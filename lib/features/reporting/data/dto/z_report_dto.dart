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
