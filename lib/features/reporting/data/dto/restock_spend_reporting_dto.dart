import 'package:modular_pos/features/reporting/data/dto/report_scope_dto.dart';
import 'package:modular_pos/features/reporting/data/dto/reporting_dto_utils.dart';

class RestockSpendSummaryReportDto {
  const RestockSpendSummaryReportDto({
    required this.scope,
    required this.totals,
    required this.monthlyBreakdown,
  });

  final ReportScopeDto scope;
  final RestockSpendTotalsDto totals;
  final List<RestockSpendMonthlyBreakdownItemDto> monthlyBreakdown;

  factory RestockSpendSummaryReportDto.fromJson(Map<String, dynamic> json) {
    return RestockSpendSummaryReportDto(
      scope: ReportScopeDto.fromJson(asDtoMap(json['scope'])),
      totals: RestockSpendTotalsDto.fromJson(asDtoMap(json['totals'])),
      monthlyBreakdown: asDtoList(json['monthlyBreakdown'])
          .map(RestockSpendMonthlyBreakdownItemDto.fromJson)
          .toList(growable: false),
    );
  }
}

class RestockSpendTotalsDto {
  const RestockSpendTotalsDto({
    required this.knownCostSpendUsd,
    required this.knownCostBatchCount,
    required this.unknownCostBatchCount,
  });

  final double knownCostSpendUsd;
  final int knownCostBatchCount;
  final int unknownCostBatchCount;

  factory RestockSpendTotalsDto.fromJson(Map<String, dynamic> json) {
    return RestockSpendTotalsDto(
      knownCostSpendUsd: dtoToDouble(json['knownCostSpendUsd']),
      knownCostBatchCount: dtoToInt(json['knownCostBatchCount']),
      unknownCostBatchCount: dtoToInt(json['unknownCostBatchCount']),
    );
  }
}

class RestockSpendMonthlyBreakdownItemDto {
  const RestockSpendMonthlyBreakdownItemDto({
    required this.month,
    required this.knownCostSpendUsd,
    required this.knownCostBatchCount,
    required this.unknownCostBatchCount,
  });

  final String month;
  final double knownCostSpendUsd;
  final int knownCostBatchCount;
  final int unknownCostBatchCount;

  factory RestockSpendMonthlyBreakdownItemDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return RestockSpendMonthlyBreakdownItemDto(
      month: dtoToString(json['month']),
      knownCostSpendUsd: dtoToDouble(json['knownCostSpendUsd']),
      knownCostBatchCount: dtoToInt(json['knownCostBatchCount']),
      unknownCostBatchCount: dtoToInt(json['unknownCostBatchCount']),
    );
  }
}

class RestockSpendDrillDownReportDto {
  const RestockSpendDrillDownReportDto({
    required this.scope,
    required this.items,
    required this.limit,
    required this.offset,
    required this.total,
    required this.hasMore,
  });

  final ReportScopeDto scope;
  final List<RestockSpendDrillDownItemDto> items;
  final int limit;
  final int offset;
  final int total;
  final bool hasMore;

  factory RestockSpendDrillDownReportDto.fromJson(Map<String, dynamic> json) {
    return RestockSpendDrillDownReportDto(
      scope: ReportScopeDto.fromJson(asDtoMap(json['scope'])),
      items: asDtoList(
        json['items'],
      ).map(RestockSpendDrillDownItemDto.fromJson).toList(growable: false),
      limit: dtoToInt(json['limit']),
      offset: dtoToInt(json['offset']),
      total: dtoToInt(json['total']),
      hasMore: dtoToBool(json['hasMore']),
    );
  }
}

class RestockSpendDrillDownItemDto {
  const RestockSpendDrillDownItemDto({
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

  factory RestockSpendDrillDownItemDto.fromJson(Map<String, dynamic> json) {
    return RestockSpendDrillDownItemDto(
      restockBatchId: dtoToString(json['restockBatchId']),
      branchId: dtoToString(json['branchId']),
      stockItemId: dtoToString(json['stockItemId']),
      stockItemName: dtoToString(json['stockItemName']),
      quantityInBaseUnit: dtoToDouble(json['quantityInBaseUnit']),
      purchaseCostUsd: dtoToNullableDouble(json['purchaseCostUsd']),
      receivedAt: dtoToDateTime(json['receivedAt']),
    );
  }
}
