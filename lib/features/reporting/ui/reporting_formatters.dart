import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/core/formatters/khr_currency_formatter.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';

final NumberFormat _usdFormatter = NumberFormat.currency(
  symbol: r'$',
  decimalDigits: 2,
);
final NumberFormat _usdCompactFormatter = NumberFormat.compactCurrency(
  symbol: r'$',
  decimalDigits: 1,
);
final NumberFormat _integerFormatter = NumberFormat.decimalPattern();
final DateFormat _reportQueryDateFormatter = DateFormat('yyyy-MM-dd');
final DateFormat _reportFriendlyDateFormatter = DateFormat('dd MMM yyyy');
final DateFormat _reportShortDateTimeFormatter = DateFormat('dd MMM • hh:mm a');

String formatReportQueryDate(DateTime value) =>
    _reportQueryDateFormatter.format(value);

String formatReportFriendlyDate(DateTime value) =>
    _reportFriendlyDateFormatter.format(value);

String formatReportDateRange(DateTimeRange range) {
  return '${formatReportFriendlyDate(range.start)} - ${formatReportFriendlyDate(range.end)}';
}

String formatUsdAmount(num value) => _usdFormatter.format(value);

String formatUsdCompact(num value) => _usdCompactFormatter.format(value);

String formatInteger(num value) => _integerFormatter.format(value);

String formatKhrAmountLabel(num value) => 'KHR ${formatKhrAmount(value)}';

String formatReportWindowLabel(ReportTimeWindow value) {
  switch (value) {
    case ReportTimeWindow.day:
      return 'Day';
    case ReportTimeWindow.week:
      return 'Week';
    case ReportTimeWindow.month:
      return 'Month';
    case ReportTimeWindow.custom:
      return 'Custom';
  }
}

String formatReportScopeSummary(ReportScope scope) {
  final branchLabel = switch (scope.branchScope) {
    ReportBranchScope.allBranches => 'All branches',
    ReportBranchScope.branch =>
      scope.branchId?.trim().isNotEmpty == true
          ? 'Branch ${scope.branchId}'
          : 'Active branch',
  };
  return '$branchLabel • ${scope.from} to ${scope.to} • ${scope.timezone}';
}

String formatSalesPaymentMethodLabel(SalesPaymentMethod value) {
  switch (value) {
    case SalesPaymentMethod.cash:
      return 'Cash';
    case SalesPaymentMethod.khqr:
      return 'KHQR';
    case SalesPaymentMethod.unknown:
      return 'Unknown';
  }
}

String formatSalesTenderCurrencyLabel(SalesTenderCurrency value) {
  switch (value) {
    case SalesTenderCurrency.usd:
      return 'USD';
    case SalesTenderCurrency.khr:
      return 'KHR';
    case SalesTenderCurrency.unknown:
      return 'Unknown';
  }
}

String formatSalesTypeLabel(SalesType value) {
  switch (value) {
    case SalesType.dineIn:
      return 'Dine in';
    case SalesType.takeaway:
      return 'Takeaway';
    case SalesType.delivery:
      return 'Delivery';
    case SalesType.unknown:
      return 'Unknown';
  }
}

String formatSalesRecordStatusLabel(SalesRecordStatus value) {
  switch (value) {
    case SalesRecordStatus.finalized:
      return 'Finalized';
    case SalesRecordStatus.voidPending:
      return 'Void pending';
    case SalesRecordStatus.voided:
      return 'Voided';
    case SalesRecordStatus.unknown:
      return 'Unknown';
  }
}

String formatShortDateTime(DateTime? value) {
  if (value == null) return 'Unknown time';
  return _reportShortDateTimeFormatter.format(value.toLocal());
}
