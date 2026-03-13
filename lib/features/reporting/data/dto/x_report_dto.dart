class XReportListItemDto {
  const XReportListItemDto({
    required this.id,
    required this.status,
    required this.openedByName,
    required this.openedAt,
    required this.closedAt,
  });

  final String id;
  final String status;
  final String openedByName;
  final DateTime? openedAt;
  final DateTime? closedAt;

  factory XReportListItemDto.fromJson(Map<String, dynamic> json) {
    return XReportListItemDto(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      openedByName: json['openedByName']?.toString() ?? '',
      openedAt: _parseDate(json['openedAt']),
      closedAt: _parseDate(json['closedAt']),
    );
  }
}

class XReportDetailDto {
  const XReportDetailDto({
    required this.id,
    required this.status,
    required this.openedByName,
    required this.openedAt,
    required this.closedAt,
    required this.openingFloatUsd,
    required this.openingFloatKhr,
    required this.totalSalesKhqrUsd,
    required this.totalSalesKhqrKhr,
    required this.totalSalesCashUsd,
    required this.totalSalesCashKhr,
    required this.totalPaidInUsd,
    required this.totalPaidInKhr,
    required this.totalPaidOutUsd,
    required this.totalPaidOutKhr,
    required this.expectedCashUsd,
    required this.expectedCashKhr,
  });

  final String id;
  final String status;
  final String openedByName;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final double openingFloatUsd;
  final double openingFloatKhr;
  final double totalSalesKhqrUsd;
  final double totalSalesKhqrKhr;
  final double totalSalesCashUsd;
  final double totalSalesCashKhr;
  final double totalPaidInUsd;
  final double totalPaidInKhr;
  final double totalPaidOutUsd;
  final double totalPaidOutKhr;
  final double expectedCashUsd;
  final double expectedCashKhr;

  factory XReportDetailDto.fromJson(Map<String, dynamic> json) {
    final manualOutUsd = _toDouble(json['totalManualOutUsd']);
    final manualOutKhr = _toDouble(json['totalManualOutKhr']);
    final refundOutUsd = _toDouble(json['totalRefundOutUsd']);
    final refundOutKhr = _toDouble(json['totalRefundOutKhr']);

    return XReportDetailDto(
      id: json['sessionId']?.toString() ?? json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      openedByName: json['openedByName']?.toString() ?? '',
      openedAt: _parseDate(json['openedAt']),
      closedAt: _parseDate(json['closedAt']),
      openingFloatUsd: _toDouble(json['openingFloatUsd']),
      openingFloatKhr: _toDouble(json['openingFloatKhr']),
      totalSalesKhqrUsd: _toDouble(json['totalSalesKhqrUsd']),
      totalSalesKhqrKhr: _toDouble(json['totalSalesKhqrKhr']),
      totalSalesCashUsd: _toDouble(json['totalSaleInUsd']),
      totalSalesCashKhr: _toDouble(json['totalSaleInKhr']),
      totalPaidInUsd: _toDouble(json['totalManualInUsd']),
      totalPaidInKhr: _toDouble(json['totalManualInKhr']),
      totalPaidOutUsd: manualOutUsd + refundOutUsd,
      totalPaidOutKhr: manualOutKhr + refundOutKhr,
      expectedCashUsd: _toDouble(json['expectedCashUsd']),
      expectedCashKhr: _toDouble(json['expectedCashKhr']),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final raw = value.toString();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
