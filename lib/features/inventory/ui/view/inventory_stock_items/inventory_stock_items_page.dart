import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/forms/app_search_bar.dart';
import 'package:modular_pos/core/widgets/buttons/app_add_new_button.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/inventory_stock_items_utils.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/widgets/stock_item_card.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/widgets/stock_item_image.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

class InventoryStockItemsPage extends ConsumerStatefulWidget {
  const InventoryStockItemsPage({super.key});

  @override
  ConsumerState<InventoryStockItemsPage> createState() =>
      _InventoryStockItemsPageState();
}

class _InventoryStockItemsPageState
    extends ConsumerState<InventoryStockItemsPage> {
  final _searchController = TextEditingController();
  String _categoryFilter = 'All Categories';
  _ActiveFilter _activeFilter = _ActiveFilter.all;
  String _selectedBranchId = 'all';

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
    final hasNoStockItems = items.isEmpty;

    final userBranches =
        ref.watch(loginControllerProvider).user?.branches ?? const [];
    final branchEntries = _branchEntries(items, userBranches);
    final effectiveBranchId = branchEntries.any(
      (entry) => entry['id'] == _selectedBranchId,
    )
        ? _selectedBranchId
        : 'all';

    final categories = [
      'All Categories',
      ...{for (final entry in categoryLookup.entries) entry.value},
    ];

    final filtered = items.where((item) {
      final displayCategory = categoryLabel(item, categoryLookup);
      final matchesCategory =
          _categoryFilter == 'All Categories' ||
          displayCategory == _categoryFilter;
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
      final matchesBranch =
          effectiveBranchId == 'all' || item.branchId == effectiveBranchId;
      return matchesCategory && matchesSearch && matchesActive && matchesBranch;
    }).toList();

    final unique = <String, StockItem>{};
    for (final item in filtered) {
      unique.putIfAbsent(item.name.toLowerCase(), () => item);
    }
    final displayed = unique.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

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
                final desktopCategoryWidth = (availableWidth * 0.16).clamp(
                  170.0,
                  220.0,
                );
                final desktopStatusWidth = (availableWidth * 0.14).clamp(
                  150.0,
                  190.0,
                );
                final desktopBranchWidth = (availableWidth * 0.18).clamp(
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
                      label: 'Inactive',
                    ),
                  ],
                  onSelected: (value) => setState(
                    () => _activeFilter = value ?? _ActiveFilter.all,
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
                          hintText: 'Search by name or barcode',
                          fillColor: Colors.white,
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: desktopCategoryWidth,
                        child: categoryFilter,
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: desktopStatusWidth,
                        child: statusFilter,
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: desktopBranchWidth,
                        child: branchFilter,
                      ),
                      const SizedBox(width: 12),
                      SizedBox(width: desktopButtonWidth, child: button),
                    ],
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppSearchBar(
                              hintText: 'Search by name or barcode',
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
                      SizedBox(
                        width: contentWidth,
                        child: branchFilter,
                      ),
                    ],
                  ),
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
                                  'No stock items yet',
                                  style: Theme.of(context).textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create your first stock item to start managing inventory in this tab.',
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
                                    label: 'Create Stock Item',
                                    onPressed: () =>
                                        context.push(AppRoute.inventoryAddItem.path),
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
                            if (displayed.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No stock items match your filters. Try a different category, status, or search term.',
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            return ListView.separated(
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
                            );
                          }
                          if (displayed.isEmpty) {
                            return Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 64,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTableTheme.background,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'No stock items match your filters. Try a different category, status, or search term.',
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          // Wide screen: DataTable
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: SingleChildScrollView(
                                child: ClipRRect(
                                  borderRadius: BorderRadiusGeometry.circular(12),
                                  child: DataTable(
                                    dataRowMinHeight: 60,
                                    dataRowMaxHeight: 70,
                                    headingRowColor: WidgetStateProperty.all(
                                      AppTableTheme.headerBackground,
                                    ),
                                    dataRowColor: const WidgetStatePropertyAll(
                                      AppTableTheme.background,
                                    ),
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
                                        DataColumn(label: Text('No.', style: AppTableTheme.headerText,)),
                                        DataColumn(label: Text('Item', style: AppTableTheme.headerText,)),
                                        DataColumn(label: Text('Category', style: AppTableTheme.headerText,)),
                                        DataColumn(
                                          label: Text(
                                            'Assigned Branch (es)',
                                            style: AppTableTheme.headerText,),
                                        ),
                                        DataColumn(label: Text('Status', style: AppTableTheme.headerText,)),
                                        DataColumn(label: Text('Action', style: AppTableTheme.headerText,)),
                                      ],
                                    rows: List<DataRow>.generate(
                                        displayed.length,
                                        (index) {
                                          final item = displayed[index];
                                          final bool isActive = item.isActive;
                                          final assigned = _assignedBranches(
                                            item,
                                            items,
                                          );
                                          
                                                                  
                                          return DataRow(
                                            cells: [
                                              DataCell(Text('${index + 1}', style: AppTableTheme.cellText,)),
                                              DataCell(
                                                Row(
                                                  children: [
                                                    StockItemImage(
                                                      imageUrl: item.imageUrl,
                                                    ),
                                                    const SizedBox(width: 12),
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
                                                ),
                                              ),
                                                                  
                                              // Category pill
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
                                                                  
                                              // branch assignment
                                              DataCell(Text(assigned, style: AppTableTheme.cellText,)),
                                                                  
                                              // Status pill
                                              DataCell(
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: isActive
                                                        ? AppTableTheme
                                                          .healthyDecoration
                                                        : AppTableTheme
                                                          .dangerDecoration,
                                                  child: Text(
                                                    isActive
                                                        ? 'Active'
                                                        : 'Inactive',
                                                    style: isActive
                                                          ? AppTableTheme.healthyText
                                                          : AppTableTheme.dangerText
                                                    ),
                                                  ),
                                                ),
                                                                  
                                              // View button
                                              DataCell(
                                                ElevatedButton(
                                                  style: AppTableTheme.actionButtonStyle,
                                                  onPressed: () => context.push(
                                                    AppRoute
                                                        .inventoryStockDetail
                                                        .path,
                                                    extra: item,
                                                  ),
                                                  child: const Text('View'),
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

enum _ActiveFilter { all, active, inactive }
