import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/printing/esc_pos_receipt_formatter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String printableText(List<int> bytes) {
    final buffer = StringBuffer();
    for (var index = 0; index < bytes.length; index += 1) {
      final byte = bytes[index];
      if (byte == 10) {
        buffer.writeln();
        continue;
      }
      if (byte == 13) {
        continue;
      }
      if (byte == 27) {
        if (index + 1 >= bytes.length) break;
        final command = bytes[++index];
        switch (command) {
          case 36:
            index += 2;
            break;
          case 45:
          case 51:
          case 69:
          case 77:
          case 97:
          case 116:
            index += 1;
            break;
          case 64:
          case 50:
            break;
          default:
            break;
        }
        continue;
      }
      if (byte == 28) {
        if (index + 1 >= bytes.length) break;
        index += 1;
        continue;
      }
      if (byte == 29) {
        if (index + 1 >= bytes.length) break;
        final command = bytes[++index];
        switch (command) {
          case 33:
          case 66:
          case 86:
            index += 1;
            break;
          default:
            break;
        }
        continue;
      }
      if (byte >= 32 && byte <= 126) {
        buffer.writeCharCode(byte);
      }
    }
    return buffer.toString();
  }

  test('formats the sale receipt layout for BT-583 58mm', () async {
    final formatter = EscPosReceiptFormatter();
    final bytes = await formatter.formatReceipt(
      ThermalReceiptPrintData(
        receiptNumber: 'RCP-1001',
        tenantName: 'Acme Coffee',
        branchName: 'BKK 1',
        cashierName: 'Nika',
        paymentMethod: 'cash',
        issuedAt: DateTime(2026, 3, 10, 8, 30),
        subtotalUsd: 5.25,
        discountUsd: 0.75,
        taxUsd: 0,
        totalUsd: 5.25,
        totalKhr: 21000,
        paidAmount: 25000,
        paidAmountCurrency: 'KHR',
        changeKhr: 4000,
        items: const [
          ThermalReceiptItemLine(
            name: 'Iced Latte',
            quantity: 1,
            basePriceUsd: 4.5,
            modifiers: [
              ThermalReceiptModifierLine(
                name: 'Less Ice',
                groupName: 'Ice Level',
              ),
              ThermalReceiptModifierLine(
                name: 'Extra Shot',
                groupName: 'Add-ons',
                priceDeltaUsd: 0.75,
              ),
            ],
          ),
        ],
      ),
    );

    final text = printableText(bytes);
    final flattenedText = text.replaceAll('\n', '');

    expect(text, contains('Acme Coffee'));
    expect(text, contains('BKK 1'));
    expect(text, contains('--------------------------------'));
    expect(text, contains('Cashier: Nika'));
    expect(text, contains('Date: 2026-03-10'));
    expect(text, contains('Time: 08:30'));
    expect(text, contains('Item'));
    expect(text, contains('Qty'));
    expect(text, contains('Price'));
    expect(text, contains('Iced Latte'));
    expect(flattenedText, contains('  Ice Level: Less Ice'));
    expect(flattenedText, contains('  Extra S'));
    expect(
      flattenedText.indexOf('  Ice Level: Less Ice'),
      lessThan(flattenedText.indexOf('  Extra S')),
    );
    expect(text, contains(r'+$0.75'));
    expect(text, contains('Subtotal'));
    expect(text, contains('Discount'));
    expect(text, contains('Tax'));
    expect(text, contains('TOTAL'));
    expect(text, contains('Payment method: CASH'));
    expect(text, contains('Paid amount'));
    expect(text, contains('KHR 25,000'));
    expect(text, contains('Change'));
    expect(text, contains('KHR 4,000'));
  });

  test('prints KHQR payment block without cash-only rows', () async {
    final formatter = EscPosReceiptFormatter();
    final bytes = await formatter.formatReceipt(
      ThermalReceiptPrintData(
        receiptNumber: 'RCP-1002',
        tenantName: 'Acme Coffee',
        branchName: 'BKK 1',
        cashierName: 'Nika',
        paymentMethod: 'khqr',
        issuedAt: DateTime(2026, 3, 10, 9, 15),
        subtotalUsd: 3,
        taxUsd: 0,
        totalUsd: 3,
        totalKhr: 12000,
        items: const [
          ThermalReceiptItemLine(
            name: 'Americano',
            quantity: 1,
            basePriceUsd: 3,
          ),
        ],
      ),
    );

    final text = printableText(bytes);

    expect(text, contains('Payment method KHQR'));
    expect(text, isNot(contains('Paid amount')));
    expect(text, isNot(contains('Change')));
  });

  test('builds a BT-583 test page payload', () async {
    final formatter = EscPosReceiptFormatter();
    final bytes = await formatter.buildTestPage(printerLabel: 'BT-583 Printer');

    final text = ascii.decode(
      bytes.where((byte) => byte == 10 || (byte >= 32 && byte <= 126)).toList(),
    );

    expect(text, contains('BT-583 Test Print'));
    expect(text, contains('BT-583 Printer'));
    expect(text, contains('58mm profile'));
  });
}
