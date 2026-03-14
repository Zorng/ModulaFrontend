import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/models/inventory_journal_reason_filter.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_journal/inventory_journal_utils.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_journal/widgets/inventory_journal_date_field.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_journal_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';

class InventoryJournalPage extends ConsumerStatefulWidget {
  const InventoryJournalPage({super.key});

  @override
  ConsumerState<InventoryJournalPage> createState() =>
      _InventoryJournalPageState();
}

class _InventoryJournalPageState extends ConsumerState<InventoryJournalPage> {
  static const int _pageSize = 10;

  InventoryJournalReasonFilter? _selectedReasonFilter;
  _JournalDatePreset _datePreset = _JournalDatePreset.today;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final current = ref.read(inventoryJournalControllerProvider);
    _selectedReasonFilter = _reasonFilterFromDomain(current.selectedReason);
    final initialRange = _rangeForPreset(_JournalDatePreset.today);
    _startDate = initialRange.start;
    _endDate = initialRange.end;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(branchControllerProvider.notifier).loadInitial();
      final stockState = ref.read(stockInventoryControllerProvider);
      if (stockState.stockItems.isEmpty) {
        ref.read(stockInventoryControllerProvider.notifier).loadStockItems();
      }
      final state = ref.read(inventoryJournalControllerProvider);
      if (state.entries.isNotEmpty ||
          state.selectedStockItemId.isNotEmpty ||
          state.selectedBranchId != 'all' ||
          state.selectedReason != null) {
        return;
      }
      ref
          .read(inventoryJournalControllerProvider.notifier)
          .load(limit: _pageSize);
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isSmallScreen = AppBreakpoints.isSmall(width);
    final loginState = ref.watch(loginControllerProvider);
    final activeTenantId =
        (loginState.session?.activeTenantId ??
                loginState.session?.user.tenantId)
            ?.trim() ??
        '';
    final tenantBranches = ref
        .watch(branchControllerProvider.select((state) => state.branches))
        .where(
          (branch) =>
              activeTenantId.isEmpty ||
              branch.tenantId.trim().isEmpty ||
              branch.tenantId.trim() == activeTenantId,
        )
        .toList(growable: false);
    final stockItems = ref.watch(
      stockInventoryControllerProvider.select((state) => state.stockItems),
    );
    final journalState = ref.watch(inventoryJournalControllerProvider);
    final entries = journalState.entries;
    final selectedItemLabel = _selectedItemLabel(
      entries: entries,
      stockItems: stockItems,
      selectedStockItemId: journalState.selectedStockItemId,
    );
    final branchOptions = _branchOptions(
      entries,
      tenantBranches: tenantBranches,
      userBranches: loginState.user?.branches ?? const <UserBranch>[],
    );
    final filteredEntries = _filteredEntries(entries);
    final dateGroups = _groupByDate(filteredEntries);
    final filterStatusItems = _filterStatusItems(
      selectedItemLabel: selectedItemLabel,
      selectedStockItemId: journalState.selectedStockItemId,
      selectedBranchId: journalState.selectedBranchId,
      branchOptions: branchOptions,
    );
    final hasFiltersApplied =
        journalState.selectedStockItemId.isNotEmpty ||
        journalState.selectedBranchId != 'all' ||
        _selectedReasonFilter != null ||
        _datePreset != _JournalDatePreset.today;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _JournalPageHeader(
              filterStatusItems: filterStatusItems,
              hasFiltersApplied: hasFiltersApplied,
              onFilterPressed: () => _openFilterModal(
                context,
                branchOptions: branchOptions,
                stockItems: stockItems,
                selectedBranchId: journalState.selectedBranchId,
                selectedItemId: journalState.selectedStockItemId,
                selectedItemName: selectedItemLabel,
              ),
            ),
            const SizedBox(height: 16),
            if (journalState.error != null && entries.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SelectionBanner(
                text: journalState.error!,
                actionLabel: 'Retry',
                onPressed: _reloadCurrentQuery,
                isError: true,
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: journalState.isLoading && entries.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : journalState.error != null && entries.isEmpty
                  ? _JournalInitialError(
                      message: journalState.error!,
                      onRetry: _reloadCurrentQuery,
                    )
                  : dateGroups.isEmpty
                  ? _JournalEmptyState(message: _emptyStateMessage)
                  : isSmallScreen
                  ? _JournalMobileList(
                      groups: dateGroups,
                      hasMore: journalState.hasMore,
                      isLoadingMore: journalState.isLoadingMore,
                      onLoadMore: _loadMore,
                    )
                  : _JournalDesktopTable(
                      groups: dateGroups,
                      hideItemColumn:
                          journalState.selectedStockItemId.isNotEmpty,
                      hideBranchColumn: journalState.selectedBranchId != 'all',
                      hasMore: journalState.hasMore,
                      isLoadingMore: journalState.isLoadingMore,
                      onLoadMore: _loadMore,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String get _dateLabel {
    return switch (_datePreset) {
      _JournalDatePreset.today => 'Today',
      _JournalDatePreset.yesterday => 'Yesterday',
      _JournalDatePreset.last7Days => 'Last 7 days',
      _JournalDatePreset.custom => _formatDateRange(_startDate, _endDate),
    };
  }

  String get _emptyStateMessage {
    return switch (_datePreset) {
      _JournalDatePreset.today => 'No inventory activity for today.',
      _JournalDatePreset.yesterday => 'No inventory activity for yesterday.',
      _JournalDatePreset.last7Days =>
        'No inventory activity in the last 7 days.',
      _JournalDatePreset.custom =>
        'No inventory activity for ${_formatDateRange(_startDate, _endDate)}.',
    };
  }

  List<_FilterStatusItem> _filterStatusItems({
    required String selectedItemLabel,
    required String selectedStockItemId,
    required String selectedBranchId,
    required List<MapEntry<String, String>> branchOptions,
  }) {
    return <_FilterStatusItem>[
      _FilterStatusItem(
        label: 'Item',
        value: selectedStockItemId.isNotEmpty ? selectedItemLabel : 'All items',
        isEmphasized: selectedStockItemId.isNotEmpty,
      ),
      _FilterStatusItem(label: 'Date', value: _dateLabel),
      if (selectedBranchId != 'all')
        _FilterStatusItem(
          label: 'Branch',
          value: _branchLabel(branchOptions, selectedBranchId),
        )
      else
        const _FilterStatusItem(label: 'Branch', value: 'All branches'),
      if (_selectedReasonFilter != null)
        _FilterStatusItem(
          label: 'Movement',
          value: _selectedReasonFilter!.label,
        )
      else
        const _FilterStatusItem(label: 'Movement', value: 'All types'),
    ];
  }

  String _selectedItemLabel({
    required List<InventoryJournalEntry> entries,
    required List<StockItem> stockItems,
    required String selectedStockItemId,
  }) {
    if (selectedStockItemId.isEmpty) {
      return 'selected stock item';
    }
    for (final item in stockItems) {
      if (item.id != selectedStockItemId) continue;
      final name = item.name.trim();
      if (name.isNotEmpty) return name;
    }
    for (final entry in entries) {
      if (entry.itemId != selectedStockItemId) continue;
      final name = entry.itemName.trim();
      if (name.isNotEmpty) return name;
    }
    return 'selected stock item';
  }

  Future<void> _reloadCurrentQuery() async {
    final journalState = ref.read(inventoryJournalControllerProvider);
    await _loadJournal(
      branchId: journalState.selectedBranchId,
      stockItemId: journalState.selectedStockItemId,
      reasonFilter: _selectedReasonFilter,
    );
  }

  Future<void> _openFilterModal(
    BuildContext context, {
    required List<MapEntry<String, String>> branchOptions,
    required List<StockItem> stockItems,
    required String selectedBranchId,
    required String selectedItemId,
    required String selectedItemName,
  }) async {
    final draft = await _showFilterModal(
      context,
      branchOptions: branchOptions,
      stockItems: stockItems,
      initialDraft: _JournalFilterDraft(
        branchId: selectedBranchId,
        stockItemId: selectedItemId,
        stockItemName: selectedItemId.isEmpty ? '' : selectedItemName,
        reasonFilter: _selectedReasonFilter,
        datePreset: _datePreset,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
    if (draft == null || !mounted) return;

    setState(() {
      _selectedReasonFilter = draft.reasonFilter;
      _datePreset = draft.datePreset;
      _startDate = draft.startDate;
      _endDate = draft.endDate;
    });

    await _loadJournal(
      branchId: draft.branchId,
      stockItemId: draft.stockItemId.isEmpty ? null : draft.stockItemId,
      reasonFilter: draft.reasonFilter,
    );
  }

  Future<_JournalFilterDraft?> _showFilterModal(
    BuildContext context, {
    required List<MapEntry<String, String>> branchOptions,
    required List<StockItem> stockItems,
    required _JournalFilterDraft initialDraft,
  }) {
    final isSmallScreen = AppBreakpoints.isSmall(
      MediaQuery.sizeOf(context).width,
    );
    if (isSmallScreen) {
      return _showMobileFullscreenModal<_JournalFilterDraft>(
        context,
        child: _JournalFilterSheet(
          branchOptions: branchOptions,
          stockItems: stockItems,
          initialDraft: initialDraft,
        ),
      );
    }

    return showDialog<_JournalFilterDraft>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _JournalFilterSheet(
              branchOptions: branchOptions,
              stockItems: stockItems,
              initialDraft: initialDraft,
            ),
          ),
        ),
      ),
    );
  }

  Future<T?> _showMobileFullscreenModal<T>(
    BuildContext context, {
    required Widget child,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        fullscreenDialog: true,
        builder: (context) => _JournalMobileModalScaffold(child: child),
      ),
    );
  }

  Future<void> _loadJournal({
    required String branchId,
    String? stockItemId,
    required InventoryJournalReasonFilter? reasonFilter,
  }) {
    return ref
        .read(inventoryJournalControllerProvider.notifier)
        .load(
          branchId: branchId == 'all' ? null : branchId,
          stockItemId: (stockItemId == null || stockItemId.isEmpty)
              ? null
              : stockItemId,
          reason: inventoryJournalReasonFilterToDomainReason(reasonFilter),
          limit: _pageSize,
        );
  }

  Future<void> _loadMore() {
    final journalState = ref.read(inventoryJournalControllerProvider);
    return ref
        .read(inventoryJournalControllerProvider.notifier)
        .loadMore(
          branchId: journalState.selectedBranchId == 'all'
              ? null
              : journalState.selectedBranchId,
          stockItemId: journalState.selectedStockItemId.isEmpty
              ? null
              : journalState.selectedStockItemId,
          reason: inventoryJournalReasonFilterToDomainReason(
            _selectedReasonFilter,
          ),
        );
  }

  List<MapEntry<String, String>> _branchOptions(
    List<InventoryJournalEntry> entries, {
    List<BranchListItem> tenantBranches = const <BranchListItem>[],
    List<UserBranch> userBranches = const <UserBranch>[],
  }) {
    final map = <String, String>{};
    if (tenantBranches.isNotEmpty) {
      for (final branch in tenantBranches) {
        final id = branch.branchId.trim();
        if (id.isEmpty) continue;
        final name = branch.branchName.trim().isNotEmpty
            ? branch.branchName.trim()
            : id;
        map[id] = name;
      }
    } else {
      for (final branch in userBranches) {
        final id = (branch.branchId.isNotEmpty ? branch.branchId : branch.id)
            .trim();
        if (id.isEmpty) continue;
        final name = branch.name.trim().isNotEmpty ? branch.name.trim() : id;
        map[id] = name;
      }
    }
    for (final entry in entries) {
      final id = entry.branchId.trim();
      if (id.isEmpty) continue;
      final entryName = entry.branchName.trim();
      if (entryName.isNotEmpty || !map.containsKey(id)) {
        map[id] = entryName.isNotEmpty ? entryName : id;
      }
    }

    final options = map.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return [const MapEntry('all', 'All branches'), ...options];
  }

  List<InventoryJournalEntry> _filteredEntries(
    List<InventoryJournalEntry> entries,
  ) {
    return entries
        .where((entry) {
          if (entry.occurredAt.isBefore(_startDate)) return false;
          if (entry.occurredAt.isAfter(_endDate)) return false;
          return true;
        })
        .toList(growable: false);
  }

  List<_JournalDateGroup> _groupByDate(List<InventoryJournalEntry> entries) {
    final grouped = <DateTime, List<InventoryJournalEntry>>{};
    for (final entry in entries) {
      final dateKey = DateTime(
        entry.occurredAt.year,
        entry.occurredAt.month,
        entry.occurredAt.day,
      );
      grouped.putIfAbsent(dateKey, () => <InventoryJournalEntry>[]).add(entry);
    }

    final groups =
        grouped.entries
            .map(
              (entry) => _JournalDateGroup(
                date: entry.key,
                entries: [...entry.value]
                  ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt)),
              ),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return groups;
  }

  String _branchLabel(
    List<MapEntry<String, String>> branchOptions,
    String branchId,
  ) {
    for (final option in branchOptions) {
      if (option.key == branchId) {
        return option.value;
      }
    }
    return branchId;
  }
}

class _JournalPageHeader extends StatelessWidget {
  const _JournalPageHeader({
    required this.filterStatusItems,
    required this.hasFiltersApplied,
    required this.onFilterPressed,
  });

  final List<_FilterStatusItem> filterStatusItems;
  final bool hasFiltersApplied;
  final VoidCallback onFilterPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
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
              _FilterActionButton(
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
              for (final item in filterStatusItems) _FilterInfoCard(item: item),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterInfoCard extends StatelessWidget {
  const _FilterInfoCard({required this.item});

  final _FilterStatusItem item;

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

class _FilterActionButton extends StatelessWidget {
  const _FilterActionButton({
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
          const Positioned(top: 4, right: 4, child: _FilterAppliedDot()),
      ],
    );
  }
}

class _FilterStatusItem {
  const _FilterStatusItem({
    required this.label,
    required this.value,
    this.isEmphasized = false,
  });

  final String label;
  final String value;
  final bool isEmphasized;
}

class _FilterAppliedDot extends StatelessWidget {
  const _FilterAppliedDot();

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

class _JournalMobileModalScaffold extends StatelessWidget {
  const _JournalMobileModalScaffold({required this.child});

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
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            top: 8,
            right: 16,
            bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SelectionBanner extends StatelessWidget {
  const _SelectionBanner({
    required this.text,
    required this.actionLabel,
    required this.onPressed,
    this.isError = false,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onPressed;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = isError ? colorScheme.error : colorScheme.primary;
    final backgroundColor = isError
        ? colorScheme.errorContainer.withValues(alpha: 0.45)
        : colorScheme.primary.withValues(alpha: 0.08);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
          TextButton(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _JournalInitialError extends StatelessWidget {
  const _JournalInitialError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _JournalEmptyState extends StatelessWidget {
  const _JournalEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try expanding the date range.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalDesktopTable extends StatelessWidget {
  const _JournalDesktopTable({
    required this.groups,
    required this.hideItemColumn,
    required this.hideBranchColumn,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  final List<_JournalDateGroup> groups;
  final bool hideItemColumn;
  final bool hideBranchColumn;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTableTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTableTheme.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: ColoredBox(
                color: AppTableTheme.background,
                child: Column(
                  children: [
                    _DesktopTableHeader(
                      hideItemColumn: hideItemColumn,
                      hideBranchColumn: hideBranchColumn,
                    ),
                    for (final group in groups) ...[
                      _DateDividerRow(date: group.date),
                      for (final entry in group.entries)
                        _DesktopEntryRow(
                          entry: entry,
                          hideItemColumn: hideItemColumn,
                          hideBranchColumn: hideBranchColumn,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasMore) ...[
          const SizedBox(height: 16),
          Center(
            child: isLoadingMore
                ? const CircularProgressIndicator()
                : OutlinedButton(
                    onPressed: onLoadMore,
                    child: const Text('Load more'),
                  ),
          ),
        ],
      ],
    );
  }
}

class _DesktopTableHeader extends StatelessWidget {
  const _DesktopTableHeader({
    required this.hideItemColumn,
    required this.hideBranchColumn,
  });

  final bool hideItemColumn;
  final bool hideBranchColumn;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTableTheme.headerBackground,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          const Expanded(
            flex: 2,
            child: Text('Time', style: AppTableTheme.headerText),
          ),
          if (!hideItemColumn)
            const Expanded(
              flex: 3,
              child: Text('Item', style: AppTableTheme.headerText),
            ),
          if (!hideBranchColumn)
            const Expanded(
              flex: 3,
              child: Text('Branch', style: AppTableTheme.headerText),
            ),
          const Expanded(
            flex: 3,
            child: Text('Movement', style: AppTableTheme.headerText),
          ),
          const Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('Quantity', style: AppTableTheme.headerText),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateDividerRow extends StatelessWidget {
  const _DateDividerRow({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTableTheme.divider)),
      ),
      child: Text(
        DateFormat('MMM d, y').format(date),
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DesktopEntryRow extends StatelessWidget {
  const _DesktopEntryRow({
    required this.entry,
    required this.hideItemColumn,
    required this.hideBranchColumn,
  });

  final InventoryJournalEntry entry;
  final bool hideItemColumn;
  final bool hideBranchColumn;

  @override
  Widget build(BuildContext context) {
    final quantityStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: _deltaColor(entry.delta),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTableTheme.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('HH:mm').format(entry.occurredAt.toLocal()),
              style: AppTableTheme.cellText,
            ),
          ),
          if (!hideItemColumn)
            Expanded(
              flex: 3,
              child: Text(entry.itemName, style: AppTableTheme.cellText),
            ),
          if (!hideBranchColumn)
            Expanded(
              flex: 3,
              child: Text(entry.branchName, style: AppTableTheme.cellText),
            ),
          Expanded(
            flex: 3,
            child: Text(
              _movementTypeLabel(entry),
              style: AppTableTheme.cellText,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(_formatDelta(entry.delta), style: quantityStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalMobileList extends StatelessWidget {
  const _JournalMobileList({
    required this.groups,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  final List<_JournalDateGroup> groups;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: groups.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index >= groups.length) {
          return Center(
            child: isLoadingMore
                ? const CircularProgressIndicator()
                : OutlinedButton(
                    onPressed: onLoadMore,
                    child: const Text('Load more'),
                  ),
          );
        }

        final group = groups[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM d').format(group.date),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < group.entries.length; i++) ...[
              _JournalMobileCard(entry: group.entries[i]),
              if (i < group.entries.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _JournalMobileCard extends StatelessWidget {
  const _JournalMobileCard({required this.entry});

  final InventoryJournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final quantityStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: _deltaColor(entry.delta),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTableTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.itemName,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  _movementTypeLabel(entry),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(_formatDelta(entry.delta), style: quantityStyle),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${entry.branchName} • ${DateFormat('HH:mm').format(entry.occurredAt.toLocal())}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF666666)),
          ),
        ],
      ),
    );
  }
}

class _JournalFilterSheet extends StatefulWidget {
  const _JournalFilterSheet({
    required this.branchOptions,
    required this.stockItems,
    required this.initialDraft,
  });

  final List<MapEntry<String, String>> branchOptions;
  final List<StockItem> stockItems;
  final _JournalFilterDraft initialDraft;

  @override
  State<_JournalFilterSheet> createState() => _JournalFilterSheetState();
}

class _JournalFilterSheetState extends State<_JournalFilterSheet> {
  late String _branchId;
  late String _stockItemId;
  late String _stockItemName;
  InventoryJournalReasonFilter? _reasonFilter;
  late _JournalDatePreset _datePreset;
  late DateTime _startDate;
  late DateTime _endDate;
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _branchId = widget.initialDraft.branchId;
    _stockItemId = widget.initialDraft.stockItemId;
    _stockItemName = widget.initialDraft.stockItemName;
    _reasonFilter = widget.initialDraft.reasonFilter;
    _datePreset = widget.initialDraft.datePreset;
    _startDate = widget.initialDraft.startDate;
    _endDate = widget.initialDraft.endDate;
    _startController = TextEditingController(
      text: formatYyyyMmDd(widget.initialDraft.startDate),
    );
    _endController = TextEditingController(
      text: formatYyyyMmDd(widget.initialDraft.endDate),
    );
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = AppBreakpoints.isSmall(
      MediaQuery.sizeOf(context).width,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Filter journal',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (!isSmallScreen)
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Date range',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in _JournalDatePreset.values)
                ChoiceChip(
                  label: Text(_presetLabel(preset)),
                  selected: _datePreset == preset,
                  onSelected: (_) => _handlePresetSelection(preset),
                ),
            ],
          ),
          if (_datePreset == _JournalDatePreset.custom) ...[
            const SizedBox(height: 12),
            if (isSmallScreen) ...[
              InventoryJournalDateField(
                controller: _startController,
                label: 'Start date',
                onTap: () => _pickDate(isStart: true),
                onClear: () => _clearDate(isStart: true),
                allowClear: false,
              ),
              const SizedBox(height: 12),
              InventoryJournalDateField(
                controller: _endController,
                label: 'End date',
                onTap: () => _pickDate(isStart: false),
                onClear: () => _clearDate(isStart: false),
                allowClear: false,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: InventoryJournalDateField(
                      controller: _startController,
                      label: 'Start date',
                      onTap: () => _pickDate(isStart: true),
                      onClear: () => _clearDate(isStart: true),
                      allowClear: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InventoryJournalDateField(
                      controller: _endController,
                      label: 'End date',
                      onTap: () => _pickDate(isStart: false),
                      onClear: () => _clearDate(isStart: false),
                      allowClear: false,
                    ),
                  ),
                ],
              ),
            ],
            if (_validationMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _validationMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Text(
            'Item',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _JournalItemAutocompleteField(
            items: widget.stockItems,
            selectedItemId: _stockItemId,
            initialText: _stockItemName,
            onSelected: (item) {
              setState(() {
                _stockItemId = item.id;
                _stockItemName = item.name;
              });
            },
            onCleared: () {
              setState(() {
                _stockItemId = '';
                _stockItemName = '';
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Branch',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _DialogDropdown<String>(
            value: _branchId,
            entries: widget.branchOptions
                .map(
                  (entry) => DropdownMenuEntry<String>(
                    value: entry.key,
                    label: entry.value,
                  ),
                )
                .toList(growable: false),
            onSelected: (value) => setState(() => _branchId = value ?? 'all'),
          ),
          const SizedBox(height: 16),
          Text(
            'Movement type',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _DialogDropdown<InventoryJournalReasonFilter?>(
            value: _reasonFilter,
            entries: <DropdownMenuEntry<InventoryJournalReasonFilter?>>[
              const DropdownMenuEntry<InventoryJournalReasonFilter?>(
                value: null,
                label: 'All types',
              ),
              ...InventoryJournalReasonFilter.values.map(
                (filter) => DropdownMenuEntry<InventoryJournalReasonFilter?>(
                  value: filter,
                  label: filter.label,
                ),
              ),
            ],
            onSelected: (value) => setState(() => _reasonFilter = value),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetToDefault,
                  child: const Text('Reset'),
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

  void _resetToDefault() {
    final range = _rangeForPreset(_JournalDatePreset.today);
    setState(() {
      _branchId = 'all';
      _stockItemId = '';
      _stockItemName = '';
      _reasonFilter = null;
      _datePreset = _JournalDatePreset.today;
      _startDate = range.start;
      _endDate = range.end;
      _validationMessage = null;
      _syncDateControllers();
    });
  }

  void _handlePresetSelection(_JournalDatePreset preset) {
    if (preset != _JournalDatePreset.custom) {
      final range = _rangeForPreset(preset);
      setState(() {
        _datePreset = preset;
        _startDate = range.start;
        _endDate = range.end;
        _validationMessage = null;
        _syncDateControllers();
      });
      return;
    }
    setState(() {
      _datePreset = _JournalDatePreset.custom;
      _validationMessage = null;
      _syncDateControllers();
    });
  }

  void _apply() {
    if (_datePreset == _JournalDatePreset.custom) {
      final validationMessage = _validateCustomRange(_startDate, _endDate);
      if (validationMessage != null) {
        setState(() => _validationMessage = validationMessage);
        return;
      }
    }
    Navigator.of(context).pop(
      _JournalFilterDraft(
        branchId: _branchId,
        stockItemId: _stockItemId,
        stockItemName: _stockItemName,
        reasonFilter: _reasonFilter,
        datePreset: _datePreset,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  void _clearDate({required bool isStart}) {
    setState(() {
      _validationMessage = null;
      if (isStart) {
        _startDate = _startOfDay(DateTime.now());
      } else {
        _endDate = _endOfDay(DateTime.now());
      }
      _syncDateControllers();
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null || !mounted) return;

    setState(() {
      _validationMessage = null;
      if (isStart) {
        _startDate = _startOfDay(picked);
      } else {
        _endDate = _endOfDay(picked);
      }
      _syncDateControllers();
    });
  }

  void _syncDateControllers() {
    _startController.text = formatYyyyMmDd(_startDate);
    _endController.text = formatYyyyMmDd(_endDate);
  }
}

class _DialogDropdown<T> extends StatelessWidget {
  const _DialogDropdown({
    required this.value,
    required this.entries,
    required this.onSelected,
  });

  final T value;
  final List<DropdownMenuEntry<T>> entries;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxMenuHeight = _filterOverlayMaxHeight(context);
        return DropdownMenu<T>(
          width: constraints.hasBoundedWidth ? constraints.maxWidth : null,
          menuHeight: maxMenuHeight,
          menuStyle: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.white),
            surfaceTintColor: WidgetStatePropertyAll(Colors.white),
          ),
          initialSelection: value,
          dropdownMenuEntries: entries,
          onSelected: onSelected,
        );
      },
    );
  }
}

class _JournalItemAutocompleteField extends StatefulWidget {
  const _JournalItemAutocompleteField({
    required this.items,
    required this.selectedItemId,
    required this.initialText,
    required this.onSelected,
    required this.onCleared,
  });

  final List<StockItem> items;
  final String selectedItemId;
  final String initialText;
  final ValueChanged<StockItem> onSelected;
  final VoidCallback onCleared;

  @override
  State<_JournalItemAutocompleteField> createState() =>
      _JournalItemAutocompleteFieldState();
}

class _JournalItemAutocompleteFieldState
    extends State<_JournalItemAutocompleteField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(covariant _JournalItemAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedItemId != widget.selectedItemId ||
        oldWidget.initialText != widget.initialText) {
      _controller.value = TextEditingValue(
        text: widget.initialText,
        selection: TextSelection.collapsed(offset: widget.initialText.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 320.0;
        final maxMenuHeight = _filterOverlayMaxHeight(context);
        return RawAutocomplete<StockItem>(
          textEditingController: _controller,
          focusNode: _focusNode,
          displayStringForOption: (option) => option.name,
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text.trim().toLowerCase();
            if (query.isEmpty) return widget.items;
            return widget.items.where((item) {
              final name = item.name.toLowerCase();
              final baseUnit = item.baseUnit.toLowerCase();
              return name.contains(query) || baseUnit.contains(query);
            });
          },
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search stock item',
                    suffixIcon: textController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear',
                            onPressed: () {
                              textController.clear();
                              widget.onCleared();
                            },
                          ),
                  ),
                  onTap: () {
                    textController.value = TextEditingValue(
                      text: textController.text,
                      selection: TextSelection.collapsed(
                        offset: textController.text.length,
                      ),
                    );
                  },
                  onChanged: (_) {
                    if (widget.selectedItemId.isNotEmpty) {
                      widget.onCleared();
                    }
                    setState(() {});
                  },
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            final optionList = options.toList(growable: false);
            if (optionList.isEmpty) return const SizedBox.shrink();
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                color: Colors.white,
                surfaceTintColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: fieldWidth,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxMenuHeight),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: optionList.length,
                      itemBuilder: (context, index) {
                        final option = optionList[index];
                        return ListTile(
                          title: Text(option.name),
                          subtitle: Text(option.baseUnit),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
          onSelected: widget.onSelected,
        );
      },
    );
  }
}

class _JournalFilterDraft {
  const _JournalFilterDraft({
    required this.branchId,
    required this.stockItemId,
    required this.stockItemName,
    required this.reasonFilter,
    required this.datePreset,
    required this.startDate,
    required this.endDate,
  });

  final String branchId;
  final String stockItemId;
  final String stockItemName;
  final InventoryJournalReasonFilter? reasonFilter;
  final _JournalDatePreset datePreset;
  final DateTime startDate;
  final DateTime endDate;
}

class _JournalDateGroup {
  const _JournalDateGroup({required this.date, required this.entries});

  final DateTime date;
  final List<InventoryJournalEntry> entries;
}

enum _JournalDatePreset { today, yesterday, last7Days, custom }

class _JournalDateRange {
  const _JournalDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

double _filterOverlayMaxHeight(BuildContext context) {
  final viewportHeight = MediaQuery.sizeOf(context).height;
  return math.min(220, math.max(160, viewportHeight * 0.28)).toDouble();
}

_JournalDateRange _rangeForPreset(_JournalDatePreset preset) {
  final now = DateTime.now();
  return switch (preset) {
    _JournalDatePreset.today => _JournalDateRange(
      start: _startOfDay(now),
      end: _endOfDay(now),
    ),
    _JournalDatePreset.yesterday => _JournalDateRange(
      start: _startOfDay(now.subtract(const Duration(days: 1))),
      end: _endOfDay(now.subtract(const Duration(days: 1))),
    ),
    _JournalDatePreset.last7Days => _JournalDateRange(
      start: _startOfDay(now.subtract(const Duration(days: 6))),
      end: _endOfDay(now),
    ),
    _JournalDatePreset.custom => _JournalDateRange(
      start: _startOfDay(now),
      end: _endOfDay(now),
    ),
  };
}

String _presetLabel(_JournalDatePreset preset) {
  return switch (preset) {
    _JournalDatePreset.today => 'Today',
    _JournalDatePreset.yesterday => 'Yesterday',
    _JournalDatePreset.last7Days => 'Last 7 days',
    _JournalDatePreset.custom => 'Custom',
  };
}

String? _validateCustomRange(DateTime? start, DateTime? end) {
  if (start == null || end == null) {
    return 'Select both start date and end date.';
  }
  if (_startOfDay(start) == _startOfDay(end)) {
    return 'Start date and end date cannot be the same.';
  }
  if (end.isBefore(start)) {
    return 'Start date must be before end date.';
  }
  final inclusiveDays = end.difference(start).inDays + 1;
  if (inclusiveDays > 90) {
    return 'Custom date range cannot exceed 90 days.';
  }
  return null;
}

DateTime _startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _endOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day, 23, 59, 59, 999);

InventoryJournalReasonFilter? _reasonFilterFromDomain(
  InventoryJournalReason? reason,
) {
  return switch (reason) {
    InventoryJournalReason.restock => InventoryJournalReasonFilter.restock,
    InventoryJournalReason.add ||
    InventoryJournalReason.remove => InventoryJournalReasonFilter.adjustment,
    InventoryJournalReason.sale => InventoryJournalReasonFilter.saleDeduction,
    InventoryJournalReason.voided => InventoryJournalReasonFilter.voidReversal,
    InventoryJournalReason.reopen ||
    InventoryJournalReason.unknown => InventoryJournalReasonFilter.other,
    null => null,
  };
}

String _movementTypeLabel(InventoryJournalEntry entry) {
  return switch (entry.reason) {
    InventoryJournalReason.restock => 'RESTOCK',
    InventoryJournalReason.add || InventoryJournalReason.remove => 'ADJUSTMENT',
    InventoryJournalReason.sale => 'SALE_DEDUCTION',
    InventoryJournalReason.voided => 'VOID_REVERSAL',
    InventoryJournalReason.reopen || InventoryJournalReason.unknown => 'OTHER',
  };
}

Color _deltaColor(int delta) {
  if (delta > 0) return const Color(0xFF1E8E5A);
  if (delta < 0) return const Color(0xFFD14343);
  return const Color(0xFF393838);
}

String _formatDelta(int delta) {
  final formatter = NumberFormat.decimalPattern();
  final sign = delta > 0 ? '+' : '';
  return '$sign${formatter.format(delta)}';
}

String _formatDateRange(DateTime start, DateTime end) {
  final startLabel = DateFormat('MMM d').format(start);
  final endLabel = DateFormat('MMM d, y').format(end);
  return '$startLabel - $endLabel';
}
