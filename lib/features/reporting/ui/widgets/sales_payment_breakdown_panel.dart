import 'package:flutter/material.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';
import 'package:modular_pos/features/reporting/ui/reporting_formatters.dart';
import 'package:modular_pos/features/reporting/ui/widgets/charts/reporting_donut_chart.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_section_card.dart';

class SalesPaymentBreakdownPanel extends StatelessWidget {
  const SalesPaymentBreakdownPanel({
    super.key,
    required this.items,
    this.cashTenderItems = const [],
  });

  final List<SalesPaymentBreakdownItem> items;
  final List<SalesCashTenderBreakdownItem> cashTenderItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderedCashTenderItems = [...cashTenderItems]
      ..sort(
        (left, right) => _tenderOrder(
          left.tenderCurrency,
        ).compareTo(_tenderOrder(right.tenderCurrency)),
      );

    return ReportingSectionCard(
      title: 'Payment breakdown',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: ReportingDonutChart(
                segments: _segments(theme),
                emptyText: 'Empty',
                showLegend: false,
              ),
            ),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < items.length; i++) ...[
              _PaymentBreakdownLegendItem(
                label: formatSalesPaymentMethodLabel(items[i].paymentMethod),
                usdTotal: formatUsdAmount(items[i].totalUsd),
                khrTotal: formatKhrAmountLabel(items[i].totalKhr),
                color: _segmentColor(theme, items[i].paymentMethod),
              ),
              if (i != items.length - 1) const SizedBox(height: 12),
            ],
          ],
          if (orderedCashTenderItems.isNotEmpty) ...[
            if (items.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade300, height: 1),
              const SizedBox(height: 16),
            ],
            Text(
              'Cash tender',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < orderedCashTenderItems.length; i++) ...[
              _CashTenderLegendItem(item: orderedCashTenderItems[i]),
              if (i != orderedCashTenderItems.length - 1)
                const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }

  List<ReportingDonutChartSegment> _segments(ThemeData theme) {
    return items
        .map((item) {
          return ReportingDonutChartSegment(
            label: formatSalesPaymentMethodLabel(item.paymentMethod),
            value: item.totalUsd,
            legendValue: formatUsdAmount(item.totalUsd),
            color: _segmentColor(theme, item.paymentMethod),
          );
        })
        .toList(growable: false);
  }

  Color _segmentColor(ThemeData theme, SalesPaymentMethod method) {
    switch (method) {
      case SalesPaymentMethod.cash:
        return theme.colorScheme.primary;
      case SalesPaymentMethod.khqr:
        return const Color(0xFF2563EB);
      case SalesPaymentMethod.unknown:
        return const Color(0xFF9CA3AF);
    }
  }

  int _tenderOrder(SalesTenderCurrency currency) {
    switch (currency) {
      case SalesTenderCurrency.usd:
        return 0;
      case SalesTenderCurrency.khr:
        return 1;
      case SalesTenderCurrency.unknown:
        return 2;
    }
  }
}

class _PaymentBreakdownLegendItem extends StatelessWidget {
  const _PaymentBreakdownLegendItem({
    required this.label,
    required this.usdTotal,
    required this.khrTotal,
    required this.color,
  });

  final String label;
  final String usdTotal;
  final String khrTotal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                usdTotal,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                khrTotal,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CashTenderLegendItem extends StatelessWidget {
  const _CashTenderLegendItem({required this.item});

  final SalesCashTenderBreakdownItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = _accentColor(item.tenderCurrency);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useStackedLayout = constraints.maxWidth < 360;
          final leading = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  formatSalesTenderCurrencyLabel(item.tenderCurrency),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatSalesTenderCurrencyLabel(item.tenderCurrency)} tender',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _transactionLabel(item.transactionCount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final amount = Text(
            _formattedTenderAmount(item),
            textAlign: TextAlign.right,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          );

          if (useStackedLayout) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: amount),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leading),
              const SizedBox(width: 12),
              amount,
            ],
          );
        },
      ),
    );
  }

  Color _accentColor(SalesTenderCurrency currency) {
    switch (currency) {
      case SalesTenderCurrency.usd:
        return const Color(0xFF059669);
      case SalesTenderCurrency.khr:
        return const Color(0xFF2563EB);
      case SalesTenderCurrency.unknown:
        return const Color(0xFF6B7280);
    }
  }

  String _transactionLabel(int count) {
    final label = count == 1 ? 'cash sale' : 'cash sales';
    return '${formatInteger(count)} $label';
  }

  String _formattedTenderAmount(SalesCashTenderBreakdownItem item) {
    switch (item.tenderCurrency) {
      case SalesTenderCurrency.usd:
        return formatUsdAmount(item.totalTenderAmount);
      case SalesTenderCurrency.khr:
        return formatKhrAmountLabel(item.totalTenderAmount);
      case SalesTenderCurrency.unknown:
        return formatInteger(item.totalTenderAmount);
    }
  }
}
