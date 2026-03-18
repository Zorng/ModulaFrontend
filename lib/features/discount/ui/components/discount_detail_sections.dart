import 'package:flutter/material.dart';
import 'package:modular_pos/features/discount/domain/models/discount_rule.dart';
import 'package:modular_pos/features/discount/domain/models/discount_scope.dart';
import 'package:modular_pos/features/discount/domain/models/discount_status.dart';
import 'package:modular_pos/features/discount/ui/components/discount_detail_card.dart';
import 'package:modular_pos/features/discount/ui/components/discount_detail_helpers.dart';
import 'package:modular_pos/features/discount/ui/components/discount_detail_hero_card.dart';

class DiscountSummarySection extends StatelessWidget {
  const DiscountSummarySection({super.key, required this.rule});

  final DiscountRule rule;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DiscountDetailInfoRow(label: 'Rule name', value: rule.name),
        DiscountDetailInfoRow(
          label: 'Percentage',
          value: '${discountDetailPercentageLabel(rule.percentage)}%',
        ),
        DiscountDetailInfoRow(
          label: 'Scope',
          value: discountDetailScopeLabel(rule.scope),
        ),
        DiscountDetailInfoRow(
          label: 'Status',
          value: discountDetailStatusLabel(rule.status),
        ),
        DiscountDetailInfoRow(
          label: 'Currently eligible',
          value: rule.isCurrentlyEligible ? 'Yes' : 'No',
        ),
        DiscountDetailInfoRow(
          label: 'Stacking policy',
          value: discountDetailStackingLabel(rule.stackingPolicy),
        ),
      ],
    );
  }
}

class DiscountScheduleSection extends StatelessWidget {
  const DiscountScheduleSection({super.key, required this.rule});

  final DiscountRule rule;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DiscountDetailInfoRow(
          label: 'Mode',
          value: rule.schedule.isAlwaysOn ? 'Always on' : 'Scheduled',
        ),
        DiscountDetailInfoRow(
          label: 'Starts at',
          value: discountDetailDateTimeLabel(
            rule.schedule.startAt,
            fallback: 'Immediate',
          ),
        ),
        DiscountDetailInfoRow(
          label: 'Ends at',
          value: discountDetailDateTimeLabel(
            rule.schedule.endAt,
            fallback: 'Open end',
          ),
        ),
      ],
    );
  }
}

class DiscountTargetingSection extends StatelessWidget {
  const DiscountTargetingSection({
    super.key,
    required this.rule,
    required this.branchName,
  });

  final DiscountRule rule;
  final String branchName;

  @override
  Widget build(BuildContext context) {
    final itemLabels = rule.itemIds.isEmpty
        ? const <String>[]
        : rule.itemIds.map(discountDetailItemLabel).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DiscountDetailInfoRow(
          label: 'Assigned branch',
          value: branchName.trim().isEmpty ? rule.branchId : branchName,
        ),
        DiscountDetailInfoRow(
          label: 'Item coverage',
          value: rule.scope == DiscountScopes.branchWide
              ? 'Entire assigned branch menu'
              : '${rule.itemIds.length} selected item${rule.itemIds.length == 1 ? '' : 's'}',
        ),
        if (itemLabels.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Selected items', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: itemLabels
                .map((label) => DiscountDetailPill(label: label))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class DiscountActionSection extends StatelessWidget {
  const DiscountActionSection({
    super.key,
    required this.rule,
    required this.isUpdating,
    required this.canManage,
    required this.canEdit,
    required this.onEdit,
    required this.onActivate,
    required this.onDeactivate,
    required this.onArchive,
  });

  final DiscountRule rule;
  final bool isUpdating;
  final bool canManage;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    if (!canManage) {
      return Text(
        'Managers and cashiers can view discount rules, but only admin or owner can change them.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: isUpdating || !canEdit ? null : onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit rule'),
        ),
        if (!canEdit) ...[
          const SizedBox(height: 12),
          Text(
            'Currently eligible discount rules cannot be edited until they are no longer effective.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (rule.status != DiscountStatuses.active)
          OutlinedButton.icon(
            onPressed: isUpdating ? null : onActivate,
            icon: const Icon(Icons.play_arrow_outlined),
            label: const Text('Activate'),
          ),
        if (rule.status != DiscountStatuses.inactive) ...[
          if (rule.status != DiscountStatuses.active)
            const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isUpdating ? null : onDeactivate,
            icon: const Icon(Icons.pause_outlined),
            label: const Text('Deactivate'),
          ),
        ],
        if (rule.status != DiscountStatuses.archived) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isUpdating ? null : onArchive,
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive'),
          ),
        ],
      ],
    );
  }
}
