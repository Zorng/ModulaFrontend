import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/forms/app_search_bar.dart';
import 'package:modular_pos/core/widgets/forms/app_search_add_bar.dart';
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
  String _categoryFilter = 'All';
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

    final userBranches =
        ref.watch(loginControllerProvider).user?.branches ?? const [];
    final branchEntries = _branchEntries(items, userBranches);
    if (_selectedBranchId == 'all' && branchEntries.length == 2) {
      _selectedBranchId = branchEntries.first['id'] == 'all'
          ? branchEntries[1]['id']!
          : branchEntries.first['id']!;
    } else if (_selectedBranchId == 'all' && userBranches.length == 1) {
      _selectedBranchId = userBranches.first.branchId.isNotEmpty
          ? userBranches.first.branchId
          : userBranches.first.id;
    }
    final branchLabel = _branchLabel(branchEntries);
    final canSelectBranch = branchEntries.length > 1;

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
      final matchesBranch =
          _selectedBranchId == 'all' || item.branchId == _selectedBranchId;
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
                final isWide = !AppBreakpoints.isSmall(constraints.maxWidth);
                if (isWide) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1440),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 3,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 366,
                                  ),
                                  child: AppSearchBar(
                                    hintText: 'Search by name or barcode',
                                    controller: _searchController,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: GestureDetector(
                                  onTap: categoryState.categories.isEmpty
                                      ? () => _showNoCategoriesDialog(context)
                                      : null,
                                  child: AbsorbPointer(
                                    absorbing: categoryState.categories.isEmpty,
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
                                      onSelected: (value) => setState(
                                        () => _categoryFilter = value ?? 'All',
                                      ),
                                    ),
                                  ),
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
                                    () => _activeFilter =
                                        value ?? _ActiveFilter.all,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 140,
                                child: AppAddNewButton(
                                  label: 'Add new',
                                  onPressed: () => context.push(
                                    AppRoute.inventoryAddItem.path,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  );
                }

                // Small / default layout
                return Column(
                  children: [
                    AppSearchAddBar(
                      searchHint: 'Search by name or barcode',
                      searchController: _searchController,
                      onSearchChanged: (_) => setState(() {}),
                      onAddPressed: () =>
                          context.push(AppRoute.inventoryAddItem.path),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: categoryState.categories.isEmpty
                                ? () => _showNoCategoriesDialog(context)
                                : null,
                            child: AbsorbPointer(
                              absorbing: categoryState.categories.isEmpty,
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
                                onSelected: (value) => setState(
                                  () => _categoryFilter = value ?? 'All',
                                ),
                              ),
                            ),
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
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${displayed.length} item${displayed.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: canSelectBranch
                      ? () => _showBranchSelector(branchEntries)
                      : null,
                  icon: const Icon(Icons.store_outlined),
                  label: Text(branchLabel),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = !AppBreakpoints.isSmall(
                            constraints.maxWidth,
                          );
                          if (!isWide) {
                            if (displayed.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No items found',
                                  style: TextStyle(color: Colors.grey),
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
                                  'No items found',
                                  style: TextStyle(color: Colors.grey),
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
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTableTheme.background,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.all(24),
                                child: SingleChildScrollView(
                                  child: ClipRRect(
                                    borderRadius: BorderRadiusGeometry.circular(12),
                                    child: DataTable(
                                      dataRowMinHeight: 60,
                                      dataRowMaxHeight: 70,
                                                                    
                                      headingRowColor: WidgetStateProperty.all(
                                        AppTableTheme.headerBackground,
                                      ),
                                      dividerThickness: 1,
                                      border: const TableBorder(
                                        horizontalInside: BorderSide(
                                          color: AppTableTheme.divider,
                                        ),
                                      ),
                                      columns: const [
                                        DataColumn(label: Text('No.', style: AppTableTheme.headerText,)),
                                        DataColumn(label: Text('Item', style: AppTableTheme.headerText,)),
                                        DataColumn(label: Text('Category', style: AppTableTheme.headerText,)),
                                        DataColumn(label: Text('Piece Size', style: AppTableTheme.headerText,)),
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
                                                                  
                                              // price
                                              DataCell(
                                                Text(item.pieceSize.toString(), style: AppTableTheme.cellText,),
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

  Future<void> _showBranchSelector(List<Map<String, String>> branches) async {
    if (branches.length <= 1) return;
    final selection = await showModalBottomSheet<Map<String, String>>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final branch = branches[index];
              final selected = branch['id'] == _selectedBranchId;
              return ListTile(
                title: Text(branch['name']!),
                trailing: selected ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(branch),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: branches.length,
          ),
        );
      },
    );

    if (selection != null) {
      final id = selection['id']!;
      setState(() => _selectedBranchId = id);
      ref
          .read(stockInventoryControllerProvider.notifier)
          .loadStockItems(branchId: id == 'all' ? null : id);
    }
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
    if (entries.length > 1) {
      entries.insert(0, {'id': 'all', 'name': 'All branches'});
    }
    return entries;
  }

  String _branchLabel(List<Map<String, String>> branches) {
    if (_selectedBranchId == 'all') return 'All branches';
    for (final branch in branches) {
      if (branch['id'] == _selectedBranchId) {
        return branch['name']!;
      }
    }
    if (branches.isNotEmpty) return branches.first['name']!;
    return 'All branches';
  }

  Future<void> _showNoCategoriesDialog(BuildContext context) async {
    final router = GoRouter.of(context);
    final choice = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Text('No categories'),
              const Spacer(),
              IconButton(
                tooltip: 'Cancel',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
          content: const Text(
            'No categories available. Create a category now?',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Create Category'),
            ),
          ],
        );
      },
    );

    if (choice == true && mounted) {
      await router.push(AppRoute.inventoryAddCategory.path);
      if (!mounted) return;
      ref.read(categoryControllerProvider.notifier).loadCategories();
    }
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
