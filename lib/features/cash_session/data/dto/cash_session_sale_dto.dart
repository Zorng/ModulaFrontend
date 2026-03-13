import 'package:modular_pos/features/cash_session/domain/models/cash_session_sale.dart';

class CashSessionSaleDto {
  const CashSessionSaleDto({
    required this.saleId,
    required this.status,
    required this.paymentMethod,
    required this.saleType,
    required this.finalizedAt,
    required this.totalItems,
    required this.grandTotalUsd,
    required this.grandTotalKhr,
    required this.cashierAccountId,
    required this.cashierName,
    required this.voidedAt,
  });

  final String saleId;
  final String status;
  final String paymentMethod;
  final String saleType;
  final DateTime? finalizedAt;
  final int totalItems;
  final double grandTotalUsd;
  final double grandTotalKhr;
  final String cashierAccountId;
  final String cashierName;
  final DateTime? voidedAt;

  factory CashSessionSaleDto.fromJson(Map<String, dynamic> json) {
    return CashSessionSaleDto(
      saleId: (json['saleId'] ?? '').toString(),
      status: CashSessionSaleStatuses.normalize(json['status'] as String?),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      saleType: (json['saleType'] ?? '').toString(),
      finalizedAt: _parseDateTime(json['finalizedAt']),
      totalItems: _parseInt(json['totalItems']),
      grandTotalUsd: _parseDouble(json['grandTotalUsd']),
      grandTotalKhr: _parseDouble(json['grandTotalKhr']),
      cashierAccountId: (json['cashierAccountId'] ?? '').toString(),
      cashierName: (json['cashierName'] ?? '').toString(),
      voidedAt: _parseDateTime(json['voidedAt']),
    );
  }

  CashSessionSale toDomain() {
    return CashSessionSale(
      saleId: saleId,
      status: status,
      paymentMethod: paymentMethod,
      saleType: saleType,
      finalizedAt: finalizedAt?.toLocal(),
      totalItems: totalItems,
      grandTotalUsd: grandTotalUsd,
      grandTotalKhr: grandTotalKhr,
      cashierAccountId: cashierAccountId,
      cashierName: cashierName,
      voidedAt: voidedAt?.toLocal(),
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    final raw = value?.toString() ?? '';
    if (raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
