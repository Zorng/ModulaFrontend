import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:modular_pos/core/theme/app_theme.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/layout/app_pagination_bar.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/models/inventory_journal_date_filter.dart';
import 'package:modular_pos/features/inventory/ui/models/inventory_journal_reason_filter.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_journal/inventory_journal_utils.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_journal/widgets/inventory_journal_date_field.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_journal_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_journal_state.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';

part 'widgets/inventory_journal_header.dart';
part 'widgets/inventory_journal_feedback.dart';
part 'widgets/inventory_journal_table.dart';
part 'widgets/inventory_journal_mobile_list.dart';
part 'widgets/inventory_journal_filter_sheet.dart';

class InventoryJournalPage extends ConsumerStatefulWidget {
  const InventoryJournalPage({super.key});

  @override
  ConsumerState<InventoryJournalPage> createState() =>
      _InventoryJournalPageState();
}

class _InventoryJournalPageState extends ConsumerState<InventoryJournalPage> {
  static const int _pageSize = 10;

  InventoryJournalReasonFilter? _selectedReasonFilter;
  InventoryJournalDatePreset _datePreset = InventoryJournalDatePreset.today;
  late DateTime _startDate;
  late DateTime _endDate;
  bool? _lastIsSmallScreen;

  @override
  void initState() {
    super.initState();
    final current = ref.read(inventoryJournalControllerProvider);
    _selectedReasonFilter = _reasonFilterFromDomain(current.selectedReason);
    final resolvedDateFilter = resolveInventoryJournalDateFilter(
      current.dateFilter,
    );
    final initialRange = _rangeFromDateFilter(resolvedDateFilter);
    _datePreset = resolvedDateFilter.preset;
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
          state.selectedReason != null ||
          state.dateFilter.preset != InventoryJournalDatePreset.today) {
        return;
      }
      ref
          .read(inventoryJournalControllerProvider.notifier)
          .load(
            limit: _pageSize,
            dateFilter: _currentDateFilter(),
            accumulatePages: _usesLazyLoading,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isSmallScreen = AppBreakpoints.isSmall(width);
    _syncLayoutMode(isSmallScreen);
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
    final baseUnitLookup = {
      for (final item in stockItems)
        if (item.id.trim().isNotEmpty && item.baseUnit.trim().isNotEmpty)
          item.id: item.baseUnit.trim(),
    };
    final branchOptions = _branchOptions(
      entries,
      tenantBranches: tenantBranches,
      userBranches: loginState.user?.branches ?? const <UserBranch>[],
    );
    final filteredEntries = _entriesWithBranchLabels(entries, branchOptions);
    final dateGroups = _groupByDate(filteredEntries);
    final rangeLabel = _journalRangeLabel(journalState);
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
        _datePreset != InventoryJournalDatePreset.today;

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
                      baseUnitLookup: baseUnitLookup,
                      hasNextPage: journalState.hasNextPage,
                      isLoadingMore: journalState.isPageLoading,
                      onLoadMore: _loadNextChunk,
                    )
                  : _JournalDesktopTable(
                      groups: dateGroups,
                      baseUnitLookup: baseUnitLookup,
                      hideItemColumn:
                          journalState.selectedStockItemId.isNotEmpty,
                      hideBranchColumn: journalState.selectedBranchId != 'all',
                      rangeLabel: rangeLabel,
                      hasPreviousPage: journalState.hasPreviousPage,
                      hasNextPage: journalState.hasNextPage,
                      isPageLoading: journalState.isPageLoading,
                      onPreviousPage: _goToPreviousPage,
                      onNextPage: _goToNextPage,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String get _dateLabel {
    return switch (_datePreset) {
      InventoryJournalDatePreset.today => 'Today',
      InventoryJournalDatePreset.yesterday => 'Yesterday',
      InventoryJournalDatePreset.last7Days => 'Last 7 days',
      InventoryJournalDatePreset.custom => _formatDateRange(
        _startDate,
        _endDate,
      ),
    };
  }

  String get _emptyStateMessage {
    return switch (_datePreset) {
      InventoryJournalDatePreset.today => 'No inventory activity for today.',
      InventoryJournalDatePreset.yesterday =>
        'No inventory activity for yesterday.',
      InventoryJournalDatePreset.last7Days =>
        'No inventory activity in the last 7 days.',
      InventoryJournalDatePreset.custom =>
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
          dateFilter: _currentDateFilter(),
          limit: _pageSize,
          accumulatePages: _usesLazyLoading,
        );
  }

  Future<void> _loadNextChunk() {
    final journalState = ref.read(inventoryJournalControllerProvider);
    return ref
        .read(inventoryJournalControllerProvider.notifier)
        .loadNextChunk(
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

  Future<void> _goToNextPage() {
    final journalState = ref.read(inventoryJournalControllerProvider);
    return ref
        .read(inventoryJournalControllerProvider.notifier)
        .goToNextPage(
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

  Future<void> _goToPreviousPage() {
    final journalState = ref.read(inventoryJournalControllerProvider);
    return ref
        .read(inventoryJournalControllerProvider.notifier)
        .goToPreviousPage(
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

  String _journalRangeLabel(InventoryJournalState journalState) {
    if (journalState.entries.isEmpty) {
      return 'Showing 0 entries';
    }
    return 'Showing ${journalState.visibleRangeStart}-${journalState.visibleRangeEnd} entries';
  }

  bool get _usesLazyLoading =>
      AppBreakpoints.isSmall(MediaQuery.sizeOf(context).width);

  void _syncLayoutMode(bool isSmallScreen) {
    if (_lastIsSmallScreen == null) {
      _lastIsSmallScreen = isSmallScreen;
      return;
    }
    if (_lastIsSmallScreen == isSmallScreen) return;
    _lastIsSmallScreen = isSmallScreen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reloadCurrentQuery();
    });
  }

  List<InventoryJournalEntry> _entriesWithBranchLabels(
    List<InventoryJournalEntry> entries,
    List<MapEntry<String, String>> branchOptions,
  ) {
    return entries
        .map((entry) {
          if (entry.branchName.trim().isNotEmpty) return entry;
          final branchId = entry.branchId.trim();
          if (branchId.isEmpty || branchId == 'all') return entry;
          return entry.copyWith(
            branchName: _branchLabel(branchOptions, branchId),
          );
        })
        .toList(growable: false);
  }

  List<_JournalDateGroup> _groupByDate(List<InventoryJournalEntry> entries) {
    final grouped = <DateTime, List<InventoryJournalEntry>>{};
    for (final entry in entries) {
      final cambodiaOccurredAt = _journalCambodiaDateTime(entry.occurredAt);
      final dateKey = DateTime(
        cambodiaOccurredAt.year,
        cambodiaOccurredAt.month,
        cambodiaOccurredAt.day,
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

  InventoryJournalDateFilter _currentDateFilter() {
    return resolveInventoryJournalDateFilter(
      InventoryJournalDateFilter(
        preset: _datePreset,
        from: _datePreset == InventoryJournalDatePreset.custom
            ? _startDate
            : null,
        to: _datePreset == InventoryJournalDatePreset.custom ? _endDate : null,
      ),
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
  final InventoryJournalDatePreset datePreset;
  final DateTime startDate;
  final DateTime endDate;
}

class _JournalDateGroup {
  const _JournalDateGroup({required this.date, required this.entries});

  final DateTime date;
  final List<InventoryJournalEntry> entries;
}

class _JournalDateRange {
  const _JournalDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

double _filterOverlayMaxHeight(BuildContext context) {
  final viewportHeight = MediaQuery.sizeOf(context).height;
  return math.min(220, math.max(160, viewportHeight * 0.28)).toDouble();
}

_JournalDateRange _rangeForPreset(InventoryJournalDatePreset preset) {
  final now = DateTime.now();
  return switch (preset) {
    InventoryJournalDatePreset.today => _JournalDateRange(
      start: _startOfDay(now),
      end: _endOfDay(now),
    ),
    InventoryJournalDatePreset.yesterday => _JournalDateRange(
      start: _startOfDay(now.subtract(const Duration(days: 1))),
      end: _endOfDay(now.subtract(const Duration(days: 1))),
    ),
    InventoryJournalDatePreset.last7Days => _JournalDateRange(
      start: _startOfDay(now.subtract(const Duration(days: 6))),
      end: _endOfDay(now),
    ),
    InventoryJournalDatePreset.custom => _JournalDateRange(
      start: _startOfDay(now),
      end: _endOfDay(now),
    ),
  };
}

_JournalDateRange _rangeFromDateFilter(InventoryJournalDateFilter filter) {
  final resolved = resolveInventoryJournalDateFilter(filter);
  return switch (resolved.preset) {
    InventoryJournalDatePreset.today ||
    InventoryJournalDatePreset.yesterday => _JournalDateRange(
      start: _startOfDay(resolved.date!),
      end: _endOfDay(resolved.date!),
    ),
    InventoryJournalDatePreset.last7Days ||
    InventoryJournalDatePreset.custom => _JournalDateRange(
      start: _startOfDay(resolved.from!),
      end: _endOfDay(resolved.to!),
    ),
  };
}

String _presetLabel(InventoryJournalDatePreset preset) {
  return switch (preset) {
    InventoryJournalDatePreset.today => 'Today',
    InventoryJournalDatePreset.yesterday => 'Yesterday',
    InventoryJournalDatePreset.last7Days => 'Last 7 days',
    InventoryJournalDatePreset.custom => 'Custom',
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

String _formatDeltaWithUnit(
  InventoryJournalEntry entry,
  Map<String, String> baseUnitLookup,
) {
  final baseUnit = baseUnitLookup[entry.itemId]?.trim() ?? '';
  if (baseUnit.isEmpty) return _formatDelta(entry.delta);
  return '${_formatDelta(entry.delta)} $baseUnit';
}

String _formatDateRange(DateTime start, DateTime end) {
  final startLabel = DateFormat('MMM d').format(start);
  final endLabel = DateFormat('MMM d, y').format(end);
  return '$startLabel - $endLabel';
}

const Duration _journalCambodiaOffset = Duration(hours: 7);

DateTime _journalCambodiaDateTime(DateTime value) {
  final utcValue = value.isUtc ? value : value.toUtc();
  return utcValue.add(_journalCambodiaOffset);
}
