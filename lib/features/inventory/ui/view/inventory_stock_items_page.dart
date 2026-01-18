import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/forms/app_search_add_bar.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
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
      final displayCategory = _categoryLabel(item, categoryLookup);
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
                              ?.copyWith(color: Theme.of(context).hintColor),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        itemBuilder: (context, index) {
                          final item = displayed[index];
                          return _StockItemCard(
                            item: item,
                            categoryLabel: _categoryLabel(item, categoryLookup),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
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

class _StockItemCard extends StatelessWidget {
  const _StockItemCard({required this.item, required this.categoryLabel});

  final StockItem item;
  final String categoryLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 3,
      color: Colors.white,
      shadowColor: scheme.shadow.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            context.push(AppRoute.inventoryStockDetail.path, extra: item),
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
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _pieceLabel(item),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        categoryLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: item.isActive ? scheme.primary : scheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Base: ${item.baseUnit}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Piece: ${item.pieceSize}',
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
    final initials = trimmed.isNotEmpty
        ? trimmed.substring(0, 1).toUpperCase()
        : '?';
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        height: 56,
        child: hasImage
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _StockPlaceholder(initials: initials, scheme: scheme),
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

String _categoryLabel(StockItem item, Map<String, String> categoryLookup) {
  if (item.categoryId != null && item.categoryId!.isNotEmpty) {
    final label = categoryLookup[item.categoryId!];
    if (label != null && label.isNotEmpty) return label;
  }
  if (item.category.isNotEmpty) return item.category;
  return 'Uncategorized';
}

enum _ActiveFilter { all, active, inactive }
