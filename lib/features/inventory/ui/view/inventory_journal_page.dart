import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_summary.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_journal_controller.dart';

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
        ref.watch(loginControllerProvider).user?.branches ?? const <UserBranch>[];
    final entries = ref.watch(inventoryJournalControllerProvider);
    final branchOptions = _branchOptions(entries, userBranches);
    if (_selectedBranchId == 'all' && branchOptions.length == 2) {
      _selectedBranchId = branchOptions.first.key == 'all'
          ? branchOptions[1].key
          : branchOptions.first.key;
    } else if (_selectedBranchId == 'all' && userBranches.length == 1) {
      final first = userBranches.first;
      _selectedBranchId =
          first.branchId.isNotEmpty ? first.branchId : first.id;
    }
    final filteredEntries = _filteredEntries(entries);
    final branchGroups = _groupByBranch(filteredEntries);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory journal'),
        centerTitle: false,
      ),
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
            _DateField(
              controller: _startCtrl,
              label: 'Start date',
              onTap: () => _pickDate(isStart: true),
              onClear: () => setState(() {
                _startDate = null;
                _startCtrl.clear();
              }),
            ),
            const SizedBox(height: 12),
            _DateField(
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
                        return _BranchGroupSection(
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

  List<_BranchGroup> _groupByBranch(List<InventoryJournalEntry> entries) {
    final builders = <String, _BranchGroupBuilder>{};
    for (final entry in entries) {
      builders.putIfAbsent(
        entry.branchId,
        () => _BranchGroupBuilder(entry.branchId, entry.branchName),
      );
      builders[entry.branchId]!.entries.add(entry);
    }
    final groups =
        builders.values
            .map(
              (builder) => _BranchGroup(
                branchId: builder.branchId,
                branchName: builder.branchName,
                summaries: _summariesFor(builder.entries),
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

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _BranchGroupBuilder {
  _BranchGroupBuilder(this.branchId, this.branchName);

  final String branchId;
  final String branchName;
  final List<InventoryJournalEntry> entries = [];
}

class _BranchGroup {
  const _BranchGroup({
    required this.branchId,
    required this.branchName,
    required this.summaries,
  });

  final String branchId;
  final String branchName;
  final List<InventoryJournalDaySummary> summaries;
}

class _BranchGroupSection extends StatelessWidget {
  const _BranchGroupSection({required this.group, required this.onOpenSummary});

  final _BranchGroup group;
  final ValueChanged<InventoryJournalDaySummary> onOpenSummary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(group.branchName, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...group.summaries.map(
          (summary) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: JournalSummaryCard(
              summary: summary,
              onOpen: () => onOpenSummary(summary),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.controller,
    required this.label,
    required this.onTap,
    required this.onClear,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasValue = controller.text.isNotEmpty;
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: hasValue
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
                  IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: onTap,
                  ),
                ],
              )
            : IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: onTap,
              ),
      ),
      onTap: onTap,
    );
  }
}

class JournalSummaryCard extends StatelessWidget {
  const JournalSummaryCard({
    required this.summary,
    required this.onOpen,
    super.key,
  });

  final InventoryJournalDaySummary summary;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          _summaryDate(summary.date),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${summary.itemCount} item${summary.itemCount == 1 ? '' : 's'} modified · '
            '${summary.activityCount} activit${summary.activityCount == 1 ? 'y' : 'ies'}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onOpen,
      ),
    );
  }

  String _summaryDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
