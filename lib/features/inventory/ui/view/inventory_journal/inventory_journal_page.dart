import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_summary.dart';
import 'package:modular_pos/features/inventory/ui/models/inventory_journal_reason_filter.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_journal/inventory_journal_models.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_journal/inventory_journal_utils.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_journal/widgets/inventory_journal_branch_section.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_journal/widgets/inventory_journal_date_field.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_journal_controller.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:go_router/go_router.dart';

class InventoryJournalPage extends ConsumerStatefulWidget {
  const InventoryJournalPage({super.key});

  @override
  ConsumerState<InventoryJournalPage> createState() =>
      _InventoryJournalPageState();
}

class _InventoryJournalPageState extends ConsumerState<InventoryJournalPage> {
  static const int _pageSize = 50;
  InventoryJournalReasonFilter? _selectedReasonFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _startCtrl = TextEditingController();
  final TextEditingController _endCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(branchControllerProvider.notifier).loadInitial();
      final current = ref.read(inventoryJournalControllerProvider);
      if (current.entries.isNotEmpty ||
          current.selectedStockItemId.isNotEmpty ||
          current.selectedBranchId != 'all') {
        return;
      }
      ref
          .read(inventoryJournalControllerProvider.notifier)
          .load(limit: _pageSize);
    });
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    final journalState = ref.watch(inventoryJournalControllerProvider);
    final entries = journalState.entries;
    final selectedBranchId = journalState.selectedBranchId;
    final selectedStockItemId = journalState.selectedStockItemId;
    final branchOptions = _branchOptions(
      entries,
      tenantBranches: tenantBranches,
      userBranches: loginState.user?.branches ?? const <UserBranch>[],
    );
    final filteredEntries = _filteredEntries(entries, selectedBranchId);
    final branchGroups = _groupByBranch(filteredEntries);
    final selectedItemLabel = selectedStockItemId.isEmpty
        ? null
        : entries
                  .where((entry) => entry.itemId == selectedStockItemId)
                  .map((entry) => entry.itemName)
                  .where((name) => name.trim().isNotEmpty)
                  .cast<String?>()
                  .firstWhere((name) => name != null, orElse: () => null) ??
              'selected stock item';

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownMenu<String>(
                    initialSelection: selectedBranchId,
                    label: const Text('Branch'),
                    dropdownMenuEntries: branchOptions
                        .map(
                          (entry) => DropdownMenuEntry(
                            value: entry.key,
                            label: entry.value,
                          ),
                        )
                        .toList(),
                    onSelected: (value) {
                      final branch = value ?? 'all';
                      ref
                          .read(inventoryJournalControllerProvider.notifier)
                          .load(
                            branchId: branch == 'all' ? null : branch,
                            reason: inventoryJournalReasonFilterToDomainReason(
                              _selectedReasonFilter,
                            ),
                            limit: _pageSize,
                          );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownMenu<InventoryJournalReasonFilter?>(
                    initialSelection: _selectedReasonFilter,
                    label: const Text('Reason'),
                    dropdownMenuEntries:
                        <DropdownMenuEntry<InventoryJournalReasonFilter?>>[
                          const DropdownMenuEntry<
                            InventoryJournalReasonFilter?
                          >(value: null, label: 'All reasons'),
                          ...InventoryJournalReasonFilter.values.map(
                            (filter) =>
                                DropdownMenuEntry<
                                  InventoryJournalReasonFilter?
                                >(value: filter, label: filter.label),
                          ),
                        ],
                    onSelected: (value) {
                      setState(() {
                        _selectedReasonFilter = value;
                      });
                      ref
                          .read(inventoryJournalControllerProvider.notifier)
                          .load(
                            branchId: selectedBranchId == 'all'
                                ? null
                                : selectedBranchId,
                            reason: inventoryJournalReasonFilterToDomainReason(
                              value,
                            ),
                            limit: _pageSize,
                          );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.restart_alt),
                  tooltip: 'Reset filters',
                  onPressed: () {
                    setState(() {
                      _selectedReasonFilter = null;
                      _startDate = null;
                      _endDate = null;
                      _startCtrl.clear();
                      _endCtrl.clear();
                    });
                    ref
                        .read(inventoryJournalControllerProvider.notifier)
                        .load(limit: _pageSize);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (selectedStockItemId.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Showing history for $selectedItemLabel.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(inventoryJournalControllerProvider.notifier)
                            .load(
                              branchId: selectedBranchId == 'all'
                                  ? null
                                  : selectedBranchId,
                              reason:
                                  inventoryJournalReasonFilterToDomainReason(
                                    _selectedReasonFilter,
                                  ),
                              limit: _pageSize,
                            );
                      },
                      child: const Text('Clear item filter'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            InventoryJournalDateField(
              controller: _startCtrl,
              label: 'Start date',
              onTap: () => _pickDate(isStart: true),
              onClear: () => setState(() {
                _startDate = null;
                _startCtrl.clear();
              }),
            ),
            const SizedBox(height: 12),
            InventoryJournalDateField(
              controller: _endCtrl,
              label: 'End date',
              onTap: () => _pickDate(isStart: false),
              onClear: () => setState(() {
                _endDate = null;
                _endCtrl.clear();
              }),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: journalState.isLoading && entries.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : journalState.error != null && entries.isEmpty
                  ? Center(child: Text(journalState.error!))
                  : branchGroups.isEmpty
                  ? const Center(child: Text('No journal activity yet.'))
                  : ListView.separated(
                      itemCount:
                          branchGroups.length + (journalState.hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        if (index >= branchGroups.length) {
                          if (journalState.isLoadingMore) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return Center(
                            child: OutlinedButton(
                              onPressed: () {
                                ref
                                    .read(
                                      inventoryJournalControllerProvider
                                          .notifier,
                                    )
                                    .loadMore(
                                      branchId: selectedBranchId == 'all'
                                          ? null
                                          : selectedBranchId,
                                      reason:
                                          inventoryJournalReasonFilterToDomainReason(
                                            _selectedReasonFilter,
                                          ),
                                    );
                              },
                              child: const Text('Load more'),
                            ),
                          );
                        }
                        final group = branchGroups[index];
                        return InventoryJournalBranchSection(
                          group: group,
                          onOpenSummary: (summary) => context.push(
                            AppRoute.inventoryJournalDetail.path,
                            extra: summary,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<MapEntry<String, String>> _branchOptions(
    List<InventoryJournalEntry> entries, {
    List<BranchListItem> tenantBranches = const <BranchListItem>[],
    List<UserBranch> userBranches = const <UserBranch>[],
  }) {
    final map = <String, String>{'all': 'All branches'};
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
      if (entry.branchId.isNotEmpty) {
        map[entry.branchId] = entry.branchName;
      }
    }
    return map.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
  }

  List<InventoryJournalEntry> _filteredEntries(
    List<InventoryJournalEntry> entries,
    String selectedBranchId,
  ) {
    return entries.where((entry) {
      final matchesBranch =
          selectedBranchId == 'all' || entry.branchId == selectedBranchId;
      final matchesStart =
          _startDate == null || !entry.occurredAt.isBefore(_startDate!);
      final matchesEnd =
          _endDate == null ||
          !entry.occurredAt.isAfter(
            _endDate!
                .add(const Duration(days: 1))
                .subtract(const Duration(seconds: 1)),
          );
      return matchesBranch && matchesStart && matchesEnd;
    }).toList();
  }

  List<InventoryJournalBranchGroup> _groupByBranch(
    List<InventoryJournalEntry> entries,
  ) {
    final byBranch = <String, List<InventoryJournalEntry>>{};
    final branchNames = <String, String>{};
    for (final entry in entries) {
      byBranch.putIfAbsent(entry.branchId, () => []).add(entry);
      branchNames[entry.branchId] = entry.branchName;
    }

    final groups =
        byBranch.entries
            .map(
              (e) => InventoryJournalBranchGroup(
                branchId: e.key,
                branchName: branchNames[e.key] ?? 'Branch',
                summaries: _summariesFor(e.value),
              ),
            )
            .where((group) => group.summaries.isNotEmpty)
            .toList()
          ..sort((a, b) => a.branchName.compareTo(b.branchName));
    return groups;
  }

  List<InventoryJournalDaySummary> _summariesFor(
    List<InventoryJournalEntry> entries,
  ) {
    final Map<DateTime, List<InventoryJournalEntry>> grouped = {};
    for (final entry in entries) {
      final dayKey = DateTime(
        entry.occurredAt.year,
        entry.occurredAt.month,
        entry.occurredAt.day,
      );
      grouped.putIfAbsent(dayKey, () => []).add(entry);
    }
    final summaries = grouped.entries.map((e) {
      final uniqueItems = e.value.map((entry) => entry.itemName).toSet().length;
      final sortedEntries = [...e.value]
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      return InventoryJournalDaySummary(
        date: e.key,
        itemCount: uniqueItems,
        activityCount: sortedEntries.length,
        entries: sortedEntries,
      );
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
    return summaries;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? _startDate ?? now : _endDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        _startCtrl.text = _formatDate(picked);
      } else {
        _endDate = picked;
        _endCtrl.text = _formatDate(picked);
      }
    });
  }

  String _formatDate(DateTime date) => formatYyyyMmDd(date);
}
