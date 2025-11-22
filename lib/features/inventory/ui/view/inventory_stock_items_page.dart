import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/app_search_add_bar.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/domain/utils/stock_quantity_formatter.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';

class InventoryStockItemsPage extends ConsumerStatefulWidget {
  const InventoryStockItemsPage({super.key});

  @override
  ConsumerState<InventoryStockItemsPage> createState() => _InventoryStockItemsPageState();
}

class _InventoryStockItemsPageState extends ConsumerState<InventoryStockItemsPage> {
  final _searchController = TextEditingController();
  String _categoryFilter = 'All';
  _ActiveFilter _activeFilter = _ActiveFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(stockInventoryControllerProvider);
    final items = inventoryState.items;
    final categories = ['All', ...{for (final item in items) item.category}];

    final filtered = items.where((item) {
      final matchesCategory =
          _categoryFilter == 'All' || item.category == _categoryFilter;
      final matchesSearch = _searchController.text.isEmpty ||
          item.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          (item.barcode ?? '').toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesActive = switch (_activeFilter) {
        _ActiveFilter.all => true,
        _ActiveFilter.active => item.isActive,
        _ActiveFilter.inactive => !item.isActive,
      };
      return matchesCategory && matchesSearch && matchesActive;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock items'),
        centerTitle: false,
      ),
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
                  child: DropdownButtonFormField<String>(
                    value: _categoryFilter,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _categoryFilter = value ?? 'All'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<_ActiveFilter>(
                    value: _activeFilter,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(
                        value: _ActiveFilter.all,
                        child: Text('All statuses'),
                      ),
                      DropdownMenuItem(
                        value: _ActiveFilter.active,
                        child: Text('Active'),
                      ),
                      DropdownMenuItem(
                        value: _ActiveFilter.inactive,
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _activeFilter = value ?? _ActiveFilter.all),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return _StockItemCard(item: item);
                            },
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemCount: filtered.length,
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockItemCard extends StatelessWidget {
  const _StockItemCard({required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onHandText = StockQuantityFormatter(
      baseQty: item.onHand,
      pieceSize: item.pieceSize,
      baseUnit: item.baseUnit,
    ).format();
    final minText = StockQuantityFormatter(
      baseQty: item.minThreshold,
      pieceSize: item.pieceSize,
      baseUnit: item.baseUnit,
    ).format();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoute.inventoryStockDetail.path, extra: item),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _StockItemImage(label: item.name, imageUrl: item.imageUrl),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('${item.category} • ${_pieceLabel(item)}'),
                  const SizedBox(height: 4),
                  Text(
                    item.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: item.isActive ? scheme.primary : scheme.error,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  onHandText,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Min $minText',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _StockItemImage extends StatelessWidget {
  const _StockItemImage({required this.label, this.imageUrl});

  final String label;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trimmed = label.trim();
    final initials = trimmed.isNotEmpty ? trimmed.substring(0, 1).toUpperCase() : '?';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        height: 56,
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _StockPlaceholder(initials: initials, scheme: scheme),
              )
            : _StockPlaceholder(initials: initials, scheme: scheme),
      ),
    );
  }
}

class _StockPlaceholder extends StatelessWidget {
  const _StockPlaceholder({required this.initials, required this.scheme});

  final String initials;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.secondaryContainer,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

String _pieceLabel(StockItem item) {
  if (item.pieceSize <= 1) return item.baseUnit;
  return '${item.pieceSize} ${item.baseUnit} per piece';
}

enum _ActiveFilter { all, active, inactive }
