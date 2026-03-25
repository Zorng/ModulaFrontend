import 'package:modular_pos/features/reporting/data/dto/report_scope_dto.dart';
import 'package:modular_pos/features/reporting/data/dto/reporting_dto_utils.dart';

class SalesSummaryReportDto {
  const SalesSummaryReportDto({
    required this.scope,
    required this.confirmed,
    required this.paymentBreakdown,
    required this.cashTenderBreakdown,
    required this.saleTypeBreakdown,
    required this.topItems,
    required this.categoryBreakdown,
    required this.exceptions,
  });

  final ReportScopeDto scope;
  final SalesConfirmedMetricsDto confirmed;
  final List<SalesPaymentBreakdownItemDto> paymentBreakdown;
  final List<SalesCashTenderBreakdownItemDto> cashTenderBreakdown;
  final List<SalesTypeBreakdownItemDto> saleTypeBreakdown;
  final List<SalesTopItemDto> topItems;
  final List<SalesCategoryBreakdownItemDto> categoryBreakdown;
  final SalesExceptionsDto exceptions;

  factory SalesSummaryReportDto.fromJson(Map<String, dynamic> json) {
    return SalesSummaryReportDto(
      scope: ReportScopeDto.fromJson(asDtoMap(json['scope'])),
      confirmed: SalesConfirmedMetricsDto.fromJson(asDtoMap(json['confirmed'])),
      paymentBreakdown: asDtoList(
        json['paymentBreakdown'],
      ).map(SalesPaymentBreakdownItemDto.fromJson).toList(growable: false),
      cashTenderBreakdown: asDtoList(
        json['cashTenderBreakdown'],
      ).map(SalesCashTenderBreakdownItemDto.fromJson).toList(growable: false),
      saleTypeBreakdown: asDtoList(
        json['saleTypeBreakdown'],
      ).map(SalesTypeBreakdownItemDto.fromJson).toList(growable: false),
      topItems: asDtoList(
        json['topItems'],
      ).map(SalesTopItemDto.fromJson).toList(growable: false),
      categoryBreakdown: asDtoList(
        json['categoryBreakdown'],
      ).map(SalesCategoryBreakdownItemDto.fromJson).toList(growable: false),
      exceptions: SalesExceptionsDto.fromJson(asDtoMap(json['exceptions'])),
    );
  }
}

class SalesConfirmedMetricsDto {
  const SalesConfirmedMetricsDto({
    required this.transactionCount,
    required this.totalGrandUsd,
    required this.totalGrandKhr,
    required this.totalVatUsd,
    required this.totalVatKhr,
    required this.totalDiscountUsd,
    required this.totalDiscountKhr,
    required this.averageTicketUsd,
    required this.averageTicketKhr,
    required this.totalItemsSold,
  });

  final int transactionCount;
  final double totalGrandUsd;
  final double totalGrandKhr;
  final double totalVatUsd;
  final double totalVatKhr;
  final double totalDiscountUsd;
  final double totalDiscountKhr;
  final double? averageTicketUsd;
  final double? averageTicketKhr;
  final int totalItemsSold;

  factory SalesConfirmedMetricsDto.fromJson(Map<String, dynamic> json) {
    return SalesConfirmedMetricsDto(
      transactionCount: dtoToInt(json['transactionCount']),
      totalGrandUsd: dtoToDouble(json['totalGrandUsd']),
      totalGrandKhr: dtoToDouble(json['totalGrandKhr']),
      totalVatUsd: dtoToDouble(json['totalVatUsd']),
      totalVatKhr: dtoToDouble(json['totalVatKhr']),
      totalDiscountUsd: dtoToDouble(json['totalDiscountUsd']),
      totalDiscountKhr: dtoToDouble(json['totalDiscountKhr']),
      averageTicketUsd: dtoToNullableDouble(json['averageTicketUsd']),
      averageTicketKhr: dtoToNullableDouble(json['averageTicketKhr']),
      totalItemsSold: dtoToInt(json['totalItemsSold']),
    );
  }
}

class SalesPaymentBreakdownItemDto {
  const SalesPaymentBreakdownItemDto({
    required this.paymentMethod,
    required this.transactionCount,
    required this.totalUsd,
    required this.totalKhr,
  });

  final String paymentMethod;
  final int transactionCount;
  final double totalUsd;
  final double totalKhr;

  factory SalesPaymentBreakdownItemDto.fromJson(Map<String, dynamic> json) {
    return SalesPaymentBreakdownItemDto(
      paymentMethod: dtoToString(json['paymentMethod']),
      transactionCount: dtoToInt(json['transactionCount']),
      totalUsd: dtoToDouble(json['totalUsd']),
      totalKhr: dtoToDouble(json['totalKhr']),
    );
  }
}

class SalesCashTenderBreakdownItemDto {
  const SalesCashTenderBreakdownItemDto({
    required this.tenderCurrency,
    required this.transactionCount,
    required this.totalTenderAmount,
  });

  final String tenderCurrency;
  final int transactionCount;
  final double totalTenderAmount;

  factory SalesCashTenderBreakdownItemDto.fromJson(Map<String, dynamic> json) {
    return SalesCashTenderBreakdownItemDto(
      tenderCurrency: dtoToString(json['tenderCurrency']),
      transactionCount: dtoToInt(json['transactionCount']),
      totalTenderAmount: dtoToDouble(json['totalTenderAmount']),
    );
  }
}

class SalesTypeBreakdownItemDto {
  const SalesTypeBreakdownItemDto({
    required this.saleType,
    required this.transactionCount,
    required this.totalUsd,
    required this.totalKhr,
    required this.totalItemsSold,
  });

  final String saleType;
  final int transactionCount;
  final double totalUsd;
  final double totalKhr;
  final int totalItemsSold;

  factory SalesTypeBreakdownItemDto.fromJson(Map<String, dynamic> json) {
    return SalesTypeBreakdownItemDto(
      saleType: dtoToString(json['saleType']),
      transactionCount: dtoToInt(json['transactionCount']),
      totalUsd: dtoToDouble(json['totalUsd']),
      totalKhr: dtoToDouble(json['totalKhr']),
      totalItemsSold: dtoToInt(json['totalItemsSold']),
    );
  }
}

class SalesTopItemDto {
  const SalesTopItemDto({
    required this.menuItemId,
    required this.itemNameSnapshot,
    required this.quantity,
    required this.revenueUsd,
    required this.revenueKhr,
  });

  final String menuItemId;
  final String itemNameSnapshot;
  final int quantity;
  final double revenueUsd;
  final double revenueKhr;

  factory SalesTopItemDto.fromJson(Map<String, dynamic> json) {
    return SalesTopItemDto(
      menuItemId: dtoToString(json['menuItemId']),
      itemNameSnapshot: dtoToString(json['itemNameSnapshot']),
      quantity: dtoToInt(json['quantity']),
      revenueUsd: dtoToDouble(json['revenueUsd']),
      revenueKhr: dtoToDouble(json['revenueKhr']),
    );
  }
}

class SalesCategoryBreakdownItemDto {
  const SalesCategoryBreakdownItemDto({
    required this.categoryNameSnapshot,
    required this.quantity,
    required this.revenueUsd,
    required this.revenueKhr,
  });

  final String categoryNameSnapshot;
  final int quantity;
  final double revenueUsd;
  final double revenueKhr;

  factory SalesCategoryBreakdownItemDto.fromJson(Map<String, dynamic> json) {
    return SalesCategoryBreakdownItemDto(
      categoryNameSnapshot: dtoToString(json['categoryNameSnapshot']),
      quantity: dtoToInt(json['quantity']),
      revenueUsd: dtoToDouble(json['revenueUsd']),
      revenueKhr: dtoToDouble(json['revenueKhr']),
    );
  }
}

class SalesExceptionTotalsDto {
  const SalesExceptionTotalsDto({
    required this.count,
    required this.totalUsd,
    required this.totalKhr,
  });

  final int count;
  final double totalUsd;
  final double totalKhr;

  factory SalesExceptionTotalsDto.fromJson(Map<String, dynamic> json) {
    return SalesExceptionTotalsDto(
      count: dtoToInt(json['count']),
      totalUsd: dtoToDouble(json['totalUsd']),
      totalKhr: dtoToDouble(json['totalKhr']),
    );
  }
}

class SalesExceptionsDto {
  const SalesExceptionsDto({required this.voidPending, required this.voided});

  final SalesExceptionTotalsDto voidPending;
  final SalesExceptionTotalsDto voided;

  factory SalesExceptionsDto.fromJson(Map<String, dynamic> json) {
    return SalesExceptionsDto(
      voidPending: SalesExceptionTotalsDto.fromJson(
        asDtoMap(json['voidPending']),
      ),
      voided: SalesExceptionTotalsDto.fromJson(asDtoMap(json['voided'])),
    );
  }
}

class SalesDrillDownReportDto {
  const SalesDrillDownReportDto({
    required this.scope,
    required this.items,
    required this.limit,
    required this.offset,
    required this.total,
    required this.hasMore,
  });

  final ReportScopeDto scope;
  final List<SalesDrillDownItemDto> items;
  final int limit;
  final int offset;
  final int total;
  final bool hasMore;

  factory SalesDrillDownReportDto.fromJson(Map<String, dynamic> json) {
    return SalesDrillDownReportDto(
      scope: ReportScopeDto.fromJson(asDtoMap(json['scope'])),
      items: asDtoList(
        json['items'],
      ).map(SalesDrillDownItemDto.fromJson).toList(growable: false),
      limit: dtoToInt(json['limit']),
      offset: dtoToInt(json['offset']),
      total: dtoToInt(json['total']),
      hasMore: dtoToBool(json['hasMore']),
    );
  }
}

class SalesDrillDownItemDto {
  const SalesDrillDownItemDto({
    required this.saleId,
    required this.branchId,
    required this.status,
    required this.paymentMethod,
    required this.saleType,
    required this.finalizedAt,
    required this.totalItems,
    required this.grandTotalUsd,
    required this.grandTotalKhr,
    required this.vatUsd,
    required this.vatKhr,
    required this.discountUsd,
    required this.discountKhr,
  });

  final String saleId;
  final String branchId;
  final String status;
  final String paymentMethod;
  final String saleType;
  final DateTime? finalizedAt;
  final int totalItems;
  final double grandTotalUsd;
  final double grandTotalKhr;
  final double vatUsd;
  final double vatKhr;
  final double discountUsd;
  final double discountKhr;

  factory SalesDrillDownItemDto.fromJson(Map<String, dynamic> json) {
    return SalesDrillDownItemDto(
      saleId: dtoToString(json['saleId']),
      branchId: dtoToString(json['branchId']),
      status: dtoToString(json['status']),
      paymentMethod: dtoToString(json['paymentMethod']),
      saleType: dtoToString(json['saleType']),
      finalizedAt: dtoToDateTime(json['finalizedAt']),
      totalItems: dtoToInt(json['totalItems']),
      grandTotalUsd: dtoToDouble(json['grandTotalUsd']),
      grandTotalKhr: dtoToDouble(json['grandTotalKhr']),
      vatUsd: dtoToDouble(json['vatUsd']),
      vatKhr: dtoToDouble(json['vatKhr']),
      discountUsd: dtoToDouble(json['discountUsd']),
      discountKhr: dtoToDouble(json['discountKhr']),
    );
  }
}
