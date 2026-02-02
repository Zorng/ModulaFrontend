import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/widgets/forms/app_search_add_bar.dart';
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
  String _categoryFilter = 'All';
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
    final categoryLookup = {
      for (final c in categoryState.categories) c.id: c.name,
    };

    final filtered = items.where((item) {
      final displayCategory = categoryLabel(item, categoryLookup);
      final matchesCategory =
          _categoryFilter == 'All' || displayCategory == _categoryFilter;
      final matchesBranch =
          _selectedBranchId == 'all' || item.branchId == _selectedBranchId;
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

    final displayed = _selectedBranchId == 'all'
        ? _aggregateItems(filtered)
        : filtered;

    final categoryList = (categoryState.categories.map((c) => c.name).toList()
      ..sort());
    final categories = ['All', ...categoryList];

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
                                child: AppSearchBar(
                                  hintText: 'Search stock items',
                                  controller: _searchController,
                                  onChanged: (_) => setState(() {}),
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
                                child: InventoryDropdown<_StockStatus>(
                                  initialValue: _stockStatus,
                                  label: const Text('Status'),
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
                                    () => _stockStatus =
                                        value ?? _StockStatus.all,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 140,
                                child: AppAddNewButton(
                                  onPressed: () async {
                                    await context.push(
                                      AppRoute.inventoryRestock.path,
                                    );
                                    if (!mounted) return;
                                    ref
                                        .read(
                                          stockInventoryControllerProvider
                                              .notifier,
                                        )
                                        .loadStockItems(
                                          branchId: _selectedBranchId == 'all'
                                              ? null
                                              : _selectedBranchId,
                                        );
                                  },
                                  label: '+ Restock',
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
                      searchHint: 'Search stock items',
                      searchController: _searchController,
                      onSearchChanged: (_) => setState(() {}),
                      addButtonLabel: 'Restock',
                      onAddPressed: () async {
                        await context.push(AppRoute.inventoryRestock.path);
                        if (!mounted) return;
                        ref
                            .read(stockInventoryControllerProvider.notifier)
                            .loadStockItems(
                              branchId: _selectedBranchId == 'all'
                                  ? null
                                  : _selectedBranchId,
                            );
                      },
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
                          child: InventoryDropdown<_StockStatus>(
                            initialValue: _stockStatus,
                            label: const Text('Status'),
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
                            context: 'Failed to load inventory',
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
                            return ListView.separated(
                              itemCount: displayed.length,
                              itemBuilder: (context, index) {
                                final item = displayed[index];
                                return InventoryItemCard(
                                  item: item,
                                  showState: _selectedBranchId != 'all',
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
                              child: Container(
                                color: AppTableTheme.background,
                                padding: const EdgeInsets.all(24),
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
                                        'Piece Size',
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
                                              item.onHand.toString(),
                                              style: AppTableTheme.cellText,
                                            ),
                                          ),

                                          DataCell(
                                            Text(
                                              item.pieceSize.toString(),
                                              style: AppTableTheme.cellText,
                                            ),
                                          ),

                                          DataCell(
                                            Text(
                                              item.branchName,
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
      // Reload inventory for the selected branch (or all branches).
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
        branchName: 'All branches',
        onHand: totalOnHand,
        minThreshold: totalThreshold,
        lastRestockDate: '-',
        expiryDate: '-',
        usageTags: mergedTags.toList(),
      );
    }).toList();
  }

  String _assignedBranches(StockItem item, List<StockItem> allItems) {
    if (item.branchId != 'all') return item.branchName;
    final branches = <String>{};
    for (final it in allItems) {
      if (it.name == item.name && it.category == item.category) {
        branches.add(it.branchName);
      }
    }
    if (branches.isEmpty) return item.branchName;
    return branches.join(', ');
  }
}

enum _StockStatus { all, healthy, outOfStock }
