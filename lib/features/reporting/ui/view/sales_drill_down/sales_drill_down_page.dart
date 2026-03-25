import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';
import 'package:modular_pos/features/reporting/ui/models/sales_drill_down_route_args.dart';
import 'package:modular_pos/features/reporting/ui/reporting_formatters.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/reporting_access_context.dart';
import 'package:modular_pos/features/reporting/ui/viewmodels/sales_drill_down_controller.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_state_views.dart';

const String _allBranchesValue = '__all_branches__';

class SalesDrillDownPage extends ConsumerStatefulWidget {
  const SalesDrillDownPage({super.key, required this.args});

  final SalesDrillDownRouteArgs args;

  @override
  ConsumerState<SalesDrillDownPage> createState() => _SalesDrillDownPageState();
}

class _SalesDrillDownPageState extends ConsumerState<SalesDrillDownPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branchState = ref.read(branchControllerProvider);
      if (branchState.branches.isEmpty && !branchState.isLoading) {
        ref.read(branchControllerProvider.notifier).loadInitial();
      }
      ref
          .read(salesDrillDownControllerProvider.notifier)
          .initialize(widget.args);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salesDrillDownControllerProvider);
    final controller = ref.read(salesDrillDownControllerProvider.notifier);
    final items = state.report?.items ?? const <SalesDrillDownItem>[];
    final access = ref.watch(reportingAccessContextProvider);
    final tenantBranches = ref.watch(
      branchControllerProvider.select((state) => state.branches),
    );
    final branchNames = {
      for (final branch in tenantBranches) branch.branchId: branch.branchName,
      for (final branch in access?.branches ?? const []) branch.id: branch.name,
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const AppBackButton(),
        title: const Text('Sales Details'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 600 ? 16.0 : 20.0;
          final header = _buildHeader(context, state);
          final branchEntries = _branchDropdownEntries(
            state,
            access: access,
            tenantBranches: tenantBranches,
          );
          final filterStatusItems = _filterStatusItems(
            state,
            branchEntries: branchEntries,
          );

          return ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              20,
            ),
            children: [
              header,
              const SizedBox(height: 16),
              _buildFilterContainer(
                context,
                filterStatusItems: filterStatusItems,
                hasFiltersApplied: _hasFiltersApplied(state),
                onFilterPressed: () => _openFilterModal(
                  context,
                  state,
                  branchEntries: branchEntries,
                ),
              ),
              const SizedBox(height: 20),
              if (state.isLoading && state.report == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.errorMessage != null && state.report == null)
                ReportingMessageStateView(
                  icon: Icons.receipt_long_outlined,
                  title: 'Sales details unavailable',
                  message: state.errorMessage!,
                  actionLabel: 'Retry',
                  onAction: controller.refresh,
                )
              else if (items.isEmpty)
                const ReportingMessageStateView(
                  icon: Icons.receipt_long_outlined,
                  title: 'No sales found',
                  message: 'No sales match the current filters.',
                )
              else ...[
                for (var i = 0; i < items.length; i++) ...[
                  _SalesDrillDownRecordCard(
                    item: items[i],
                    branchName:
                        branchNames[items[i].branchId] ??
                        _routeBranchNameForItem(items[i], state),
                  ),
                  if (i != items.length - 1) const SizedBox(height: 12),
                ],
                const SizedBox(height: 16),
                if (state.report!.hasMore || state.isLoadingMore)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      onPressed: state.isLoadingMore
                          ? null
                          : controller.loadMore,
                      child: state.isLoadingMore
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Load more'),
                    ),
                  ),
                if (state.errorMessage != null && state.report != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SalesDrillDownState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.report != null) ...[
          const SizedBox(height: 12),
          Text(
            _summaryLabel(state.report!),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterContainer(
    BuildContext context, {
    required List<_SalesFilterStatusItem> filterStatusItems,
    required bool hasFiltersApplied,
    required VoidCallback onFilterPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTableTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTableTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Current filter',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _SalesFilterActionButton(
                hasFiltersApplied: hasFiltersApplied,
                onPressed: onFilterPressed,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in filterStatusItems)
                _SalesFilterInfoCard(item: item),
            ],
          ),
        ],
      ),
    );
  }

  List<_SalesFilterStatusItem> _filterStatusItems(
    SalesDrillDownState state, {
    required List<DropdownMenuEntry<String>> branchEntries,
  }) {
    final scope = state.scope ?? widget.args.scope;
    final initialScope = _normalizedSalesScope(widget.args.scope);
    final currentScope = _normalizedSalesScope(scope);

    return [
      _SalesFilterStatusItem(
        label: 'Date',
        value: _dateFilterLabel(scope),
        isEmphasized: !_sameSalesScope(currentScope, initialScope),
      ),
      _SalesFilterStatusItem(
        label: 'Status',
        value: _statusFilterLabel(state.statusFilter),
        isEmphasized: state.statusFilter != SalesDrillDownStatusFilter.all,
      ),
      _SalesFilterStatusItem(
        label: 'Branch',
        value: _branchFilterLabel(state, branchEntries: branchEntries),
        isEmphasized:
            currentScope.branchScope != initialScope.branchScope ||
            currentScope.branchId != initialScope.branchId,
      ),
    ];
  }

  bool _hasFiltersApplied(SalesDrillDownState state) {
    final scope = state.scope;
    if (scope == null) return false;
    return !_sameSalesScope(
          _normalizedSalesScope(scope),
          _normalizedSalesScope(widget.args.scope),
        ) ||
        state.statusFilter != SalesDrillDownStatusFilter.all;
  }

  String _dateFilterLabel(ReportScopeQuery scope) {
    switch (scope.window) {
      case ReportTimeWindow.day:
        return 'Today';
      case ReportTimeWindow.week:
        return 'Week';
      case ReportTimeWindow.month:
        return 'Month';
      case ReportTimeWindow.custom:
        return formatReportDateRange(_dateRangeForQueryScope(scope));
    }
  }

  String _statusFilterLabel(SalesDrillDownStatusFilter value) {
    switch (value) {
      case SalesDrillDownStatusFilter.all:
        return 'All statuses';
      case SalesDrillDownStatusFilter.finalized:
        return 'Finalized';
      case SalesDrillDownStatusFilter.voidPending:
        return 'Void pending';
      case SalesDrillDownStatusFilter.voided:
        return 'Voided';
    }
  }

  String _branchFilterLabel(
    SalesDrillDownState state, {
    required List<DropdownMenuEntry<String>> branchEntries,
  }) {
    final scope = state.scope ?? widget.args.scope;
    if (scope.branchScope == ReportBranchScope.allBranches) {
      return 'All branches';
    }

    final branchId = scope.branchId?.trim();
    if (branchId == null || branchId.isEmpty) {
      return _routeBranchNameForScope(scope) ?? 'Selected branch';
    }

    for (final entry in branchEntries) {
      if (entry.value == branchId) {
        return entry.label;
      }
    }

    final routeBranchName = _routeBranchNameForScope(scope);
    if (routeBranchName != null) {
      return routeBranchName;
    }

    return 'Selected branch';
  }

  Future<void> _openFilterModal(
    BuildContext context,
    SalesDrillDownState state, {
    required List<DropdownMenuEntry<String>> branchEntries,
  }) async {
    final scope = state.scope ?? widget.args.scope;
    final draft = await _showFilterModal(
      context,
      initialDraft: _SalesDrillDownFilterDraft(
        window: scope.window,
        dateRange: _dateRangeForQueryScope(scope),
        statusFilter: state.statusFilter,
        branchScope: scope.branchScope,
        branchId: scope.branchId,
      ),
      branchEntries: branchEntries,
    );
    if (draft == null || !mounted) return;

    await ref
        .read(salesDrillDownControllerProvider.notifier)
        .applyFilters(
          window: draft.window,
          selectedDateRange: draft.dateRange,
          branchScope: draft.branchScope,
          branchId: draft.branchId,
          statusFilter: draft.statusFilter,
        );
  }

  Future<_SalesDrillDownFilterDraft?> _showFilterModal(
    BuildContext context, {
    required _SalesDrillDownFilterDraft initialDraft,
    required List<DropdownMenuEntry<String>> branchEntries,
  }) {
    return Navigator.of(context).push<_SalesDrillDownFilterDraft>(
      MaterialPageRoute<_SalesDrillDownFilterDraft>(
        fullscreenDialog: true,
        builder: (context) => _SalesDrillDownFilterScreen(
          child: _SalesDrillDownFilterSheet(
            initialDraft: initialDraft,
            branchEntries: branchEntries,
          ),
        ),
      ),
    );
  }

  List<DropdownMenuEntry<String>> _branchDropdownEntries(
    SalesDrillDownState state, {
    required ReportingAccessContext? access,
    required List<BranchListItem> tenantBranches,
  }) {
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
    if (access != null) {
      for (final branch in access.branches) {
        addBranch(branch.id, branch.name);
      }
    }

    final currentBranchId = (state.branchId ?? '').trim();
    if (currentBranchId.isNotEmpty &&
        !branchLabels.containsKey(currentBranchId)) {
      addBranch(
        currentBranchId,
        _routeBranchNameForScope(state.scope ?? widget.args.scope) ??
            'Selected branch',
      );
    }

    final entries = branchLabels.entries.toList(growable: false)
      ..sort((a, b) => a.value.compareTo(b.value));

    return [
      if (access?.canUseAllBranches == true)
        const DropdownMenuEntry(
          value: _allBranchesValue,
          label: 'All branches',
        ),
      for (final entry in entries)
        DropdownMenuEntry(value: entry.key, label: entry.value),
    ];
  }

  String? _routeBranchNameForItem(
    SalesDrillDownItem item,
    SalesDrillDownState state,
  ) {
    final scopedBranchId = state.branchId?.trim();
    if (state.branchScope != ReportBranchScope.branch ||
        scopedBranchId == null ||
        scopedBranchId.isEmpty ||
        item.branchId.trim() != scopedBranchId) {
      return null;
    }
    final branchName = widget.args.branchName?.trim();
    if (branchName == null || branchName.isEmpty) {
      return null;
    }
    return branchName;
  }

  String? _routeBranchNameForScope(ReportScopeQuery scope) {
    final scopedBranchId = scope.branchId?.trim();
    if (scope.branchScope != ReportBranchScope.branch ||
        scopedBranchId == null ||
        scopedBranchId.isEmpty ||
        widget.args.scope.branchId?.trim() != scopedBranchId) {
      return null;
    }
    final branchName = widget.args.branchName?.trim();
    if (branchName == null || branchName.isEmpty) {
      return null;
    }
    return branchName;
  }
}

class _SalesFilterInfoCard extends StatelessWidget {
  const _SalesFilterInfoCard({required this.item});

  final _SalesFilterStatusItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = item.isEmphasized
        ? colorScheme.primary.withValues(alpha: 0.08)
        : AppTableTheme.headerBackground;
    final borderColor = item.isEmphasized
        ? colorScheme.primary.withValues(alpha: 0.35)
        : AppTableTheme.divider;
    final labelColor = item.isEmphasized
        ? colorScheme.primary
        : const Color(0xFF6B7280);
    final valueColor = item.isEmphasized
        ? const Color(0xFF1F2937)
        : const Color(0xFF2B2B2B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${item.label}: ',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
            TextSpan(
              text: item.value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: item.isEmphasized
                    ? FontWeight.w700
                    : FontWeight.w600,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesFilterActionButton extends StatelessWidget {
  const _SalesFilterActionButton({
    required this.hasFiltersApplied,
    required this.onPressed,
  });

  final bool hasFiltersApplied;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          onPressed: onPressed,
          child: const Text('Filter'),
        ),
        if (hasFiltersApplied)
          const Positioned(top: 4, right: 4, child: _SalesFilterAppliedDot()),
      ],
    );
  }
}

class _SalesFilterStatusItem {
  const _SalesFilterStatusItem({
    required this.label,
    required this.value,
    this.isEmphasized = false,
  });

  final String label;
  final String value;
  final bool isEmphasized;
}

class _SalesFilterAppliedDot extends StatelessWidget {
  const _SalesFilterAppliedDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: Color(0xFFD14343),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SalesDrillDownFilterDraft {
  const _SalesDrillDownFilterDraft({
    required this.window,
    required this.dateRange,
    required this.statusFilter,
    required this.branchScope,
    required this.branchId,
  });

  final ReportTimeWindow window;
  final DateTimeRange dateRange;
  final SalesDrillDownStatusFilter statusFilter;
  final ReportBranchScope branchScope;
  final String? branchId;
}

class _SalesDrillDownFilterSheet extends StatefulWidget {
  const _SalesDrillDownFilterSheet({
    required this.initialDraft,
    required this.branchEntries,
  });

  final _SalesDrillDownFilterDraft initialDraft;
  final List<DropdownMenuEntry<String>> branchEntries;

  @override
  State<_SalesDrillDownFilterSheet> createState() =>
      _SalesDrillDownFilterSheetState();
}

class _SalesDrillDownFilterSheetState
    extends State<_SalesDrillDownFilterSheet> {
  late ReportTimeWindow _window;
  late DateTimeRange _dateRange;
  late SalesDrillDownStatusFilter _statusFilter;
  late String _branchValue;

  @override
  void initState() {
    super.initState();
    _window = widget.initialDraft.window;
    _dateRange = widget.initialDraft.dateRange;
    _statusFilter = widget.initialDraft.statusFilter;
    _branchValue =
        widget.initialDraft.branchScope == ReportBranchScope.allBranches
        ? _allBranchesValue
        : ((widget.initialDraft.branchId ?? '').trim().isNotEmpty
              ? widget.initialDraft.branchId!.trim()
              : _fallbackBranchValue());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Filter sales',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Adjust date, status, and branch filters for this drill-down view.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF4B5563)),
          ),
          const SizedBox(height: 20),
          Text(
            'Date',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          InventoryDropdown<ReportTimeWindow>(
            initialValue: _window,
            entries: const [
              DropdownMenuEntry(value: ReportTimeWindow.day, label: 'Today'),
              DropdownMenuEntry(value: ReportTimeWindow.week, label: 'Week'),
              DropdownMenuEntry(value: ReportTimeWindow.month, label: 'Month'),
              DropdownMenuEntry(
                value: ReportTimeWindow.custom,
                label: 'Custom',
              ),
            ],
            onSelected: (value) async {
              if (value == null) return;
              if (value == ReportTimeWindow.custom) {
                final picked = await _pickDateRange();
                if (picked == null || !mounted) return;
                setState(() {
                  _window = ReportTimeWindow.custom;
                  _dateRange = picked;
                });
                return;
              }
              setState(() => _window = value);
            },
            leadingIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            fillColor: Colors.white,
          ),
          if (_window == ReportTimeWindow.custom) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await _pickDateRange();
                if (picked == null || !mounted) return;
                setState(() => _dateRange = picked);
              },
              icon: const Icon(Icons.date_range_outlined),
              label: const Text('Pick range'),
            ),
            const SizedBox(height: 8),
            Text(
              formatReportDateRange(_dateRange),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF4B5563)),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Status',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          InventoryDropdown<SalesDrillDownStatusFilter>(
            initialValue: _statusFilter,
            entries: const [
              DropdownMenuEntry(
                value: SalesDrillDownStatusFilter.all,
                label: 'All statuses',
              ),
              DropdownMenuEntry(
                value: SalesDrillDownStatusFilter.finalized,
                label: 'Finalized',
              ),
              DropdownMenuEntry(
                value: SalesDrillDownStatusFilter.voidPending,
                label: 'Void pending',
              ),
              DropdownMenuEntry(
                value: SalesDrillDownStatusFilter.voided,
                label: 'Voided',
              ),
            ],
            onSelected: (value) {
              if (value == null) return;
              setState(() => _statusFilter = value);
            },
            leadingIcon: const Icon(Icons.filter_list_outlined, size: 18),
            fillColor: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            'Branch',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          InventoryDropdown<String>(
            initialValue: _branchValue,
            entries: widget.branchEntries,
            enabled: widget.branchEntries.isNotEmpty,
            onSelected: (value) {
              if (value == null) return;
              setState(() => _branchValue = value);
            },
            leadingIcon: const Icon(Icons.storefront_outlined, size: 18),
            fillColor: Colors.white,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fallbackBranchValue() {
    if (widget.branchEntries.isEmpty) {
      return '';
    }
    for (final entry in widget.branchEntries) {
      if (entry.value != _allBranchesValue) {
        return entry.value;
      }
    }
    return widget.branchEntries.first.value;
  }

  Future<DateTimeRange?> _pickDateRange() {
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      initialDateRange: _dateRange,
      saveText: 'Apply',
    );
  }

  void _apply() {
    Navigator.of(context).pop(
      _SalesDrillDownFilterDraft(
        window: _window,
        dateRange: _dateRange,
        statusFilter: _statusFilter,
        branchScope: _branchValue == _allBranchesValue
            ? ReportBranchScope.allBranches
            : ReportBranchScope.branch,
        branchId: _branchValue == _allBranchesValue ? null : _branchValue,
      ),
    );
  }
}

class _SalesDrillDownFilterScreen extends StatelessWidget {
  const _SalesDrillDownFilterScreen({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Close',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                16 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SalesDrillDownRecordCard extends StatelessWidget {
  const _SalesDrillDownRecordCard({required this.item, this.branchName});

  final SalesDrillDownItem item;
  final String? branchName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final branchLabel = switch (branchName?.trim()) {
      final String value when value.isNotEmpty => value,
      _ => 'Branch',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branchLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatShortDateTime(item.finalizedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _SalesMetaChip(
                      label: formatSalesPaymentMethodLabel(item.paymentMethod),
                    ),
                    _SalesMetaChip(label: formatSalesTypeLabel(item.saleType)),
                    _SalesMetaChip(
                      label: 'Items ${formatInteger(item.totalItems)}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      'VAT ${formatUsdAmount(item.vatUsd)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Discount ${formatUsdAmount(item.discountUsd)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.topRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatUsdAmount(item.grandTotalUsd),
                    textAlign: TextAlign.right,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatKhrAmountLabel(item.grandTotalKhr),
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SalesMetaChip(
                    label: formatSalesRecordStatusLabel(item.status),
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

class _SalesMetaChip extends StatelessWidget {
  const _SalesMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475467),
        ),
      ),
    );
  }
}

String _summaryLabel(SalesDrillDownReport report) {
  final shown = report.items.length;
  final total = report.total;
  return 'Showing $shown of $total records';
}

ReportScopeQuery _normalizedSalesScope(ReportScopeQuery scope) {
  return ReportScopeQuery(
    window: scope.window,
    from: scope.from?.trim().isEmpty == true ? null : scope.from?.trim(),
    to: scope.to?.trim().isEmpty == true ? null : scope.to?.trim(),
    branchScope: scope.branchScope,
    branchId: scope.branchId?.trim().isEmpty == true
        ? null
        : scope.branchId?.trim(),
  );
}

bool _sameSalesScope(ReportScopeQuery left, ReportScopeQuery right) {
  return left.window == right.window &&
      left.from == right.from &&
      left.to == right.to &&
      left.branchScope == right.branchScope &&
      left.branchId == right.branchId;
}

DateTimeRange _dateRangeForQueryScope(ReportScopeQuery scope) {
  if (scope.window == ReportTimeWindow.custom) {
    final start = DateTime.tryParse(scope.from ?? '');
    final end = DateTime.tryParse(scope.to ?? '');
    if (start != null && end != null) {
      return DateTimeRange(start: start, end: end);
    }
  }

  final today = DateTime.now();
  final normalizedToday = DateTime(today.year, today.month, today.day);
  return DateTimeRange(start: normalizedToday, end: normalizedToday);
}
