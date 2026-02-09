import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_summary.dart';
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
  String _selectedBranchId = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _startCtrl = TextEditingController();
  final TextEditingController _endCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initial load from backend.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryJournalControllerProvider.notifier).load();
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
    final userBranches =
        ref.watch(loginControllerProvider).user?.branches ??
        const <UserBranch>[];
    final entries = ref.watch(inventoryJournalControllerProvider);
    final branchOptions = _branchOptions(entries, userBranches);
    if (_selectedBranchId == 'all' && branchOptions.length == 2) {
      _selectedBranchId = branchOptions.first.key == 'all'
          ? branchOptions[1].key
          : branchOptions.first.key;
    } else if (_selectedBranchId == 'all' && userBranches.length == 1) {
      final first = userBranches.first;
      _selectedBranchId = first.branchId.isNotEmpty ? first.branchId : first.id;
    }
    final filteredEntries = _filteredEntries(entries);
    final branchGroups = _groupByBranch(filteredEntries);

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
                    initialSelection: _selectedBranchId,
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
                      setState(() {
                        _selectedBranchId = branch;
                      });
                      ref
                          .read(inventoryJournalControllerProvider.notifier)
                          .load(branchId: branch == 'all' ? null : branch);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.restart_alt),
                  tooltip: 'Reset filters',
                  onPressed: () {
                    setState(() {
                      _selectedBranchId = 'all';
                      _startDate = null;
                      _endDate = null;
                      _startCtrl.clear();
                      _endCtrl.clear();
                    });
                    ref
                        .read(inventoryJournalControllerProvider.notifier)
                        .load();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
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
              child: branchGroups.isEmpty
                  ? const Center(child: Text('No journal activity yet.'))
                  : ListView.separated(
                      itemCount: branchGroups.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
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
    List<InventoryJournalEntry> entries,
    List<UserBranch> userBranches,
  ) {
    final map = <String, String>{'all': 'All branches'};
    for (final branch in userBranches) {
      final id = branch.branchId.isNotEmpty ? branch.branchId : branch.id;
      map[id] = branch.name;
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
  ) {
    return entries.where((entry) {
      final matchesBranch =
          _selectedBranchId == 'all' || entry.branchId == _selectedBranchId;
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
