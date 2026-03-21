import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/sync/sync_freshness.dart';
import 'package:modular_pos/core/widgets/sync/sync_freshness_banner.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/ui/view/menu/widgets/menu_page_filter_bar.dart';
import 'package:modular_pos/features/menu/ui/view/menu/widgets/menu_page_items_section.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

class MenuPage extends ConsumerStatefulWidget {
  const MenuPage({super.key});

  @override
  ConsumerState<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends ConsumerState<MenuPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(menuViewModelProvider.notifier).loadMenu();
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuViewModelProvider);
    final notifier = ref.read(menuViewModelProvider.notifier);
    final workspaceFreshness = ref.watch(branchWorkspaceSyncFreshnessProvider);
    final items = menuState.filteredItems;
    final freshness = workspaceFreshness.asData?.value;

    final categories = <MenuCategory>[
      const MenuCategory(id: 'all', name: 'All'),
      ...menuState.categories,
    ];

    final branchOptions = <DropdownMenuEntry<String>>[
      const DropdownMenuEntry<String>(value: 'all', label: 'All branches'),
      ...menuState.branches.map(
        (branch) =>
            DropdownMenuEntry<String>(value: branch.id, label: branch.name),
      ),
    ];
    const statusOptions = <DropdownMenuEntry<String>>[
      DropdownMenuEntry<String>(value: 'active', label: 'Active'),
      DropdownMenuEntry<String>(value: 'archived', label: 'Archived'),
    ];
    final selectedCategoryName = categories
        .firstWhere(
          (category) => category.id == menuState.selectedCategoryId,
          orElse: () => categories.first,
        )
        .name;
    final emptyMessage =
        menuState.selectedStatus == 'archived' &&
            menuState.selectedCategoryId != 'all'
        ? 'No archived menu items found in $selectedCategoryName.'
        : 'No menu items match your filters.';

    return Scaffold(
      body: Padding(
        padding: EdgeInsetsGeometry.only(left: 16, right: 16),
        child: Column(
          children: [
            MenuPageFilterBar(
              categories: categories,
              selectedCategoryId: menuState.selectedCategoryId,
              onCategorySelected: notifier.filterByCategory,
              branchOptions: branchOptions,
              selectedBranchId: menuState.selectedBranchId,
              onBranchSelected: notifier.filterByBranch,
              statusOptions: statusOptions,
              selectedStatus: menuState.selectedStatus,
              onStatusSelected: notifier.filterByStatus,
              onSearchChanged: notifier.searchItems,
              onAddPressed: () async {
                final result = await context.push<MenuItem>(
                  AppRoute.adminMenuItemForm.path,
                );
                if (result != null && mounted) {
                  await notifier.loadMenu();
                }
              },
            ),
            if (freshness != null) ...[
              const SizedBox(height: 12),
              SyncFreshnessBanner(freshness: freshness),
            ],
            if (menuState.isLoading && items.isNotEmpty) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 2),
            ],
            Expanded(
              child: MenuPageItemsSection(
                isLoading: menuState.isLoading,
                error: menuState.error,
                items: items,
                categories: menuState.categories,
                branches: menuState.branches,
                emptyMessage: emptyMessage,
                onItemTap: (item) => _openItemDetail(context, item),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openItemDetail(BuildContext context, MenuItem item) async {
    await context.push<MenuItem>(AppRoute.adminMenuItemForm.path, extra: item);
    if (mounted) {
      await ref.read(menuViewModelProvider.notifier).loadMenu();
    }
  }
}
