import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/core/printing/thermal_printer_profiles.dart';

class ThermalReceiptModifierLine {
  const ThermalReceiptModifierLine({
    required this.name,
    this.priceDeltaUsd = 0,
  });

  final String name;
  final double priceDeltaUsd;

  bool get hasPriceDelta => priceDeltaUsd.abs() >= 0.005;
}

class ThermalReceiptItemLine {
  const ThermalReceiptItemLine({
    required this.name,
    required this.quantity,
    required this.basePriceUsd,
    this.modifiers = const <ThermalReceiptModifierLine>[],
  });

  final String name;
  final int quantity;
  final double basePriceUsd;
  final List<ThermalReceiptModifierLine> modifiers;
}

class ThermalReceiptPrintData {
  const ThermalReceiptPrintData({
    required this.receiptNumber,
    required this.tenantName,
    required this.branchName,
    required this.cashierName,
    required this.paymentMethod,
    required this.issuedAt,
    required this.subtotalUsd,
    required this.taxUsd,
    required this.totalUsd,
    required this.totalKhr,
    required this.items,
    this.paidAmount,
    this.paidAmountCurrency,
    this.changeKhr,
  });

  final String receiptNumber;
  final String tenantName;
  final String branchName;
  final String cashierName;
  final String paymentMethod;
  final DateTime issuedAt;
  final double subtotalUsd;
  final double taxUsd;
  final double totalUsd;
  final double totalKhr;
  final List<ThermalReceiptItemLine> items;
  final double? paidAmount;
  final String? paidAmountCurrency;
  final double? changeKhr;
}

class EscPosReceiptFormatter {
  EscPosReceiptFormatter({
    ThermalPrinterProfile? profile,
    DateFormat? issuedDateFormatter,
    DateFormat? issuedTimeFormatter,
  }) : profile = profile ?? ThermalPrinterProfiles.bt58358mm,
       _issuedDateFormatter = issuedDateFormatter ?? DateFormat('yyyy-MM-dd'),
       _issuedTimeFormatter = issuedTimeFormatter ?? DateFormat('HH:mm');

  final ThermalPrinterProfile profile;
  final DateFormat _issuedDateFormatter;
  final DateFormat _issuedTimeFormatter;

  static Future<CapabilityProfile>? _capabilityProfileFuture;

  Future<List<int>> formatReceipt(ThermalReceiptPrintData data) async {
    final generator = await _buildGenerator();
    final bytes = <int>[];
    final paymentMethod = _normalizePaymentMethod(data.paymentMethod);

    bytes.addAll(generator.reset());
    bytes.addAll(
      generator.text(
        _sanitizeHeader(data.tenantName, fallback: 'Tenant'),
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    bytes.addAll(
      generator.text(
        _sanitizeHeader(data.branchName, fallback: 'Branch'),
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.hr(ch: '-'));
    bytes.addAll(
      generator.text(
        'Cashier: ${_sanitizeHeader(data.cashierName, fallback: 'Cashier')}',
      ),
    );
    bytes.addAll(
      generator.row([
        PosColumn(
          text: 'Date: ${_issuedDateFormatter.format(data.issuedAt)}',
          width: 7,
        ),
        PosColumn(
          text: 'Time: ${_issuedTimeFormatter.format(data.issuedAt)}',
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );
    bytes.addAll(generator.hr(ch: '-'));
    bytes.addAll(
      generator.row([
        PosColumn(text: 'Item', width: 7, styles: const PosStyles(bold: true)),
        PosColumn(
          text: 'Qty',
          width: 2,
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
        PosColumn(
          text: 'Price',
          width: 3,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]),
    );

    for (final item in data.items) {
      bytes.addAll(
        generator.row([
          PosColumn(text: _sanitizeCell(item.name), width: 7),
          PosColumn(
            text: item.quantity.toString(),
            width: 2,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: _formatUsd(item.basePriceUsd),
            width: 3,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );

      for (final modifier in _orderedModifiers(item.modifiers)) {
        bytes.addAll(
          generator.row([
            PosColumn(text: '  ${_sanitizeCell(modifier.name)}', width: 7),
            PosColumn(text: '', width: 2),
            PosColumn(
              text: modifier.hasPriceDelta
                  ? _formatUsd(modifier.priceDeltaUsd, includePlus: true)
                  : '',
              width: 3,
              styles: const PosStyles(align: PosAlign.right),
            ),
          ]),
        );
      }
    }

    bytes.addAll(generator.hr(ch: '-'));
    bytes.addAll(
      _summaryRow(
        generator,
        label: 'Subtotal',
        value: _formatUsd(data.subtotalUsd),
      ),
    );
    bytes.addAll(
      _summaryRow(generator, label: 'Tax', value: _formatUsd(data.taxUsd)),
    );
    bytes.addAll(generator.hr(ch: '-'));
    bytes.addAll(
      _summaryRow(
        generator,
        label: 'TOTAL',
        value: _formatUsd(data.totalUsd),
        bold: true,
      ),
    );
    bytes.addAll(generator.hr(ch: '-'));

    if (paymentMethod == 'khqr') {
      bytes.addAll(generator.text('Payment method KHQR'));
    } else {
      bytes.addAll(generator.text('Payment method: CASH'));
      if (data.paidAmount != null) {
        bytes.addAll(
          _summaryRow(
            generator,
            label: 'Paid amount',
            value: _formatTenderAmount(
              amount: data.paidAmount!,
              currency: data.paidAmountCurrency,
            ),
          ),
        );
      }
      if (data.changeKhr != null) {
        bytes.addAll(
          _summaryRow(
            generator,
            label: 'Change',
            value: _formatKhr(data.changeKhr!),
          ),
        );
      }
    }

    bytes.addAll(generator.feed(profile.feedLinesAfterPrint));
    if (profile.supportsCut) {
      bytes.addAll(generator.cut());
    }
    return bytes;
  }

  Future<List<int>> buildTestPage({String? printerLabel}) async {
    final generator = await _buildGenerator();
    final bytes = <int>[];

    bytes.addAll(generator.reset());
    bytes.addAll(
      generator.text(
        'BT-583 Test Print',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    bytes.addAll(
      generator.text(
        _sanitizeCell(printerLabel ?? profile.label),
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(
      generator.text(
        '58mm profile',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.hr(ch: '-'));
    bytes.addAll(generator.text('ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
    bytes.addAll(generator.text('12345678901234567890123456789012'));
    bytes.addAll(generator.text('test ok'));
    bytes.addAll(generator.feed(profile.feedLinesAfterPrint));
    return bytes;
  }

  Future<Generator> _buildGenerator() async {
    final capabilityProfile = _capabilityProfileFuture ??=
        CapabilityProfile.load();
    return Generator(
      _paperSizeFor(profile),
      await capabilityProfile,
      spaceBetweenRows: 0,
    );
  }

  PaperSize _paperSizeFor(ThermalPrinterProfile profile) {
    return profile.paperWidthMm <= 58 ? PaperSize.mm58 : PaperSize.mm80;
  }

  List<int> _summaryRow(
    Generator generator, {
    required String label,
    required String value,
    bool bold = false,
  }) {
    return generator.row([
      PosColumn(
        text: label,
        width: 8,
        styles: PosStyles(bold: bold),
      ),
      PosColumn(
        text: value,
        width: 4,
        styles: PosStyles(align: PosAlign.right, bold: bold),
      ),
    ]);
  }

  Iterable<ThermalReceiptModifierLine> _orderedModifiers(
    List<ThermalReceiptModifierLine> modifiers,
  ) {
    final zeroPrice = <ThermalReceiptModifierLine>[];
    final priceAdjusted = <ThermalReceiptModifierLine>[];
    for (final modifier in modifiers) {
      if (modifier.hasPriceDelta) {
        priceAdjusted.add(modifier);
      } else {
        zeroPrice.add(modifier);
      }
    }
    return <ThermalReceiptModifierLine>[...zeroPrice, ...priceAdjusted];
  }

  String _normalizePaymentMethod(String input) {
    final normalized = input.trim().toLowerCase();
    if (normalized == 'qr' || normalized == 'khqr') {
      return 'khqr';
    }
    return 'cash';
  }

  String _sanitizeHeader(String input, {required String fallback}) {
    final value = _sanitizeCell(input);
    return value.isEmpty ? fallback : value;
  }

  String _sanitizeCell(String input) {
    return input.replaceAll(RegExp(r'[^\x20-\x7E]'), '?').trimRight();
  }

  String _formatUsd(double amount, {bool includePlus = false}) {
    final prefix = includePlus && amount > 0 ? '+' : '';
    return '$prefix\$${amount.toStringAsFixed(2)}';
  }

  String _formatKhr(double amount) {
    final rounded = amount.round();
    return 'KHR ${_withThousandsSeparator(rounded)}';
  }

  String _formatTenderAmount({
    required double amount,
    required String? currency,
  }) {
    final normalizedCurrency = (currency ?? '').trim().toUpperCase();
    if (normalizedCurrency == 'KHR') {
      return _formatKhr(amount);
    }
    return 'USD ${amount.toStringAsFixed(2)}';
  }

  String _withThousandsSeparator(int amount) {
    final digits = amount.abs().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index += 1) {
      final remaining = digits.length - index;
      buffer.write(digits[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    final formatted = buffer.toString();
    return amount < 0 ? '-$formatted' : formatted;
  }
}
