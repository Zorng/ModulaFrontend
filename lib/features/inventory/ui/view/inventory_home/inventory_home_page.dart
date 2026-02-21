import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/forms/app_search_bar.dart';
import 'package:modular_pos/core/widgets/buttons/app_add_new_button.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/inventory_stock_items_utils.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/widgets/stock_item_image.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_item_card.dart';

class InventoryHomePage extends ConsumerStatefulWidget {
  const InventoryHomePage({super.key});

  @override
  ConsumerState<InventoryHomePage> createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends ConsumerState<InventoryHomePage> {
  String _selectedBranchId = 'all';
  String _categoryFilter = 'All Categories';
  _StockStatus _stockStatus = _StockStatus.all;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ensure fresh data when opening inventory.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryControllerProvider.notifier).loadCategories();
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
    final userBranches =
        ref.watch(loginControllerProvider).user?.branches ?? const [];
    final items = inventoryState.items;
    final hasNoStockItems = items.isEmpty;
    final branchEntries = _branchEntries(items, userBranches);
    final effectiveBranchId = branchEntries.any(
      (entry) => entry['id'] == _selectedBranchId,
    )
        ? _selectedBranchId
        : 'all';
    final categoryLookup = {
      for (final c in categoryState.categories) c.id: c.name,
    };

    final filtered = items.where((item) {
      final displayCategory = categoryLabel(item, categoryLookup);
      final matchesCategory =
          _categoryFilter == 'All Categories' ||
          displayCategory == _categoryFilter;
      final matchesBranch =
          effectiveBranchId == 'all' || item.branchId == effectiveBranchId;
      final matchesSearch =
          _searchController.text.isEmpty ||
          item.name.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );
      final matchesStatus = switch (_stockStatus) {
        _StockStatus.all => true,
        _StockStatus.healthy => item.onHand > 0,
        _StockStatus.outOfStock => item.onHand <= 0,
      };
      return matchesCategory && matchesBranch && matchesSearch && matchesStatus;
    }).toList();

    final displayed = effectiveBranchId == 'all'
        ? _aggregateItems(filtered)
        : filtered;

    final categoryList = (categoryState.categories.map((c) => c.name).toList()
      ..sort());
    final categories = ['All Categories', ...categoryList];

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
                final contentWidth = (availableWidth - 32).clamp(0.0, double.infinity);
                final desktopFilterWidth = (availableWidth * 0.16).clamp(
                  170.0,
                  220.0,
                );
                final desktopButtonWidth = 132.0;
                final compactButtonWidth = contentWidth < 420 ? 108.0 : 120.0;
                final button = AppAddNewButton(
                  onPressed: hasNoStockItems
                      ? null
                      : () async {
                          await context.push(
                            AppRoute.inventoryRestock.path,
                          );
                          if (!mounted) return;
                          ref
                              .read(
                                stockInventoryControllerProvider.notifier,
                              )
                              .loadStockItems(
                                branchId: effectiveBranchId == 'all'
                                    ? null
                                    : effectiveBranchId,
                              );
                        },
                  label: 'Restock',
                );

                final categoryFilter = InventoryDropdown<String>(
                  initialValue: _categoryFilter,
                  entries: categories
                      .map(
                        (category) => DropdownMenuEntry(
                          value: category,
                          label: category,
                        ),
                      )
                      .toList(),
                  onSelected: (value) => setState(
                    () => _categoryFilter = value ?? 'All Categories',
                  ),
                );

                final statusFilter = InventoryDropdown<_StockStatus>(
                  initialValue: _stockStatus,
                  entries: const [
                    DropdownMenuEntry(
                      value: _StockStatus.all,
                      label: 'All statuses',
                    ),
                    DropdownMenuEntry(
                      value: _StockStatus.healthy,
                      label: 'Healthy',
                    ),
                    DropdownMenuEntry(
                      value: _StockStatus.outOfStock,
                      label: 'Out of stock',
                    ),
                  ],
                  onSelected: (value) => setState(
                    () => _stockStatus = value ?? _StockStatus.all,
                  ),
                );

                final branchFilter = InventoryDropdown<String>(
                  initialValue: effectiveBranchId,
                  entries: branchEntries
                      .map(
                        (branch) => DropdownMenuEntry(
                          value: branch['id']!,
                          label: branch['name']!,
                        ),
                      )
                      .toList(),
                  onSelected: (value) {
                    final selected = value ?? 'all';
                    setState(() => _selectedBranchId = selected);
                    ref
                        .read(stockInventoryControllerProvider.notifier)
                        .loadStockItems(
                          branchId: selected == 'all' ? null : selected,
                        );
                  },
                );

                if (hasNavigationRail) {
                  return Row(
                    children: [
                      Expanded(
                        child: AppSearchBar(
                          hintText: 'Search stock items',
                          fillColor: Colors.white,
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: desktopFilterWidth,
                        child: categoryFilter,
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: desktopFilterWidth,
                        child: statusFilter,
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: desktopFilterWidth,
                        child: branchFilter,
                      ),
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
                            hintText: 'Search stock items',
                            fillColor: Colors.white,
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: branchFilter,
                        ),
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
                            context: 'Failed to load inventory',
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
                                  'No inventory yet',
                                  style: Theme.of(context).textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Inventory depends on Stock Items. Create a stock item first, then you can restock and manage quantities here.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context).hintColor,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: 220,
                                  child: AppAddNewButton(
                                    onPressed: () =>
                                        context.push(AppRoute.inventoryAddItem.path),
                                    label: 'Create Stock Item',
                                  ),
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
                              itemCount: displayed.length,
                              itemBuilder: (context, index) {
                                final item = displayed[index];
                                return InventoryItemCard(
                                  item: item,
                                  showState: effectiveBranchId != 'all',
                                  onTap: () {
                                    if (item.branchId == 'all') {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                            );
                          }

                          // Wide screen: show DataTable
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: SingleChildScrollView(
                                child: ClipRRect(
                                  borderRadius: BorderRadiusGeometry.circular(
                                    12,
                                  ),
                                  child: DataTable(
                                    dataRowMinHeight: 60,
                                    dataRowMaxHeight: 70,
                                    headingRowColor: WidgetStateProperty.all(
                                      AppTableTheme.headerBackground,
                                    ),
                                    dataRowColor: WidgetStatePropertyAll(AppTableTheme.background),
                                    dividerThickness: 1,
                                    border: const TableBorder(
                                      top: BorderSide(
                                        color: AppTableTheme.divider,
                                      ),
                                      bottom: BorderSide(
                                        color: AppTableTheme.divider,
                                      ),
                                      left: BorderSide(
                                        color: AppTableTheme.divider,
                                      ),
                                      right: BorderSide(
                                        color: AppTableTheme.divider,
                                      ),
                                    ),
                                    columns: const [
                                      DataColumn(
                                        label: Text(
                                          'No.',
                                          style: AppTableTheme.headerText,
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Item Name',
                                          style: AppTableTheme.headerText,
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Category',
                                          style: AppTableTheme.headerText,
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Current Piece',
                                          style: AppTableTheme.headerText,
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Assigned Branch(es)',
                                          style: AppTableTheme.headerText,
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Status',
                                          style: AppTableTheme.headerText,
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Action',
                                          style: AppTableTheme.headerText,
                                        ),
                                      ),
                                    ],
                                    rows: List<DataRow>.generate(
                                      displayed.length,
                                      (index) {
                                        final item = displayed[index];
                                        final isHealthy = item.onHand > 0;
                                        final assigned = _assignedBranches(
                                          item,
                                          items,
                                        );
                                          
                                  
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(
                                                '${index + 1}',
                                                style: AppTableTheme.cellText,
                                              ),
                                            ),
                                  
                                            DataCell(
                                              Row(
                                                children: [
                                                  StockItemImage(imageUrl: item.imageUrl),
                                                  const SizedBox(width: 12,),
                                                  Flexible(
                                                      child: Text(
                                                        item.name,
                                                        style: Theme.of(
                                                          context,
                                                        ).textTheme.bodyMedium,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                ],
                                              )
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
                                                  item.category,
                                                  style: AppTableTheme
                                                      .categoryPillText,
                                                ),
                                              ),
                                            ),
                                  
                                            DataCell(
                                              Text(
                                                '${item.onHand} ${item.baseUnit}',
                                                style: AppTableTheme.cellText,
                                              ),
                                            ),
                                  
                                            DataCell(
                                              Text(
                                                assigned,
                                                style: AppTableTheme.cellText,
                                              ),
                                            ),
                                  
                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: isHealthy
                                                    ? AppTableTheme
                                                          .healthyDecoration
                                                    : AppTableTheme
                                                          .dangerDecoration,
                                                child: Text(
                                                  isHealthy
                                                      ? 'Healthy'
                                                      : 'Out of stock',
                                                  style: isHealthy
                                                      ? AppTableTheme.healthyText
                                                      : AppTableTheme.dangerText,
                                                ),
                                              ),
                                            ),
                                  
                                            DataCell(
                                              ElevatedButton(
                                                style: AppTableTheme
                                                    .actionButtonStyle,
                                                onPressed: () {
                                                  context.push(
                                                    '/inventory/adjust',
                                                    extra: item,
                                                  );
                                                },
                                                child: const Text('Adjust'),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
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

  List<Map<String, String>> _branchEntries(
    List<StockItem> items,
    List<UserBranch> userBranches,
  ) {
    final map = <String, String>{};
    if (userBranches.isNotEmpty) {
      for (final b in userBranches) {
        final id = b.branchId.isNotEmpty ? b.branchId : b.id;
        map[id] = b.name;
      }
    } else {
      for (final item in items) {
        map[item.branchId] = item.branchName;
      }
    }
    final entries =
        map.entries
            .map((entry) => {'id': entry.key, 'name': entry.value})
            .toList()
          ..sort((a, b) => a['name']!.compareTo(b['name']!));
    if (entries.every((entry) => entry['id'] != 'all')) {
      entries.insert(0, {'id': 'all', 'name': 'All Branches'});
    }
    return entries;
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
      final totalOnHand = entry.value.fold<int>(
        0,
        (sum, item) => sum + item.onHand,
      );
      final totalThreshold = entry.value.fold<int>(
        0,
        (sum, item) => sum + item.minThreshold,
      );
      final mergedTags = <String>{};
      for (final item in entry.value) {
        mergedTags.addAll(item.usageTags);
      }
      return first.copyWith(
        id: '${entry.key}_aggregate',
        branchId: 'all',
        branchName: 'All Branches',
        onHand: totalOnHand,
        minThreshold: totalThreshold,
        lastRestockDate: '-',
        expiryDate: '-',
        usageTags: mergedTags.toList(),
      );
    }).toList();
  }

    String _assignedBranches(StockItem item, List<StockItem> allItems) {
    final branches = <String>{};

    for (final it in allItems) {
      if (it.name == item.name && it.category == item.category) {
        branches.add(it.branchName);
      }
    }

    if (branches.length <= 1) {
      return item.branchName;
    }

    return '${branches.length} branches assigned';
  }
}

enum _StockStatus { all, healthy, outOfStock }
