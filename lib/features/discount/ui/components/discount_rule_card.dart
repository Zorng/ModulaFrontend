import 'package:flutter/material.dart';
import 'package:modular_pos/features/discount/domain/models/discount_rule.dart';

class DiscountRuleCard extends StatelessWidget {
  const DiscountRuleCard({
    super.key,
    required this.rule,
    required this.onTap,
    this.compact = false,
  });

  final DiscountRule rule;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compactTitleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.18,
    );
    final regularTitleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.15,
    );

    return Card(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedHeight = constraints.maxHeight.isFinite;
            return Padding(
              padding: EdgeInsets.all(compact ? 14 : 16),
              child: Column(
                mainAxisSize: hasBoundedHeight
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          rule.name,
                          maxLines: compact ? 2 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: compact
                              ? compactTitleStyle
                              : regularTitleStyle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _Tag(
                        label: rule.status,
                        color: _statusColor(rule.status),
                        compact: compact,
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 10 : 12),
                  Wrap(
                    spacing: compact ? 6 : 8,
                    runSpacing: compact ? 6 : 8,
                    children: [
                      _Tag(
                        label:
                            '${rule.percentage.toStringAsFixed(rule.percentage == rule.percentage.roundToDouble() ? 0 : 2)}%',
                        compact: compact,
                      ),
                      _Tag(
                        label: rule.scope == 'BRANCH_WIDE'
                            ? 'Branch-wide'
                            : 'Item-level',
                        compact: compact,
                      ),
                      if (!compact)
                        _Tag(
                          label: _stackingPolicyLabel(rule.stackingPolicy),
                          compact: compact,
                        ),
                    ],
                  ),
                  SizedBox(height: compact ? 10 : 14),
                  Text(
                    _scheduleLabel(rule),
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Assigned branch: ${rule.branchId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rule.scope == 'ITEM'
                        ? '${rule.itemIds.length} targeted item${rule.itemIds.length == 1 ? '' : 's'}'
                        : 'Applies across the assigned branch.',
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (!compact) ...[
                    SizedBox(height: hasBoundedHeight ? 0 : 16),
                    if (hasBoundedHeight) const Spacer(),
                    Row(
                      children: [
                        Text(
                          'View details',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_outward,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'ARCHIVED':
        return Colors.grey;
      default:
        return Colors.orange;
    }
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

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.color, this.compact = false});

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
