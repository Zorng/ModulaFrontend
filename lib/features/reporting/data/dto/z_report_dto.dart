class ZReportSummaryDto {
  const ZReportSummaryDto({
    required this.date,
    required this.sessionCount,
    required this.openingFloatUsd,
    required this.openingFloatKhr,
    required this.totalSalesCashUsd,
    required this.totalSalesCashKhr,
    required this.totalPaidInUsd,
    required this.totalPaidInKhr,
    required this.totalPaidOutUsd,
    required this.totalPaidOutKhr,
    required this.expectedCashUsd,
    required this.expectedCashKhr,
  });

  final DateTime? date;
  final int sessionCount;
  final double openingFloatUsd;
  final double openingFloatKhr;
  final double totalSalesCashUsd;
  final double totalSalesCashKhr;
  final double totalPaidInUsd;
  final double totalPaidInKhr;
  final double totalPaidOutUsd;
  final double totalPaidOutKhr;
  final double expectedCashUsd;
  final double expectedCashKhr;

  factory ZReportSummaryDto.fromJson(Map<String, dynamic> json) {
    return ZReportSummaryDto(
      date: _parseDate(json['date']),
      sessionCount: _toInt(json['sessionCount']),
      openingFloatUsd: _toDouble(json['openingFloatUsd']),
      openingFloatKhr: _toDouble(json['openingFloatKhr']),
      totalSalesCashUsd: _toDouble(json['totalSalesCashUsd']),
      totalSalesCashKhr: _toDouble(json['totalSalesCashKhr']),
      totalPaidInUsd: _toDouble(json['totalPaidInUsd']),
      totalPaidInKhr: _toDouble(json['totalPaidInKhr']),
      totalPaidOutUsd: _toDouble(json['totalPaidOutUsd']),
      totalPaidOutKhr: _toDouble(json['totalPaidOutKhr']),
      expectedCashUsd: _toDouble(json['expectedCashUsd']),
      expectedCashKhr: _toDouble(json['expectedCashKhr']),
    );
  }
}

class ZReportDetailDto {
  const ZReportDetailDto({
    required this.sessionId,
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
    required this.countedCashUsd,
    required this.countedCashKhr,
    required this.varianceUsd,
    required this.varianceKhr,
    required this.closedByName,
    required this.closeReason,
  });

  final String sessionId;
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
  final double countedCashUsd;
  final double countedCashKhr;
  final double varianceUsd;
  final double varianceKhr;
  final String closedByName;
  final String closeReason;

  factory ZReportDetailDto.fromJson(Map<String, dynamic> json) {
    final manualOutUsd = _toDouble(json['totalManualOutUsd']);
    final manualOutKhr = _toDouble(json['totalManualOutKhr']);
    final refundOutUsd = _toDouble(json['totalRefundOutUsd']);
    final refundOutKhr = _toDouble(json['totalRefundOutKhr']);

    return ZReportDetailDto(
      sessionId: json['sessionId']?.toString() ?? json['id']?.toString() ?? '',
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
      countedCashUsd: _toDouble(json['countedCashUsd']),
      countedCashKhr: _toDouble(json['countedCashKhr']),
      varianceUsd: _toDouble(json['varianceUsd']),
      varianceKhr: _toDouble(json['varianceKhr']),
      closedByName: json['closedByName']?.toString() ?? '',
      closeReason: json['closeReason']?.toString() ?? '',
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

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
