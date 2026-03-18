import 'package:flutter/material.dart';
import 'package:modular_pos/features/discount/domain/models/discount_rule.dart';
import 'package:modular_pos/features/discount/ui/components/discount_detail_helpers.dart';

class DiscountDetailHeroCard extends StatelessWidget {
  const DiscountDetailHeroCard({super.key, required this.rule});

  final DiscountRule rule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DiscountDetailPill(
                label: discountDetailStatusLabel(rule.status),
                color: discountDetailStatusColor(rule.status),
              ),
              DiscountDetailPill(label: discountDetailScopeLabel(rule.scope)),
              DiscountDetailPill(
                label: '${discountDetailPercentageLabel(rule.percentage)}%',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(rule.name, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            discountDetailScopeDescription(rule),
            style: theme.textTheme.bodyLarge?.copyWith(color: onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class DiscountDetailPill extends StatelessWidget {
  const DiscountDetailPill({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: effectiveColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
