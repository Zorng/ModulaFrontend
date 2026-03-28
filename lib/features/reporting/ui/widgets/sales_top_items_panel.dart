import 'package:flutter/material.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';
import 'package:modular_pos/features/reporting/ui/reporting_formatters.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_section_card.dart';

class SalesTopItemsPanel extends StatelessWidget {
  const SalesTopItemsPanel({super.key, required this.items});

  final List<SalesTopItem> items;

  @override
  Widget build(BuildContext context) {
    return ReportingSectionCard(
      title: 'Top items',
      subtitle: 'Best-selling items by quantity',
      child: items.isEmpty
          ? Text(
              'Empty',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            )
          : Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  _TopItemRow(rank: i + 1, item: items[i]),
                  if (i != items.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _TopItemRow extends StatelessWidget {
  const _TopItemRow({required this.rank, required this.item});

  final int rank;
  final SalesTopItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accentColor = Color(0xFF0F766E);
    final leading = Row(
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
            '#$rank',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.itemNameSnapshot,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    final metrics = Text(
      'Qty ${formatInteger(item.quantity)}',
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );

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
          if (useStackedLayout) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: metrics),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leading),
              const SizedBox(width: 12),
              metrics,
            ],
          );
        },
      ),
    );
  }
}
