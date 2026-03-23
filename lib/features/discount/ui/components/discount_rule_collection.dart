import 'package:flutter/material.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/features/discount/domain/models/discount_rule.dart';
import 'package:modular_pos/features/discount/ui/components/discount_rule_card.dart';
import 'package:modular_pos/features/discount/ui/components/discount_state_message.dart';

class DiscountRuleCollection extends StatelessWidget {
  const DiscountRuleCollection({
    super.key,
    required this.isLoading,
    required this.error,
    required this.rules,
    required this.width,
    required this.onRetry,
    this.onOpenCreate,
    required this.onOpenRule,
    required this.branchNamesById,
    this.emptyMessage = 'No discount rules match the current filters.',
  });

  final bool isLoading;
  final String? error;
  final List<DiscountRule> rules;
  final double width;
  final Future<void> Function() onRetry;
  final Future<void> Function()? onOpenCreate;
  final Future<void> Function(DiscountRule rule) onOpenRule;
  final Map<String, String> branchNamesById;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading && rules.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && error!.trim().isNotEmpty) {
      return DiscountStateMessage(
        message: UserErrorMessage.build(
          context: 'Failed to load discount rules',
          error: error,
        ),
        actionLabel: 'Retry',
        onAction: onRetry,
      );
    }

    if (rules.isEmpty) {
      return DiscountStateMessage(
        message: emptyMessage,
        actionLabel: onOpenCreate == null ? null : 'Add discount',
        onAction: onOpenCreate,
      );
    }

    if (width >= 1024) {
      return _WideDiscountTable(
        isLoading: isLoading,
        rules: rules,
        onOpenRule: onOpenRule,
        branchNamesById: branchNamesById,
      );
    }

    final crossAxisCount = _crossAxisCount(width);
    final useCompactCard = width < 780;
    if (crossAxisCount > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoading) const LinearProgressIndicator(minHeight: 2),
          if (isLoading) const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: _gridItemExtent(width),
              ),
              itemCount: rules.length,
              itemBuilder: (context, index) {
                final rule = rules[index];
                return DiscountRuleCard(
                  rule: rule,
                  compact: useCompactCard,
                  onTap: () => onOpenRule(rule),
                );
              },
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isLoading) const LinearProgressIndicator(minHeight: 2),
        if (isLoading) const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: rules.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final rule = rules[index];
              return DiscountRuleCard(
                rule: rule,
                compact: useCompactCard,
                onTap: () => onOpenRule(rule),
              );
            },
          ),
        ),
      ],
    );
  }

  int _crossAxisCount(double width) {
    if (width >= 1680) return 3;
    if (width >= 780) return 2;
    return 1;
  }

  double _gridItemExtent(double width) {
    if (width >= 1680) return 280;
    if (width >= 1200) return 264;
    return 248;
  }
}

class _WideDiscountTable extends StatelessWidget {
  const _WideDiscountTable({
    required this.isLoading,
    required this.rules,
    required this.onOpenRule,
    required this.branchNamesById,
  });

  final bool isLoading;
  final List<DiscountRule> rules;
  final Future<void> Function(DiscountRule rule) onOpenRule;
  final Map<String, String> branchNamesById;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isLoading) const LinearProgressIndicator(minHeight: 2),
        if (isLoading) const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = constraints.maxWidth;
              final columnSpacing = tableWidth >= 1480
                  ? 56.0
                  : tableWidth >= 1320
                  ? 44.0
                  : 32.0;
              final ruleColumnWidth = tableWidth >= 1480 ? 260.0 : 220.0;
              final scheduleColumnWidth = tableWidth >= 1480 ? 220.0 : 180.0;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: tableWidth),
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: tableWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTableTheme.background,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTableTheme.divider),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(1),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            child: DataTable(
                              dataRowMinHeight: 74,
                              dataRowMaxHeight: 88,
                              headingRowHeight: 68,
                              headingRowColor: WidgetStateProperty.all(
                                AppTableTheme.headerBackground,
                              ),
                              dataRowColor: const WidgetStatePropertyAll(
                                AppTableTheme.background,
                              ),
                              dividerThickness: 1,
                              horizontalMargin: 24,
                              columnSpacing: columnSpacing,
                              border: const TableBorder(
                                horizontalInside: BorderSide(
                                  color: AppTableTheme.divider,
                                ),
                              ),
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'No.',
                                    style: AppTableTheme.headerText,
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Discount Rule',
                                    style: AppTableTheme.headerText,
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Assigned Branch',
                                    style: AppTableTheme.headerText,
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Scope',
                                    style: AppTableTheme.headerText,
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Status',
                                    style: AppTableTheme.headerText,
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Schedule',
                                    style: AppTableTheme.headerText,
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Action',
                                    style: AppTableTheme.headerText,
                                  ),
                                ),
                              ],
                              rows: List<DataRow>.generate(rules.length, (
                                index,
                              ) {
                                final rule = rules[index];
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        '${index + 1}',
                                        style: AppTableTheme.cellText,
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: ruleColumnWidth,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Text(
                                                rule.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_percentageLabel(rule)} | ${_stackingPolicyLabel(rule.stackingPolicy)}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: IntrinsicWidth(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: AppTableTheme
                                                .categoryPillDecoration,
                                            child: Text(
                                              branchNamesById[rule.branchId] ??
                                                  rule.branchId,
                                              style: AppTableTheme
                                                  .categoryPillText,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      _TablePill(
                                        label: rule.scope == 'BRANCH_WIDE'
                                            ? 'Branch-wide'
                                            : 'Item-level',
                                      ),
                                    ),
                                    DataCell(
                                      _TablePill(
                                        label: _statusLabel(rule.status),
                                        color: _statusColor(rule.status),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: scheduleColumnWidth,
                                        child: Text(
                                          _scheduleLabel(rule),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTableTheme.cellText,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: IntrinsicWidth(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              minimumSize: const Size(0, 40),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 18,
                                                  ),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            onPressed: () => onOpenRule(rule),
                                            child: const Text('View details'),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static String _percentageLabel(DiscountRule rule) {
    final percentage = rule.percentage;
    return '${percentage.toStringAsFixed(percentage == percentage.roundToDouble() ? 0 : 2)}%';
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

  static String _statusLabel(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Active';
      case 'ARCHIVED':
        return 'Archived';
      default:
        return 'Inactive';
    }
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

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
}

class _TablePill extends StatelessWidget {
  const _TablePill({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
