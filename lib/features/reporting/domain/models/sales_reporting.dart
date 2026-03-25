import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';

enum SalesPaymentMethod { cash, khqr, unknown }

SalesPaymentMethod salesPaymentMethodFromApi(String? raw) {
  switch ((raw ?? '').trim().toUpperCase()) {
    case 'CASH':
      return SalesPaymentMethod.cash;
    case 'KHQR':
      return SalesPaymentMethod.khqr;
    default:
      return SalesPaymentMethod.unknown;
  }
}

enum SalesTenderCurrency { usd, khr, unknown }

SalesTenderCurrency salesTenderCurrencyFromApi(String? raw) {
  switch ((raw ?? '').trim().toUpperCase()) {
    case 'USD':
      return SalesTenderCurrency.usd;
    case 'KHR':
      return SalesTenderCurrency.khr;
    default:
      return SalesTenderCurrency.unknown;
  }
}

enum SalesType { dineIn, takeaway, delivery, unknown }

SalesType salesTypeFromApi(String? raw) {
  switch ((raw ?? '').trim().toUpperCase()) {
    case 'DINE_IN':
      return SalesType.dineIn;
    case 'TAKEAWAY':
      return SalesType.takeaway;
    case 'DELIVERY':
      return SalesType.delivery;
    default:
      return SalesType.unknown;
  }
}

enum SalesRecordStatus { finalized, voidPending, voided, unknown }

SalesRecordStatus salesRecordStatusFromApi(String? raw) {
  switch ((raw ?? '').trim().toUpperCase()) {
    case 'FINALIZED':
      return SalesRecordStatus.finalized;
    case 'VOID_PENDING':
      return SalesRecordStatus.voidPending;
    case 'VOIDED':
      return SalesRecordStatus.voided;
    default:
      return SalesRecordStatus.unknown;
  }
}

class SalesSummaryReport {
  const SalesSummaryReport({
    required this.scope,
    required this.confirmed,
    required this.paymentBreakdown,
    required this.cashTenderBreakdown,
    required this.saleTypeBreakdown,
    required this.topItems,
    required this.categoryBreakdown,
    required this.exceptions,
  });

  final ReportScope scope;
  final SalesConfirmedMetrics confirmed;
  final List<SalesPaymentBreakdownItem> paymentBreakdown;
  final List<SalesCashTenderBreakdownItem> cashTenderBreakdown;
  final List<SalesTypeBreakdownItem> saleTypeBreakdown;
  final List<SalesTopItem> topItems;
  final List<SalesCategoryBreakdownItem> categoryBreakdown;
  final SalesExceptions exceptions;
}

class SalesConfirmedMetrics {
  const SalesConfirmedMetrics({
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
}

class SalesPaymentBreakdownItem {
  const SalesPaymentBreakdownItem({
    required this.paymentMethod,
    required this.transactionCount,
    required this.totalUsd,
    required this.totalKhr,
  });

  final SalesPaymentMethod paymentMethod;
  final int transactionCount;
  final double totalUsd;
  final double totalKhr;
}

class SalesCashTenderBreakdownItem {
  const SalesCashTenderBreakdownItem({
    required this.tenderCurrency,
    required this.transactionCount,
    required this.totalTenderAmount,
  });

  final SalesTenderCurrency tenderCurrency;
  final int transactionCount;
  final double totalTenderAmount;
}

class SalesTypeBreakdownItem {
  const SalesTypeBreakdownItem({
    required this.saleType,
    required this.transactionCount,
    required this.totalUsd,
    required this.totalKhr,
    required this.totalItemsSold,
  });

  final SalesType saleType;
  final int transactionCount;
  final double totalUsd;
  final double totalKhr;
  final int totalItemsSold;
}

class SalesTopItem {
  const SalesTopItem({
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
}

class SalesCategoryBreakdownItem {
  const SalesCategoryBreakdownItem({
    required this.categoryNameSnapshot,
    required this.quantity,
    required this.revenueUsd,
    required this.revenueKhr,
  });

  final String categoryNameSnapshot;
  final int quantity;
  final double revenueUsd;
  final double revenueKhr;
}

class SalesExceptionTotals {
  const SalesExceptionTotals({
    required this.count,
    required this.totalUsd,
    required this.totalKhr,
  });

  final int count;
  final double totalUsd;
  final double totalKhr;
}

class SalesExceptions {
  const SalesExceptions({required this.voidPending, required this.voided});

  final SalesExceptionTotals voidPending;
  final SalesExceptionTotals voided;
}

class SalesDrillDownReport {
  const SalesDrillDownReport({
    required this.scope,
    required this.items,
    required this.limit,
    required this.offset,
    required this.total,
    required this.hasMore,
  });

  final ReportScope scope;
  final List<SalesDrillDownItem> items;
  final int limit;
  final int offset;
  final int total;
  final bool hasMore;
}

class SalesDrillDownItem {
  const SalesDrillDownItem({
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
  final SalesRecordStatus status;
  final SalesPaymentMethod paymentMethod;
  final SalesType saleType;
  final DateTime? finalizedAt;
  final int totalItems;
  final double grandTotalUsd;
  final double grandTotalKhr;
  final double vatUsd;
  final double vatKhr;
  final double discountUsd;
  final double discountKhr;
}
