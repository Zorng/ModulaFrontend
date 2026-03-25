import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';

class RestockSpendSummaryReport {
  const RestockSpendSummaryReport({
    required this.scope,
    required this.totals,
    required this.monthlyBreakdown,
  });

  final ReportScope scope;
  final RestockSpendTotals totals;
  final List<RestockSpendMonthlyBreakdownItem> monthlyBreakdown;
}

class RestockSpendTotals {
  const RestockSpendTotals({
    required this.knownCostSpendUsd,
    required this.knownCostBatchCount,
    required this.unknownCostBatchCount,
  });

  final double knownCostSpendUsd;
  final int knownCostBatchCount;
  final int unknownCostBatchCount;
}

class RestockSpendMonthlyBreakdownItem {
  const RestockSpendMonthlyBreakdownItem({
    required this.month,
    required this.knownCostSpendUsd,
    required this.knownCostBatchCount,
    required this.unknownCostBatchCount,
  });

  final String month;
  final double knownCostSpendUsd;
  final int knownCostBatchCount;
  final int unknownCostBatchCount;
}

class RestockSpendDrillDownReport {
  const RestockSpendDrillDownReport({
    required this.scope,
    required this.items,
    required this.limit,
    required this.offset,
    required this.total,
    required this.hasMore,
  });

  final ReportScope scope;
  final List<RestockSpendDrillDownItem> items;
  final int limit;
  final int offset;
  final int total;
  final bool hasMore;
}

class RestockSpendDrillDownItem {
  const RestockSpendDrillDownItem({
    required this.restockBatchId,
    required this.branchId,
    required this.stockItemId,
    required this.stockItemName,
    required this.quantityInBaseUnit,
    required this.purchaseCostUsd,
    required this.receivedAt,
  });

  final String restockBatchId;
  final String branchId;
  final String stockItemId;
  final String stockItemName;
  final double quantityInBaseUnit;
  final double? purchaseCostUsd;
  final DateTime? receivedAt;
}
