import 'package:flutter/material.dart';
import 'package:modular_pos/features/discount/domain/models/discount_scope.dart';
import 'package:modular_pos/features/discount/ui/components/discount_form_card.dart';

class DiscountFormPreviewSection extends StatelessWidget {
  const DiscountFormPreviewSection({
    super.key,
    required this.scope,
    required this.percentageLabel,
    required this.previewName,
    required this.itemCount,
  });

  final String scope;
  final String percentageLabel;
  final String previewName;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return DiscountFormCard(
      title: 'Preview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewPill(
            label: scope == DiscountScopes.branchWide
                ? 'Branch-wide'
                : 'Item-level',
          ),
          const SizedBox(height: 8),
          _PreviewPill(label: percentageLabel),
          const SizedBox(height: 16),
          Text(previewName, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            scope == DiscountScopes.branchWide
                ? 'Will apply to the full branch menu.'
                : '$itemCount targeted item${itemCount == 1 ? '' : 's'} selected.',
          ),
        ],
      ),
    );
  }
}

class _PreviewPill extends StatelessWidget {
  const _PreviewPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
