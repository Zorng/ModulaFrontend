import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/app_kebab_menu.dart';
import 'package:modular_pos/core/widgets/app_search_add_bar.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_item_card.dart';

class InventoryHomePage extends ConsumerStatefulWidget {
  const InventoryHomePage({super.key});

  @override
  ConsumerState<InventoryHomePage> createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends ConsumerState<InventoryHomePage> {
  String _selectedBranchId = 'all';
  String _selectedBranchName = 'All branches';
  String _selectedCategory = 'All';
  Set<InventoryStockState>? _stateFilters;
  final _searchController = TextEditingController();

  final _branches = const [
    {'id': 'all', 'name': 'All branches'},
    {'id': 'main', 'name': 'Main Branch'},
    {'id': 'downtown', 'name': 'Downtown'},
    {'id': 'airport', 'name': 'Airport'},
  ];
  final _categories = const ['All', 'Dairy', 'Packaging', 'Produce'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(stockInventoryControllerProvider);
    final items = inventoryState.items;
    final activeFilters = _stateFilters ?? const <InventoryStockState>{};
    final filterLabel =
        activeFilters.isEmpty ? 'Filters' : 'Filters (${activeFilters.length})';
    final filtered = items.where((item) {
      final matchesCategory =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchesBranch =
          _selectedBranchId == 'all' || item.branchId == _selectedBranchId;
      final matchesSearch = _searchController.text.isEmpty ||
          item.name.toLowerCase().contains(_searchController.text.toLowerCase());
      final stockState = _mapState(item);
      final matchesState =
          activeFilters.isEmpty || activeFilters.contains(stockState);
      return matchesCategory && matchesBranch && matchesSearch && matchesState;
    }).toList();

    final displayed = _selectedBranchId == 'all'
        ? _aggregateItems(filtered)
        : filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        centerTitle: false,
        actions: [
          AppKebabMenu(
            items: [
              KebabMenuItem(
                label: 'Category management',
                onTap: () => _showComingSoon(context, 'Category management'),
              ),
              KebabMenuItem(
                label: 'Stock item management',
                onTap: () => context.push(AppRoute.inventoryStockItems.path),
              ),
              KebabMenuItem(
                label: 'Inventory journal',
                onTap: () => _showComingSoon(context, 'Inventory journal'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSearchAddBar(
              searchHint: 'Search stock items',
              searchController: _searchController,
              onSearchChanged: (_) => setState(() {}),
              addButtonLabel: 'Restock',
              onAddPressed: () => context.push(AppRoute.inventoryRestock.path),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  final selected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${displayed.length} item${displayed.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _showBranchSelector,
                  icon: const Icon(Icons.store_outlined),
                  label: Text(_selectedBranchName),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _openFilterSheet,
                  icon: const Icon(Icons.filter_list),
                  label: Text(filterLabel),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: inventoryState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : inventoryState.error != null
                        ? Center(
                            child: Text(
                              inventoryState.error!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Theme.of(context).hintColor),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: displayed.length,
                            itemBuilder: (context, index) {
                              final item = displayed[index];
                              return InventoryItemCard(
                                item: item,
                                showState: _selectedBranchId != 'all',
                                onTap: () {
                                  if (item.branchId == 'all') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Select a branch to adjust stock',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  context.push(
                                    AppRoute.inventoryAdjustStock.path,
                                    extra: item,
                                  );
                                },
                              );
                            },
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    final activeFilters = _stateFilters ?? const <InventoryStockState>{};
    final tempStates = {...activeFilters};
    final result = await showModalBottomSheet<Set<InventoryStockState>>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Text(
                    'Stock state',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: InventoryStockState.values.map((state) {
                      final selected = tempStates.contains(state);
                      return FilterChip(
                        label: Text(_stateLabel(state)),
                        selected: selected,
                        avatar: Icon(
                          _stateIcon(state),
                          size: 16,
                          color: selected ? Colors.white : Colors.black54,
                        ),
                        onSelected: (value) {
                          setModalState(() {
                            if (value) {
                              tempStates.add(state);
                            } else {
                              tempStates.remove(state);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() => tempStates.clear());
                        },
                        child: const Text('Reset'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pop({...tempStates}),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _stateFilters = result);
    }
  }

  Future<void> _showBranchSelector() async {
    final selection = await showModalBottomSheet<Map<String, String>>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final branch = _branches[index];
              final selected = branch['id'] == _selectedBranchId;
              return ListTile(
                title: Text(branch['name']!),
                trailing: selected ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(branch),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: _branches.length,
          ),
        );
      },
    );

    if (selection != null) {
      setState(() {
        _selectedBranchId = selection['id']!;
        _selectedBranchName = selection['name']!;
      });
    }
  }

  InventoryStockState _mapState(StockItem item) {
    if (item.onHand == 0) return InventoryStockState.outOfStock;
    if (item.isLowStock) return InventoryStockState.lowStock;
    return InventoryStockState.healthy;
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon')),
    );
  }

  List<StockItem> _aggregateItems(List<StockItem> items) {
    final grouped = <String, List<StockItem>>{};
    for (final item in items) {
      final key =
          '${item.name}|${item.category}|${item.baseUnit}|${item.pieceSize}|${item.barcode ?? ''}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return grouped.entries.map((entry) {
      final first = entry.value.first;
      final totalOnHand =
          entry.value.fold<int>(0, (sum, item) => sum + item.onHand);
      final totalThreshold =
          entry.value.fold<int>(0, (sum, item) => sum + item.minThreshold);
      final mergedTags = <String>{};
      for (final item in entry.value) {
        mergedTags.addAll(item.usageTags);
      }
      return first.copyWith(
        id: '${entry.key}_aggregate',
        branchId: 'all',
        branchName: 'All branches',
        onHand: totalOnHand,
        minThreshold: totalThreshold,
        lastRestockDate: '-',
        expiryDate: '-',
        usageTags: mergedTags.toList(),
      );
    }).toList();
  }
}

String _stateLabel(InventoryStockState state) => switch (state) {
      InventoryStockState.healthy => 'Healthy',
      InventoryStockState.lowStock => 'Low stock',
      InventoryStockState.outOfStock => 'Out of stock',
    };

IconData _stateIcon(InventoryStockState state) => switch (state) {
      InventoryStockState.healthy => Icons.check_circle,
      InventoryStockState.lowStock => Icons.warning_amber,
      InventoryStockState.outOfStock => Icons.error_outline,
    };
