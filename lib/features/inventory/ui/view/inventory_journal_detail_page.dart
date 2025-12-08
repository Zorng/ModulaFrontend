import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_summary.dart';

class InventoryJournalDetailPage extends ConsumerStatefulWidget {
  const InventoryJournalDetailPage({super.key, required this.summary});

  final InventoryJournalDaySummary summary;

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
            _SearchAutocomplete(
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
                          JournalTile(entry: entries[index]),
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

class _SearchAutocomplete extends StatefulWidget {
  const _SearchAutocomplete({
    required this.initialValue,
    required this.options,
    required this.onChanged,
  });

  final String initialValue;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchAutocomplete> createState() => _SearchAutocompleteState();
}

class _SearchAutocompleteState extends State<_SearchAutocomplete> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _SearchAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.toLowerCase();
        if (query.isEmpty) return const Iterable<String>.empty();
        return widget.options.where(
          (option) => option.toLowerCase().contains(query),
        );
      },
      onSelected: (value) {
        widget.onChanged(value);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        controller.value = _controller.value;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Search stock item or note',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      controller.clear();
                      widget.onChanged('');
                    },
                  )
                : null,
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: widget.onChanged,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class JournalTile extends StatelessWidget {
  const JournalTile({required this.entry, super.key});

  final InventoryJournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final deltaColor = entry.delta >= 0 ? scheme.primary : scheme.error;
    return Card(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    entry.itemName,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTimestamp(entry.occurredAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(_resolvedReason(entry)),
                  backgroundColor: scheme.secondaryContainer,
                  labelStyle: TextStyle(color: scheme.onSecondaryContainer),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.delta > 0 ? '+' : ''}${entry.delta}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: deltaColor),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(entry.note.isEmpty ? '—' : entry.note),
            const SizedBox(height: 4),
            Text(
              'By ${entry.actor}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(
              'Created at ${_formatTimestamp(entry.createdAt)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  String _resolvedReason(InventoryJournalEntry entry) {
    final label = entry.reason.label;
    if (label == 'Other') {
      return entry.delta >= 0 ? 'Add' : 'Remove';
    }
    return label;
  }
}
