import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/ui/view/menu/widgets/menu_page_actions_menu.dart';
import 'package:modular_pos/features/menu/ui/view/menu/widgets/menu_page_filter_bar.dart';
import 'package:modular_pos/features/menu/ui/view/menu/widgets/menu_page_items_section.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form/menu_item_form_page.dart';
import 'package:modular_pos/features/menu/ui/view/view_menu_item/view_menu_item_page.dart';
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
    final items = menuState.filteredItems;

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

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        centerTitle: false,
        title: const Text('Menu'),
        actions: const [MenuPageActionsMenu()],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: Column(
          children: [
            MenuPageFilterBar(
              categories: categories,
              selectedCategoryId: menuState.selectedCategoryId,
              onCategorySelected: notifier.filterByCategory,
              branchOptions: branchOptions,
              selectedBranchId: menuState.selectedBranchId,
              onBranchSelected: notifier.filterByBranch,
              onSearchChanged: notifier.searchItems,
              onAddPressed: () async {
                final result = await Navigator.push<MenuItem>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MenuItemFormPage(),
                  ),
                );
                if (result != null && mounted) {
                  await notifier.loadMenu();
                }
              },
            ),
            Expanded(
              child: MenuPageItemsSection(
                isLoading: menuState.isLoading,
                error: menuState.error,
                items: items,
                categories: menuState.categories,
                onItemTap: (item) => _openItemDetail(context, item),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openItemDetail(BuildContext context, MenuItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ViewMenuItemPage(menuItem: item)),
    );
    if (mounted) {
      await ref.read(menuViewModelProvider.notifier).loadMenu();
    }
  }
}
