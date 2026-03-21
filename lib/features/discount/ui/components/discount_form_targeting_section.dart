import 'package:flutter/material.dart';
import 'package:modular_pos/features/discount/domain/models/discount_scope.dart';
import 'package:modular_pos/features/discount/ui/components/discount_form_card.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';

class DiscountFormTargetingSection extends StatefulWidget {
  const DiscountFormTargetingSection({
    super.key,
    required this.scope,
    required this.selectedBranchName,
    required this.availableItems,
    required this.selectedItemIds,
    required this.invalidItemIds,
    required this.isReadOnly,
    required this.isLoadingItems,
    required this.itemLoadError,
    required this.onSelectionChanged,
    this.onRetryLoad,
  });

  final String scope;
  final String selectedBranchName;
  final List<MenuItem> availableItems;
  final List<String> selectedItemIds;
  final List<String> invalidItemIds;
  final bool isReadOnly;
  final bool isLoadingItems;
  final String? itemLoadError;
  final ValueChanged<List<String>> onSelectionChanged;
  final VoidCallback? onRetryLoad;

  @override
  State<DiscountFormTargetingSection> createState() =>
      _DiscountFormTargetingSectionState();
}

class _DiscountFormTargetingSectionState
    extends State<DiscountFormTargetingSection> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBranchWide = widget.scope == DiscountScopes.branchWide;
    final searchQuery = _searchController.text.trim().toLowerCase();
    final filteredItems = widget.availableItems
        .where((item) {
          if (searchQuery.isEmpty) return true;
          return item.name.toLowerCase().contains(searchQuery);
        })
        .toList(growable: false);
    final itemLookup = {
      for (final item in widget.availableItems) item.id: item.name,
    };

    return DiscountFormCard(
      title: 'Target items',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBranchWide
                ? 'This rule will apply to the full assigned branch menu.'
                : widget.selectedBranchName.isEmpty
                ? 'Select a branch first, then choose the menu items to target.'
                : 'Search and select the menu items to target in ${widget.selectedBranchName}.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (!isBranchWide) ...[
            const SizedBox(height: 16),
            Text(
              'Search target items',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              enabled: !widget.isReadOnly,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search by item name',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            if (widget.selectedItemIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.selectedItemIds
                    .map((itemId) {
                      final isInvalid = widget.invalidItemIds.contains(itemId);
                      return InputChip(
                        label: Text(itemLookup[itemId] ?? itemId),
                        onDeleted: widget.isReadOnly
                            ? null
                            : () => _toggleSelection(itemId),
                        backgroundColor: isInvalid
                            ? Theme.of(context).colorScheme.errorContainer
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                      );
                    })
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 12),
            if (widget.selectedBranchName.isEmpty)
              Text(
                'Branch assignment is required before item targeting.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else if (widget.isLoadingItems)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if ((widget.itemLoadError ?? '').trim().isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.itemLoadError!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  if (widget.onRetryLoad != null)
                    TextButton(
                      onPressed: widget.onRetryLoad,
                      child: const Text('Retry'),
                    ),
                ],
              )
            else if (widget.availableItems.isEmpty)
              Text(
                'No active menu items found for this branch.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filteredItems.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final isSelected = widget.selectedItemIds.contains(item.id);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: widget.isReadOnly
                          ? null
                          : (_) => _toggleSelection(item.id),
                      title: Text(item.name),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    );
                  },
                ),
              ),
            if (widget.invalidItemIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Invalid items: ${widget.invalidItemIds.join(', ')}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _toggleSelection(String itemId) {
    final next = widget.selectedItemIds.toList(growable: true);
    if (next.contains(itemId)) {
      next.remove(itemId);
    } else {
      next.add(itemId);
    }
    widget.onSelectionChanged(next);
  }
}
