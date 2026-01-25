import 'package:modular_pos/features/reporting/domain/models/cash_session_status.dart';

class XReportListItem {
  const XReportListItem({
    required this.id,
    required this.status,
    required this.openedByName,
    required this.openedAt,
    required this.closedAt,
  });

  final String id;
  final CashSessionStatus status;
  final String openedByName;
  final DateTime? openedAt;
  final DateTime? closedAt;
}

class XReportDetail {
  const XReportDetail({
    required this.id,
    required this.status,
    required this.openedByName,
    required this.openedAt,
    required this.closedAt,
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

  final String id;
  final CashSessionStatus status;
  final String openedByName;
  final DateTime? openedAt;
  final DateTime? closedAt;
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
}
