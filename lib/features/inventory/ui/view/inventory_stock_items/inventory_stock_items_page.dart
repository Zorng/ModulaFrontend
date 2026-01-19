import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/forms/app_search_add_bar.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/inventory_stock_items_utils.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/widgets/stock_item_card.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';

class InventoryStockItemsPage extends ConsumerStatefulWidget {
  const InventoryStockItemsPage({super.key});

  @override
  ConsumerState<InventoryStockItemsPage> createState() =>
      _InventoryStockItemsPageState();
}

class _InventoryStockItemsPageState
    extends ConsumerState<InventoryStockItemsPage> {
  final _searchController = TextEditingController();
  String _categoryFilter = 'All';
  _ActiveFilter _activeFilter = _ActiveFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stockInventoryControllerProvider.notifier).loadStockItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(stockInventoryControllerProvider);
    final categoryState = ref.watch(categoryControllerProvider);
    final categoryLookup = {
      for (final c in categoryState.categories) c.id: c.name,
    };
    final items = inventoryState.items;
    final categories = [
      'All',
      ...{for (final entry in categoryLookup.entries) entry.value},
    ];

    final filtered = items.where((item) {
      final displayCategory = categoryLabel(item, categoryLookup);
      final matchesCategory =
          _categoryFilter == 'All' || displayCategory == _categoryFilter;
      final matchesSearch =
          _searchController.text.isEmpty ||
          item.name.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ) ||
          (item.barcode ?? '').toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );
      final matchesActive = switch (_activeFilter) {
        _ActiveFilter.all => true,
        _ActiveFilter.active => item.isActive,
        _ActiveFilter.inactive => !item.isActive,
      };
      return matchesCategory && matchesSearch && matchesActive;
    }).toList();

    final unique = <String, StockItem>{};
    for (final item in filtered) {
      unique.putIfAbsent(item.name.toLowerCase(), () => item);
    }
    final displayed = unique.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(title: const Text('Stock items'), centerTitle: false),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSearchAddBar(
              searchHint: 'Search by name or barcode',
              searchController: _searchController,
              onSearchChanged: (_) => setState(() {}),
              onAddPressed: () => context.push(AppRoute.inventoryAddItem.path),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InventoryDropdown<String>(
                    initialValue: _categoryFilter,
                    label: const Text('Category'),
                    entries: categories
                        .map(
                          (category) => DropdownMenuEntry(
                            value: category,
                            label: category,
                          ),
                        )
                        .toList(),
                    onSelected: (value) =>
                        setState(() => _categoryFilter = value ?? 'All'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: InventoryDropdown<_ActiveFilter>(
                    initialValue: _activeFilter,
                    label: const Text('Status'),
                    entries: const [
                      DropdownMenuEntry(
                        value: _ActiveFilter.all,
                        label: 'All statuses',
                      ),
                      DropdownMenuEntry(
                        value: _ActiveFilter.active,
                        label: 'Active',
                      ),
                      DropdownMenuEntry(
                        value: _ActiveFilter.inactive,
                        label: 'Inactive',
                      ),
                    ],
                    onSelected: (value) => setState(
                      () => _activeFilter = value ?? _ActiveFilter.all,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 0,
                color: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: inventoryState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : inventoryState.error != null
                        ? Center(
                            child: Text(
                              UserErrorMessage.build(
                                context: 'Failed to load stock items',
                                error: inventoryState.error,
                              ),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            itemBuilder: (context, index) {
                              final item = displayed[index];
                              return StockItemCard(
                                item: item,
                                categoryLabel: categoryLabel(
                                  item,
                                  categoryLookup,
                                ),
                              );
                            },
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemCount: displayed.length,
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ActiveFilter { all, active, inactive }

