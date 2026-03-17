import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/buttons/app_add_new_button.dart';
import 'package:modular_pos/core/widgets/forms/app_search_bar.dart';
import 'package:modular_pos/core/widgets/layout/app_pagination_bar.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/inventory_stock_items_utils.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/widgets/stock_item_card.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/widgets/stock_item_image.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';
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
  static const int _pageSize = 10;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _categoryFilterId = 'all';
  _ActiveFilter _activeFilter = _ActiveFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(categoryControllerProvider.notifier).loadCategories();
      await _loadStockItems();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
    final compactViewButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppTableTheme.actionButtonColor,
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    final items = inventoryState.stockItems;
    final hasSearch = _searchController.text.trim().isNotEmpty;
    final hasCategoryFilter = _categoryFilterId != 'all';
    final hasStatusFilter = _activeFilter != _ActiveFilter.all;
    final hasActiveFilters = hasSearch || hasCategoryFilter || hasStatusFilter;
    final hasNoStockItems = items.isEmpty;

    final categoryEntries = <DropdownMenuEntry<String>>[
      const DropdownMenuEntry<String>(value: 'all', label: 'All Categories'),
      ...categoryState.categories
          .map(
            (category) => DropdownMenuEntry<String>(
              value: category.id,
              label: category.name,
            ),
          )
          .toList(growable: false)
        ..sort((a, b) => a.label.compareTo(b.label)),
    ];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final hasNavigationRail = AppBreakpoints.isLarge(
                  MediaQuery.of(context).size.width,
                );
                final availableWidth = constraints.maxWidth;
                final contentWidth = (availableWidth - 32).clamp(
                  0.0,
                  double.infinity,
                );
                final desktopFilterWidth = (availableWidth * 0.18).clamp(
                  180.0,
                  240.0,
                );
                final desktopButtonWidth = 132.0;
                final compactButtonWidth = contentWidth < 420 ? 108.0 : 120.0;
                final button = AppAddNewButton(
                  label: 'Add new',
                  onPressed: () => context.push(AppRoute.inventoryAddItem.path),
                );

                final categoryFilter = InventoryDropdown<String>(
                  initialValue: _categoryFilterId,
                  entries: categoryEntries,
                  onSelected: (value) {
                    setState(() => _categoryFilterId = value ?? 'all');
                    _reloadStockItems();
                  },
                );

                final statusFilter = InventoryDropdown<_ActiveFilter>(
                  initialValue: _activeFilter,
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
                      label: 'Archived',
                    ),
                  ],
                  onSelected: (value) {
                    final selected = value ?? _ActiveFilter.all;
                    setState(() => _activeFilter = selected);
                    _reloadStockItems();
                  },
                );

                if (hasNavigationRail) {
                  return Row(
                    children: [
                      Expanded(
                        child: AppSearchBar(
                          hintText: 'Search by name',
                          fillColor: Colors.white,
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: desktopFilterWidth,
                        child: categoryFilter,
                      ),
                      const SizedBox(width: 12),
                      SizedBox(width: desktopFilterWidth, child: statusFilter),
                      const SizedBox(width: 12),
                      SizedBox(width: desktopButtonWidth, child: button),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppSearchBar(
                            hintText: 'Search by name',
                            fillColor: Colors.white,
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(width: compactButtonWidth, child: button),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: statusFilter),
                        const SizedBox(width: 8),
                        Expanded(child: categoryFilter),
                      ],
                    ),
                  ],
                );
              },
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
                    : hasNoStockItems
                    ? Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  hasActiveFilters
                                      ? 'No stock items match your filters'
                                      : 'No stock items yet',
                                  style: Theme.of(context).textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  hasActiveFilters
                                      ? 'Try a different category, status, or search term.'
                                      : 'Create your first stock item to start managing inventory.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context).hintColor,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final hasNavigationRail = AppBreakpoints.isLarge(
                            MediaQuery.of(context).size.width,
                          );
                          if (!hasNavigationRail) {
                            return ListView.separated(
                              padding: EdgeInsets.zero,
                              itemBuilder: (context, index) {
                                if (index >= items.length) {
                                  if (inventoryState.isLoadingMoreStockItems) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: FilledButton(
                                        onPressed: _loadMoreStockItems,
                                        child: const Text('Load more'),
                                      ),
                                    ),
                                  );
                                }
                                final item = items[index];
                                return StockItemCard(
                                  item: item,
                                  categoryLabel: categoryLabel(
                                    item,
                                    categoryLookup,
                                  ),
                                  onRestore: item.isActive
                                      ? null
                                      : () => _restoreItem(item),
                                );
                              },
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemCount:
                                  items.length +
                                  (inventoryState.hasNextStockItemsPage
                                      ? 1
                                      : 0),
                            );
                          }
                          final tableContentWidth = constraints.maxWidth < 980
                              ? 980.0
                              : constraints.maxWidth;
                          return SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: tableContentWidth,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppTableTheme.background,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTableTheme.divider,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(1),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                          child: DataTable(
                                            dataRowMinHeight: 60,
                                            dataRowMaxHeight: 70,
                                            headingRowColor:
                                                WidgetStateProperty.all(
                                                  AppTableTheme
                                                      .headerBackground,
                                                ),
                                            dataRowColor:
                                                const WidgetStatePropertyAll(
                                                  AppTableTheme.background,
                                                ),
                                            dividerThickness: 1,
                                            border: const TableBorder(
                                              horizontalInside: BorderSide(
                                                color: AppTableTheme.divider,
                                              ),
                                            ),
                                            columns: const [
                                              DataColumn(
                                                label: Text(
                                                  'No.',
                                                  style:
                                                      AppTableTheme.headerText,
                                                ),
                                              ),
                                              DataColumn(
                                                label: Text(
                                                  'Item',
                                                  style:
                                                      AppTableTheme.headerText,
                                                ),
                                              ),
                                              DataColumn(
                                                label: Text(
                                                  'Category',
                                                  style:
                                                      AppTableTheme.headerText,
                                                ),
                                              ),
                                              DataColumn(
                                                label: Text(
                                                  'Threshold',
                                                  style:
                                                      AppTableTheme.headerText,
                                                ),
                                              ),
                                              DataColumn(
                                                label: Text(
                                                  'Action',
                                                  style:
                                                      AppTableTheme.headerText,
                                                ),
                                              ),
                                            ],
                                            rows: List<DataRow>.generate(items.length, (
                                              index,
                                            ) {
                                              final item = items[index];

                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text(
                                                      '${inventoryState.stockItemsVisibleRangeStart + index}',
                                                      style: AppTableTheme
                                                          .cellText,
                                                    ),
                                                  ),
                                                  DataCell(
                                                    SizedBox(
                                                      width: 280,
                                                      child: Row(
                                                        children: [
                                                          StockItemImage(
                                                            imageUrl:
                                                                item.imageUrl,
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              item.name,
                                                              style:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .textTheme
                                                                      .bodyMedium,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 6,
                                                          ),
                                                      decoration: AppTableTheme
                                                          .categoryPillDecoration,
                                                      child: Text(
                                                        categoryLabel(
                                                          item,
                                                          categoryLookup,
                                                        ),
                                                        style: AppTableTheme
                                                            .categoryPillText,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      '${item.minThreshold} ${item.baseUnit}',
                                                      style: AppTableTheme
                                                          .cellText,
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Wrap(
                                                      spacing: 8,
                                                      runSpacing: 8,
                                                      children: [
                                                        ElevatedButton(
                                                          style:
                                                              compactViewButtonStyle,
                                                          onPressed: () =>
                                                              context.push(
                                                                AppRoute
                                                                    .inventoryStockDetail
                                                                    .path,
                                                                extra: item,
                                                              ),
                                                          child: const Text(
                                                            'View',
                                                          ),
                                                        ),
                                                        if (!item.isActive)
                                                          OutlinedButton.icon(
                                                            onPressed: () =>
                                                                _restoreItem(
                                                                  item,
                                                                ),
                                                            icon: const Icon(
                                                              Icons
                                                                  .restore_outlined,
                                                              size: 18,
                                                            ),
                                                            label: const Text(
                                                              'Restore',
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    AppPaginationBar(
                                      rangeLabel:
                                          'Showing ${inventoryState.stockItemsVisibleRangeStart}-${inventoryState.stockItemsVisibleRangeEnd} entries',
                                      currentPage:
                                          inventoryState.stockItemsCurrentPage,
                                      totalPages:
                                          inventoryState.stockItemsTotalPages,
                                      canGoPrevious: inventoryState
                                          .hasPreviousStockItemsPage,
                                      canGoNext:
                                          inventoryState.hasNextStockItemsPage,
                                      isLoading: inventoryState
                                          .isStockItemsPageLoading,
                                      onPageSelected: _goToStockItemsPage,
                                      onPrevious: _goToPreviousStockItemsPage,
                                      onNext: _goToNextStockItemsPage,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusApiValue(_ActiveFilter filter) {
    return switch (filter) {
      _ActiveFilter.all => 'all',
      _ActiveFilter.active => 'active',
      _ActiveFilter.inactive => 'archived',
    };
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _reloadStockItems();
    });
  }

  Future<void> _reloadStockItems() {
    return _loadStockItems(page: 1);
  }

  Future<void> _loadStockItems({int page = 1, bool accumulatePages = false}) {
    return ref
        .read(stockInventoryControllerProvider.notifier)
        .loadStockItemsPage(
          status: _statusApiValue(_activeFilter),
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          categoryId: _categoryFilterId == 'all' ? null : _categoryFilterId,
          limit: _pageSize,
          page: page,
          pageTransition: page > 1,
          accumulatePages: accumulatePages,
        );
  }

  Future<void> _goToStockItemsPage(int page) {
    return ref
        .read(stockInventoryControllerProvider.notifier)
        .goToStockItemsPage(page);
  }

  Future<void> _goToNextStockItemsPage() {
    return ref
        .read(stockInventoryControllerProvider.notifier)
        .goToNextStockItemsPage();
  }

  Future<void> _goToPreviousStockItemsPage() {
    return ref
        .read(stockInventoryControllerProvider.notifier)
        .goToPreviousStockItemsPage();
  }

  Future<void> _loadMoreStockItems() {
    return ref
        .read(stockInventoryControllerProvider.notifier)
        .loadMoreStockItems();
  }

  Future<void> _restoreItem(StockItem item) async {
    try {
      await ref
          .read(stockInventoryControllerProvider.notifier)
          .restoreStockItem(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${item.name} restored')));
    } catch (e) {
      if (!mounted) return;
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to restore stock item.',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapped.message)));
    }
  }
}

enum _ActiveFilter { all, active, inactive }
