import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';
import 'package:modular_pos/features/reporting/ui/models/sales_drill_down_route_args.dart';
import 'package:modular_pos/features/reporting/ui/reporting_formatters.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/reporting_access_context.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/sales_summary_controller.dart';
import 'package:modular_pos/features/reporting/ui/widgets/sales_cash_tender_breakdown_panel.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_kpi_card.dart';
import 'package:modular_pos/features/reporting/ui/widgets/sales_category_breakdown_panel.dart';
import 'package:modular_pos/features/reporting/ui/widgets/sales_payment_breakdown_panel.dart';
import 'package:modular_pos/features/reporting/ui/widgets/sales_type_breakdown_panel.dart';

class SalesSummaryPage extends ConsumerStatefulWidget {
  const SalesSummaryPage({super.key});

  @override
  ConsumerState<SalesSummaryPage> createState() => _SalesSummaryPageState();
}

class _SalesSummaryPageState extends ConsumerState<SalesSummaryPage> {
  static const String _allBranchesValue = '__all_branches__';
  static const double _summaryPanelGap = 16;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branchState = ref.read(branchControllerProvider);
      if (branchState.branches.isEmpty && !branchState.isLoading) {
        ref.read(branchControllerProvider.notifier).loadInitial();
      }

      final state = ref.read(salesSummaryControllerProvider);
      if (state.report == null && !state.isLoading) {
        ref.read(salesSummaryControllerProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salesSummaryControllerProvider);
    final access = ref.watch(reportingAccessContextProvider);
    final tenantBranches = ref.watch(
      branchControllerProvider.select((state) => state.branches),
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
        final latestState = ref.read(salesSummaryControllerProvider);
        if (latestState.report != null ||
            latestState.errorMessage != null ||
            latestState.isLoading) {
          return;
        }
        ref.read(salesSummaryControllerProvider.notifier).load();
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
                _buildKpiSection(context, state),
                const SizedBox(height: 24),
                _buildSalesSummaryPanels(state),
                if (state.report != null && access != null) ...[
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () => _openDrillDown(
                        context,
                        state,
                        access,
                        tenantBranches,
                      ),
                      icon: const Icon(Icons.list_alt_outlined),
                      label: const Text('View Sales Details'),
                    ),
                  ),
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
          'Overview',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Track sales performance.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildFilters(
    BuildContext context,
    SalesSummaryState state, {
    required List<BranchListItem> tenantBranches,
    required bool stretchToAvailableWidth,
  }) {
    final controller = ref.read(salesSummaryControllerProvider.notifier);
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
    SalesSummaryState state,
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
    SalesSummaryState state,
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

  Widget _buildKpiSection(BuildContext context, SalesSummaryState state) {
    final cards = state.kpis
        .map(
          (item) => ReportingKpiCard(
            title: item.title,
            value: item.value,
            secondaryValue: item.secondaryValue,
            icon: item.icon,
            accentColor: item.accentColor,
          ),
        )
        .toList(growable: false);

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

  Widget _buildSalesSummaryPanels(SalesSummaryState state) {
    const wideLeftFlex = 1;
    const wideRightFlex = 1;
    final paymentBreakdownItems = state.report?.paymentBreakdown ?? const [];
    final cashTenderBreakdownItems =
        state.report?.cashTenderBreakdown ?? const [];
    final categoryBreakdownItems = state.report?.categoryBreakdown ?? const [];
    final saleTypeBreakdownItems = state.report?.saleTypeBreakdown ?? const [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useWideLayout = constraints.maxWidth >= 980;
        if (!useWideLayout) {
          return Column(
            children: [
              SalesPaymentBreakdownPanel(items: paymentBreakdownItems),
              const SizedBox(height: _summaryPanelGap),
              SalesCategoryBreakdownPanel(categories: categoryBreakdownItems),
              const SizedBox(height: _summaryPanelGap),
              SalesTypeBreakdownPanel(items: saleTypeBreakdownItems),
              const SizedBox(height: _summaryPanelGap),
              SalesCashTenderBreakdownPanel(items: cashTenderBreakdownItems),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: wideLeftFlex,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SalesPaymentBreakdownPanel(items: paymentBreakdownItems),
                  const SizedBox(height: _summaryPanelGap),
                  SalesCategoryBreakdownPanel(
                    categories: categoryBreakdownItems,
                  ),
                ],
              ),
            ),
            const SizedBox(width: _summaryPanelGap),
            Expanded(
              flex: wideRightFlex,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SalesTypeBreakdownPanel(items: saleTypeBreakdownItems),
                  SizedBox(height: _summaryPanelGap),
                  SalesCashTenderBreakdownPanel(
                    items: cashTenderBreakdownItems,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _openDrillDown(
    BuildContext context,
    SalesSummaryState state,
    ReportingAccessContext access,
    List<BranchListItem> tenantBranches,
  ) {
    final scope = state.toScopeQuery(fallbackBranchId: access.fallbackBranchId);
    final selectedBranchName = scope.branchScope == ReportBranchScope.branch
        ? tenantBranches
                  .where((branch) => branch.branchId == scope.branchId)
                  .map((branch) => branch.branchName)
                  .firstOrNull ??
              access.branches
                  .where((branch) => branch.id == scope.branchId)
                  .map((branch) => branch.name)
                  .firstOrNull
        : null;
    final args = SalesDrillDownRouteArgs(
      scope: scope,
      branchName: selectedBranchName,
    );
    context.pushNamed(
      AppRoute.reportingSalesDrillDown.name,
      extra: args,
      queryParameters: args.toQueryParameters(),
    );
  }
}
