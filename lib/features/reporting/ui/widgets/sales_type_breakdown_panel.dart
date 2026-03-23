import 'package:flutter/material.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';
import 'package:modular_pos/features/reporting/ui/reporting_formatters.dart';
import 'package:modular_pos/features/reporting/ui/widgets/charts/reporting_donut_chart.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_section_card.dart';

class SalesTypeBreakdownPanel extends StatelessWidget {
  const SalesTypeBreakdownPanel({super.key, required this.items});

  final List<SalesTypeBreakdownItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ReportingSectionCard(
      title: 'Sale type',
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
              _SaleTypeLegendItem(
                label: formatSalesTypeLabel(items[i].saleType),
                usdTotal: formatUsdAmount(items[i].totalUsd),
                khrTotal: formatKhrAmountLabel(items[i].totalKhr),
                color: _segmentColor(theme, items[i].saleType),
              ),
              if (i != items.length - 1) const SizedBox(height: 12),
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
            label: formatSalesTypeLabel(item.saleType),
            value: item.totalUsd,
            legendValue: formatUsdAmount(item.totalUsd),
            color: _segmentColor(theme, item.saleType),
          );
        })
        .toList(growable: false);
  }

  Color _segmentColor(ThemeData theme, SalesType type) {
    switch (type) {
      case SalesType.dineIn:
        return theme.colorScheme.primary;
      case SalesType.takeaway:
        return const Color(0xFF2563EB);
      case SalesType.delivery:
        return const Color(0xFFF59E0B);
      case SalesType.unknown:
        return const Color(0xFF9CA3AF);
    }
  }
}

class _SaleTypeLegendItem extends StatelessWidget {
  const _SaleTypeLegendItem({
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
