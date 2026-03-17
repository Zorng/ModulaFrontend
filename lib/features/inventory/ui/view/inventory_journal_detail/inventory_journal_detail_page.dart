import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_summary.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/inventory/ui/models/inventory_journal_reason_filter.dart';
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
  final Set<InventoryJournalReasonFilter> _selectedReasonFilters = {};

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
            : const AppBackButton(icon: Icons.close, tooltip: 'Close'),
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
              children: InventoryJournalReasonFilter.values
                  .map(
                    (filter) => FilterChip(
                      label: Text(filter.label),
                      selected: _selectedReasonFilters.contains(filter),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedReasonFilters.add(filter);
                          } else {
                            _selectedReasonFilters.remove(filter);
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
          _selectedReasonFilters.isEmpty ||
          _selectedReasonFilters.any(
            (filter) => inventoryJournalReasonFilterMatchesEntry(filter, entry),
          );
      return matchesQuery && matchesReason;
    }).toList();
  }

  String _summaryDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  List<String> get _itemOptions =>
      _entries.map((entry) => entry.itemName).toSet().toList()..sort();

  Future<void> _hydrateNames() async {
    // Detect if names look like placeholders or IDs and hydrate from repository.
    bool looksLikeId(String name, String id) {
      final n = name.trim();
      if (n.isEmpty) return true;
      if (n.toLowerCase() == 'item') return true;
      if (n == id) return true;
      // Heuristic: no spaces and contains a hyphen or long alphanumeric (likely an id)
      if (!n.contains(' ') && (n.contains('-') || n.length > 12)) return true;
      return false;
    }

    final needsHydrate = _entries.any((e) => looksLikeId(e.itemName, e.itemId));
    if (!needsHydrate) return;

    final repo = ref.read(stockItemRepositoryProvider);
    final fetched = await repo.fetchMasterStockItems();
    final lookup = {for (final item in fetched.items) item.id: item.name};
    setState(() {
      _entries = _entries
          .map(
            (e) => looksLikeId(e.itemName, e.itemId)
                ? e.copyWith(itemName: lookup[e.itemId] ?? e.itemName)
                : e,
          )
          .toList();
    });
  }
}
