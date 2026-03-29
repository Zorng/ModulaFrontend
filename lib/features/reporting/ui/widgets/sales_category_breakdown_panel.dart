import 'package:flutter/material.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';
import 'package:modular_pos/features/reporting/ui/reporting_formatters.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_section_card.dart';

class SalesCategoryBreakdownPanel extends StatelessWidget {
  const SalesCategoryBreakdownPanel({super.key, required this.categories});

  final List<SalesCategoryBreakdownItem> categories;

  @override
  Widget build(BuildContext context) {
    final rankedEntries = _buildChartEntries(categories);

    return ReportingSectionCard(
      title: 'Category breakdown',
      subtitle: 'Top categories by quantity',
      child: rankedEntries.isEmpty
          ? Text(
              'Empty',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            )
          : Column(
              children: [
                for (var i = 0; i < rankedEntries.length; i++) ...[
                  _CategoryRankRow(
                    rank: i + 1,
                    entry: rankedEntries[i],
                    color: _barColor(i),
                    maxQuantity: rankedEntries.first.quantity,
                  ),
                  if (i != rankedEntries.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

const int _topCategoryCount = 4;

class _CategoryChartEntry {
  const _CategoryChartEntry({required this.label, required this.quantity});

  final String label;
  final int quantity;
}

List<_CategoryChartEntry> _buildChartEntries(
  List<SalesCategoryBreakdownItem> categories,
) {
  final ordered =
      categories
          .where((item) => item.quantity > 0)
          .map(
            (item) => _CategoryChartEntry(
              label: item.categoryNameSnapshot,
              quantity: item.quantity,
            ),
          )
          .toList(growable: false)
        ..sort((left, right) {
          final quantityCompare = right.quantity.compareTo(left.quantity);
          if (quantityCompare != 0) return quantityCompare;
          return left.label.toLowerCase().compareTo(right.label.toLowerCase());
        });

  if (ordered.length <= _topCategoryCount) {
    return ordered;
  }

  final topCategories = ordered.take(_topCategoryCount).toList(growable: true);
  final remaining = ordered.skip(_topCategoryCount);

  var otherQuantity = 0;
  for (final item in remaining) {
    otherQuantity += item.quantity;
  }

  topCategories.add(
    _CategoryChartEntry(label: 'Other', quantity: otherQuantity),
  );
  return topCategories;
}

Color _barColor(int index) {
  const palette = <Color>[
    Color(0xFF0F766E),
    Color(0xFF2563EB),
    Color(0xFFF59E0B),
    Color(0xFFDC2626),
    Color(0xFF6B7280),
  ];
  return palette[index % palette.length];
}

class _CategoryRankRow extends StatelessWidget {
  const _CategoryRankRow({
    required this.rank,
    required this.entry,
    required this.color,
    required this.maxQuantity,
  });

  final int rank;
  final _CategoryChartEntry entry;
  final Color color;
  final int maxQuantity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = maxQuantity <= 0 ? 0.0 : entry.quantity / maxQuantity;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '#$rank',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    entry.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Qty ${formatInteger(entry.quantity)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: Colors.grey.shade200),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
