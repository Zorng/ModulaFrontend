import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';
import 'package:modular_pos/features/reporting/domain/models/restock_spend_reporting.dart';
import 'package:modular_pos/features/reporting/ui/models/restock_spend_drill_down_route_args.dart';
import 'package:modular_pos/features/reporting/ui/reporting_formatters.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/reporting_access_context.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/restock_spend_summary_controller.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_kpi_card.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_section_card.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_state_views.dart';

class InventoryReportingSummaryPage extends ConsumerStatefulWidget {
  const InventoryReportingSummaryPage({super.key});

  @override
  ConsumerState<InventoryReportingSummaryPage> createState() =>
      _InventoryReportingSummaryPageState();
}

class _InventoryReportingSummaryPageState
    extends ConsumerState<InventoryReportingSummaryPage> {
  static const String _allBranchesValue = '__all_branches__';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branchState = ref.read(branchControllerProvider);
      if (branchState.branches.isEmpty && !branchState.isLoading) {
        ref.read(branchControllerProvider.notifier).loadInitial();
      }

      final state = ref.read(restockSpendSummaryControllerProvider);
      if (state.report == null && !state.isLoading) {
        ref.read(restockSpendSummaryControllerProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restockSpendSummaryControllerProvider);
    final access = ref.watch(reportingAccessContextProvider);
    final tenantBranches = ref.watch(
      branchControllerProvider.select((value) => value.branches),
    );
    final isCustomRange = state.window == ReportTimeWindow.custom;

    final shouldAutoLoad =
        access != null &&
        access.canViewReporting &&
        state.report == null &&
        state.errorMessage == null &&
        !state.isLoading;
    if (shouldAutoLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final latestState = ref.read(restockSpendSummaryControllerProvider);
        if (latestState.report != null ||
            latestState.errorMessage != null ||
            latestState.isLoading) {
          return;
        }
        ref.read(restockSpendSummaryControllerProvider.notifier).load();
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useStackedLayout = constraints.maxWidth < 920;
        final header = _buildHeader(context);
        final filters = _buildFilters(
          context,
          state,
          tenantBranches: tenantBranches,
          stretchToAvailableWidth: useStackedLayout,
        );

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (useStackedLayout)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [header, const SizedBox(height: 20), filters],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: header),
                      const SizedBox(width: 24),
                      filters,
                    ],
                  ),
                if (isCustomRange) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Custom range: ${formatReportDateRange(state.selectedDateRange)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (state.errorMessage != null && state.report == null)
                  ReportingMessageStateView(
                    icon: Icons.inventory_2_outlined,
                    title: 'Inventory summary unavailable',
                    message: state.errorMessage!,
                    actionLabel: 'Retry',
                    onAction: () {
                      ref
                          .read(restockSpendSummaryControllerProvider.notifier)
                          .load();
                    },
                  )
                else ...[
                  _buildKpiSection(context, state),
                  const SizedBox(height: 24),
                  _buildMonthlyBreakdownSection(context, state),
                  if (state.report != null) ...[
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: () => _openDrillDown(context, state),
                        icon: const Icon(Icons.list_alt_outlined),
                        label: const Text('View Restock Details'),
                      ),
                    ),
                  ],
                ],
              ],
            ),
            if (state.isLoading)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.white.withValues(alpha: 0.72),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Restock spend',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Track purchasing spend and stock intake cost visibility.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildFilters(
    BuildContext context,
    RestockSpendSummaryState state, {
    required List<BranchListItem> tenantBranches,
    required bool stretchToAvailableWidth,
  }) {
    final controller = ref.read(restockSpendSummaryControllerProvider.notifier);
    final branchValue = state.branchScope == ReportBranchScope.allBranches
        ? _allBranchesValue
        : state.branchId;
    final dateFilter = InventoryDropdown<ReportTimeWindow>(
      initialValue: state.window,
      entries: const [
        DropdownMenuEntry(value: ReportTimeWindow.day, label: 'Today'),
        DropdownMenuEntry(value: ReportTimeWindow.week, label: 'Week'),
        DropdownMenuEntry(value: ReportTimeWindow.month, label: 'Month'),
        DropdownMenuEntry(value: ReportTimeWindow.custom, label: 'Custom'),
      ],
      onSelected: (value) async {
        if (value == null) return;
        if (value == ReportTimeWindow.custom) {
          final picked = await _pickDateRange(context, state);
          if (picked != null) {
            await controller.setDateRange(picked);
          }
          return;
        }
        await controller.setWindow(value);
      },
      leadingIcon: const Icon(Icons.calendar_today_outlined, size: 18),
      fillColor: Colors.white,
    );
    final branchFilter = InventoryDropdown<String>(
      initialValue: branchValue,
      entries: _branchDropdownEntries(state, tenantBranches),
      onSelected: (value) async {
        if (value == null) return;
        if (value == _allBranchesValue) {
          await controller.setBranchScope(ReportBranchScope.allBranches);
          return;
        }
        if (state.branchScope != ReportBranchScope.branch) {
          await controller.setBranchScope(ReportBranchScope.branch);
        }
        await controller.setBranchId(value);
      },
      leadingIcon: const Icon(Icons.storefront_outlined, size: 18),
      fillColor: Colors.white,
    );

    if (stretchToAvailableWidth) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final keepSingleRow = constraints.maxWidth >= 360;
          if (!keepSingleRow) {
            return Column(
              children: [dateFilter, const SizedBox(height: 12), branchFilter],
            );
          }

          return Row(
            children: [
              Expanded(child: dateFilter),
              const SizedBox(width: 12),
              Expanded(child: branchFilter),
            ],
          );
        },
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(width: 180, child: dateFilter),
          SizedBox(width: 240, child: branchFilter),
        ],
      ),
    );
  }

  List<DropdownMenuEntry<String>> _branchDropdownEntries(
    RestockSpendSummaryState state,
    List<BranchListItem> tenantBranches,
  ) {
    final branchLabels = <String, String>{};

    void addBranch(String id, String name) {
      final normalizedId = id.trim();
      final normalizedName = name.trim();
      if (normalizedId.isEmpty || normalizedName.isEmpty) return;
      branchLabels.putIfAbsent(normalizedId, () => normalizedName);
    }

    for (final branch in tenantBranches) {
      addBranch(branch.branchId, branch.branchName);
    }
    for (final branch in state.branches) {
      addBranch(branch.id, branch.name);
    }

    final currentBranchId = (state.branchId ?? '').trim();
    if (currentBranchId.isNotEmpty) {
      final knownBranch = state.branches.where((branch) {
        return branch.id.trim() == currentBranchId;
      });
      if (knownBranch.isNotEmpty) {
        addBranch(currentBranchId, knownBranch.first.name);
      } else {
        addBranch(currentBranchId, currentBranchId);
      }
    }

    final entries = branchLabels.entries.toList(growable: false)
      ..sort((a, b) => a.value.compareTo(b.value));

    return [
      if (state.canUseAllBranches)
        const DropdownMenuEntry(
          value: _allBranchesValue,
          label: 'All branches',
        ),
      for (final entry in entries)
        DropdownMenuEntry(value: entry.key, label: entry.value),
    ];
  }

  Future<DateTimeRange?> _pickDateRange(
    BuildContext context,
    RestockSpendSummaryState state,
  ) {
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      initialDateRange: state.selectedDateRange,
      helpText: 'Select custom range',
      saveText: 'Apply',
    );
  }

  Widget _buildKpiSection(
    BuildContext context,
    RestockSpendSummaryState state,
  ) {
    final totals = state.report?.totals;
    final cards = [
      ReportingKpiCard(
        title: 'Total Spend',
        value: totals == null
            ? '--'
            : formatUsdAmount(totals.knownCostSpendUsd),
        icon: Icons.payments_outlined,
      ),
      ReportingKpiCard(
        title: 'Known Batches',
        value: totals == null
            ? '--'
            : formatInteger(totals.knownCostBatchCount),
        icon: Icons.inventory_outlined,
        accentColor: const Color(0xFF2563EB),
      ),
      ReportingKpiCard(
        title: 'Unknown Batches',
        value: totals == null
            ? '--'
            : formatInteger(totals.unknownCostBatchCount),
        icon: Icons.help_outline,
        accentColor: const Color(0xFFF59E0B),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 920;
        if (isWide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  Expanded(child: cards[i]),
                  if (i != cards.length - 1) const SizedBox(width: 16),
                ],
              ],
            ),
          );
        }

        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              cards[i],
              if (i != cards.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMonthlyBreakdownSection(
    BuildContext context,
    RestockSpendSummaryState state,
  ) {
    final monthlyBreakdown = state.report?.monthlyBreakdown ?? const [];

    return ReportingSectionCard(
      title: 'Monthly breakdown',
      subtitle: 'Known spend and batch visibility by month',
      child: monthlyBreakdown.isEmpty
          ? Text(
              'Empty',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            )
          : Column(
              children: [
                for (var i = 0; i < monthlyBreakdown.length; i++) ...[
                  _MonthlyBreakdownRow(item: monthlyBreakdown[i]),
                  if (i != monthlyBreakdown.length - 1)
                    const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }

  void _openDrillDown(BuildContext context, RestockSpendSummaryState state) {
    final access = ref.read(reportingAccessContextProvider);
    if (access == null) return;
    final args = RestockSpendDrillDownRouteArgs(
      scope: state.toScopeQuery(fallbackBranchId: access.fallbackBranchId),
    );
    context.pushNamed(
      AppRoute.reportingInventoryDrillDown.name,
      extra: args,
      queryParameters: args.toQueryParameters(),
    );
  }
}

class _MonthlyBreakdownRow extends StatelessWidget {
  const _MonthlyBreakdownRow({required this.item});

  final RestockSpendMonthlyBreakdownItem item;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _formatMonthLabel(item.month),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatUsdAmount(item.knownCostSpendUsd),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'Known batches ${formatInteger(item.knownCostBatchCount)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Unknown batches ${formatInteger(item.unknownCostBatchCount)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatMonthLabel(String value) {
  final parsed = DateTime.tryParse('$value-01');
  if (parsed == null) return value;
  return DateFormat('MMM yyyy').format(parsed);
}
