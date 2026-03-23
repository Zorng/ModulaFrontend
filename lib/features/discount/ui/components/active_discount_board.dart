import 'package:flutter/material.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/discount/domain/models/discount_rule.dart';
import 'package:modular_pos/features/discount/ui/components/discount_state_message.dart';

class ActiveDiscountBoard extends StatelessWidget {
  const ActiveDiscountBoard({
    super.key,
    required this.isLoading,
    required this.error,
    required this.rules,
    required this.width,
    required this.onRetry,
    required this.branchNamesById,
    required this.itemNamesById,
    this.emptyMessage = 'No active discount rules are assigned to this branch.',
  });

  final bool isLoading;
  final String? error;
  final List<DiscountRule> rules;
  final double width;
  final Future<void> Function() onRetry;
  final Map<String, String> branchNamesById;
  final Map<String, String> itemNamesById;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading && rules.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && error!.trim().isNotEmpty) {
      return DiscountStateMessage(
        message: UserErrorMessage.build(
          context: 'Failed to load active discounts',
          error: error,
        ),
        actionLabel: 'Retry',
        onAction: onRetry,
      );
    }

    if (rules.isEmpty) {
      return DiscountStateMessage(message: emptyMessage);
    }

    final crossAxisCount = _crossAxisCount(width);
    final cards = [
      for (final rule in rules)
        ActiveDiscountRuleCard(
          rule: rule,
          assignedBranchLabel: branchNamesById[rule.branchId],
          itemNamesById: itemNamesById,
          compact: width < 720,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isLoading) const LinearProgressIndicator(minHeight: 2),
        if (isLoading) const SizedBox(height: 12),
        Expanded(
          child: crossAxisCount == 1
              ? ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 96),
                  itemBuilder: (context, index) => cards[index],
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemCount: cards.length,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 16.0;
                    final totalSpacing = spacing * (crossAxisCount - 1);
                    final cardWidth =
                        (constraints.maxWidth - totalSpacing) / crossAxisCount;
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 96),
                      child: Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final card in cards)
                            SizedBox(width: cardWidth, child: card),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  int _crossAxisCount(double width) {
    if (width >= 1680) return 3;
    if (width >= 980) return 2;
    return 1;
  }
}

class ActiveDiscountRuleCard extends StatelessWidget {
  const ActiveDiscountRuleCard({
    super.key,
    required this.rule,
    required this.itemNamesById,
    this.assignedBranchLabel,
    this.compact = false,
  });

  final DiscountRule rule;
  final Map<String, String> itemNamesById;
  final String? assignedBranchLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headlineStyle =
        (compact ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)
            ?.copyWith(fontWeight: FontWeight.w700, height: 1.15);

    return Card(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    rule.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: headlineStyle,
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => _showDetails(context),
                  child: const Text('See more'),
                ),
              ],
            ),
            SizedBox(height: compact ? 10 : 12),
            _SectionLabel(label: 'Summary'),
            const SizedBox(height: 8),
            _InfoLine(
              icon: Icons.percent_rounded,
              label: 'Discount',
              valueChild: _BoardTag(
                label:
                    '${rule.percentage.toStringAsFixed(rule.percentage == rule.percentage.roundToDouble() ? 0 : 2)}% off',
                compact: compact,
              ),
            ),
            const SizedBox(height: 8),
            _InfoLine(
              icon: Icons.sell_outlined,
              label: 'Scope',
              value: rule.scope == 'BRANCH_WIDE' ? 'Branch-wide' : 'Item-level',
            ),
            const SizedBox(height: 8),
            _InfoLine(
              icon: Icons.schedule_rounded,
              label: 'Schedule',
              value: _scheduleLabel(rule),
            ),
            const SizedBox(height: 8),
            _InfoLine(
              icon: Icons.storefront_outlined,
              label: 'Assigned branch',
              value: (assignedBranchLabel ?? '').trim().isEmpty
                  ? rule.branchId
                  : assignedBranchLabel!,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDetails(BuildContext context) {
    final itemNames = rule.itemIds
        .map((itemId) => (itemNamesById[itemId] ?? '').trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    final unresolvedItemCount = rule.itemIds.length - itemNames.length;
    final detail = _ActiveDiscountDetailView(
      rule: rule,
      assignedBranchLabel: assignedBranchLabel,
      itemNames: itemNames,
      unresolvedItemCount: unresolvedItemCount,
    );
    final width = MediaQuery.of(context).size.width;

    if (width < AppBreakpoints.medium) {
      return showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        useSafeArea: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => Material(
          color: Colors.white,
          child: FractionallySizedBox(heightFactor: 0.9, child: detail),
        ),
      );
    }

    return showDialog<void>(
      context: context,
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.86;
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 760, maxHeight: maxHeight),
            child: detail,
          ),
        );
      },
    );
  }

  static String _stackingPolicyLabel(String stackingPolicy) {
    switch (stackingPolicy) {
      case 'MULTIPLICATIVE':
        return 'Multiplicative';
      default:
        return stackingPolicy;
    }
  }

  static String _scheduleLabel(DiscountRule rule) {
    final start = rule.schedule.startAt;
    final end = rule.schedule.endAt;
    if (start == null && end == null) {
      return 'Always on';
    }
    final startText = start == null
        ? 'Now'
        : '${start.year}-${_two(start.month)}-${_two(start.day)} ${_two(start.hour)}:${_two(start.minute)}';
    final endText = end == null
        ? 'Open end'
        : '${end.year}-${_two(end.month)}-${_two(end.day)} ${_two(end.hour)}:${_two(end.minute)}';
    return '$startText to $endText';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

class _ActiveDiscountDetailView extends StatelessWidget {
  const _ActiveDiscountDetailView({
    required this.rule,
    required this.itemNames,
    required this.unresolvedItemCount,
    this.assignedBranchLabel,
  });

  final DiscountRule rule;
  final List<String> itemNames;
  final int unresolvedItemCount;
  final String? assignedBranchLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveLabel = rule.isCurrentlyEligible
        ? 'Effective now'
        : 'Scheduled active';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _BoardTag(
                          label:
                              '${rule.percentage.toStringAsFixed(rule.percentage == rule.percentage.roundToDouble() ? 0 : 2)}% off',
                        ),
                        _BoardTag(
                          label: rule.scope == 'BRANCH_WIDE'
                              ? 'Branch-wide'
                              : 'Item-level',
                        ),
                        _BoardTag(
                          label: effectiveLabel,
                          color: rule.isCurrentlyEligible
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close),
                tooltip: 'Close',
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(label: 'Summary'),
                const SizedBox(height: 10),
                _InfoLine(
                  icon: Icons.percent_rounded,
                  label: 'Discount',
                  value:
                      '${rule.percentage.toStringAsFixed(rule.percentage == rule.percentage.roundToDouble() ? 0 : 2)}% off',
                ),
                const SizedBox(height: 10),
                _InfoLine(
                  icon: Icons.sell_outlined,
                  label: 'Scope',
                  value: rule.scope == 'BRANCH_WIDE'
                      ? 'Branch-wide'
                      : 'Item-level',
                ),
                const SizedBox(height: 10),
                _InfoLine(
                  icon: Icons.schedule_rounded,
                  label: 'Schedule',
                  value: ActiveDiscountRuleCard._scheduleLabel(rule),
                ),
                const SizedBox(height: 10),
                _InfoLine(
                  icon: Icons.storefront_outlined,
                  label: 'Assigned branch',
                  value: (assignedBranchLabel ?? '').trim().isEmpty
                      ? rule.branchId
                      : assignedBranchLabel!,
                ),
                const SizedBox(height: 10),
                _InfoLine(
                  icon: Icons.layers_outlined,
                  label: 'Stacking',
                  value: ActiveDiscountRuleCard._stackingPolicyLabel(
                    rule.stackingPolicy,
                  ),
                ),
                const SizedBox(height: 18),
                _SectionLabel(
                  label: rule.scope == 'BRANCH_WIDE'
                      ? 'Coverage'
                      : 'Discounted Items',
                ),
                const SizedBox(height: 10),
                if (rule.scope == 'BRANCH_WIDE')
                  Text(
                    'Applies across the assigned branch menu.',
                    style: theme.textTheme.bodyMedium,
                  )
                else if (itemNames.isEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${rule.itemIds.length} targeted item${rule.itemIds.length == 1 ? '' : 's'} configured for this rule.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Item names are currently unavailable from branch menu data.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final itemName in itemNames)
                        _BoardTag(label: itemName),
                    ],
                  ),
                if (unresolvedItemCount > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    '$unresolvedItemCount item name${unresolvedItemCount == 1 ? ' is' : 's are'} unavailable from the current branch menu snapshot.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    this.value,
    this.valueChild,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueChild;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: valueChild != null
              ? Align(alignment: Alignment.centerLeft, child: valueChild)
              : Text(
                  value ?? '',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
        ),
      ],
    );
  }
}

class _BoardTag extends StatelessWidget {
  const _BoardTag({required this.label, this.color, this.compact = false});

  final String label;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: effectiveColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
