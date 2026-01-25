import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_summary.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_journal_detail/widgets/inventory_journal_entry_card.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_journal_detail/widgets/inventory_journal_search_autocomplete.dart';

class InventoryJournalDetailPage extends ConsumerStatefulWidget {
  const InventoryJournalDetailPage({
    super.key,
    required this.summary,
    this.showBack = true,
  });

  final InventoryJournalDaySummary summary;
  final bool showBack;

  @override
  ConsumerState<InventoryJournalDetailPage> createState() =>
      _InventoryJournalDetailPageState();
}

class _InventoryJournalDetailPageState
    extends ConsumerState<InventoryJournalDetailPage> {
  late List<InventoryJournalEntry> _entries;
  String? _searchQuery;
  final Set<InventoryJournalReason> _selectedReasons = {};

  @override
  void initState() {
    super.initState();
    _entries = widget.summary.entries;
    _hydrateNames();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBack,
        leading: widget.showBack
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        title: Text('Journal on ${_summaryDate(widget.summary.date)}'),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.summary.entries.isNotEmpty
                  ? 'Branch: ${widget.summary.entries.first.branchName}'
                  : 'Branch',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
            const SizedBox(height: 8),
            InventoryJournalSearchAutocomplete(
              initialValue: _searchQuery ?? '',
              options: _itemOptions,
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: InventoryJournalReason.values
                  .where((reason) => reason != InventoryJournalReason.unknown)
                  .map(
                    (reason) => FilterChip(
                      label: Text(reason.label),
                      selected: _selectedReasons.contains(reason),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedReasons.add(reason);
                          } else {
                            _selectedReasons.remove(reason);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Text('No matching transactions.'))
                  : ListView.separated(
                      itemBuilder: (context, index) =>
                          InventoryJournalEntryCard(entry: entries[index]),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: entries.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<InventoryJournalEntry> _filteredEntries() {
    final query = (_searchQuery ?? '').trim().toLowerCase();
    return _entries.where((entry) {
      final matchesQuery =
          query.isEmpty ||
          entry.itemName.toLowerCase().contains(query) ||
          entry.note.toLowerCase().contains(query);
      final matchesReason =
          _selectedReasons.isEmpty || _selectedReasons.contains(entry.reason);
      return matchesQuery && matchesReason;
    }).toList();
  }

  String _summaryDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  List<String> get _itemOptions =>
      _entries.map((entry) => entry.itemName).toSet().toList()..sort();

  Future<void> _hydrateNames() async {
    // Only hydrate if any entry has a placeholder name.
    final needsHydrate = _entries.any((e) {
      final name = e.itemName.trim();
      return name.isEmpty || name.toLowerCase() == 'item';
    });
    if (!needsHydrate) return;

    final repo = ref.read(stockItemRepositoryProvider);
    final items = await repo.fetchMasterStockItems();
    final lookup = {for (final item in items) item.id: item.name};
    setState(() {
      _entries = _entries
          .map(
            (e) => (e.itemName.trim().isEmpty ||
                    e.itemName.trim().toLowerCase() == 'item')
                ? e.copyWith(itemName: lookup[e.itemId] ?? e.itemName)
                : e,
          )
          .toList();
    });
  }
}
