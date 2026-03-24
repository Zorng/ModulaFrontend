import 'package:flutter/material.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';
import 'package:modular_pos/features/reporting/ui/reporting_formatters.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_section_card.dart';

class SalesCashTenderBreakdownPanel extends StatelessWidget {
  const SalesCashTenderBreakdownPanel({super.key, required this.items});

  final List<SalesCashTenderBreakdownItem> items;

  @override
  Widget build(BuildContext context) {
    final orderedItems = [...items]
      ..sort(
        (left, right) => _currencyOrder(
          left.tenderCurrency,
        ).compareTo(_currencyOrder(right.tenderCurrency)),
      );

    return ReportingSectionCard(
      title: 'Cash tender',
      subtitle: orderedItems.isEmpty
          ? null
          : '${formatInteger(_totalTransactions(orderedItems))} cash sales',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 148),
        child: orderedItems.isEmpty
            ? Center(
                child: Text(
                  'Empty',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
              )
            : Column(
                children: [
                  for (var i = 0; i < orderedItems.length; i++) ...[
                    _CashTenderLegendItem(item: orderedItems[i]),
                    if (i != orderedItems.length - 1)
                      const SizedBox(height: 12),
                  ],
                ],
              ),
      ),
    );
  }

  int _totalTransactions(List<SalesCashTenderBreakdownItem> items) {
    return items.fold<int>(0, (total, item) => total + item.transactionCount);
  }

  int _currencyOrder(SalesTenderCurrency currency) {
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
