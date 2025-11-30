import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/widgets/app_category_selector.dart';
import 'package:modular_pos/core/widgets/app_kebab_menu.dart';
import 'package:modular_pos/core/widgets/app_search_add_bar.dart';
import 'package:modular_pos/core/widgets/card_container.dart';
import 'package:modular_pos/core/widgets/menu_item_card.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/ui/view/categories_management_page.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form_page.dart';
import 'package:modular_pos/features/menu/ui/view/modifiers_management_page.dart';
import 'package:modular_pos/features/menu/ui/view/view_menu_item_page.dart';
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
    final List<_CategoryChip> categories = [
      _CategoryChip(id: 'all', label: 'All'),
      ...menuState.categories
          .map((c) => _CategoryChip(id: c.id, label: c.name)),
    ];
    final selectedChip = categories.firstWhere(
      (chip) => chip.id == menuState.selectedCategoryId,
      orElse: () => categories.first,
    );

    final items = menuState.filteredItems;
    final branchOptions = [
      const _BranchOption(id: 'all', label: 'All branches'),
      ...menuState.branches
          .map((branch) => _BranchOption(id: branch.id, label: branch.name)),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        centerTitle: false,
        title: const Text('Menu'),
        actions: [
          AppKebabMenu(
            items: [
              KebabMenuItem(
                label: 'Categories Management',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoriesManagementPage(),
                    ),
                  );
                },
              ),
              KebabMenuItem(
                label: 'Modifiers Management',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ModifiersManagementPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            AppSearchAddBar(
              searchHint: 'Search menu items...',
              onSearchChanged: ref
                  .read(menuViewModelProvider.notifier)
                  .searchItems,
              onAddPressed: () async {
                final result = await Navigator.push<MenuItem>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MenuItemFormPage(),
                  ),
                );
                if (result != null && mounted) {
                  await ref.read(menuViewModelProvider.notifier).loadMenu();
                }
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: DropdownMenu<String>(
                width: double.infinity,
                initialSelection: menuState.selectedBranchId,
                leadingIcon: const Icon(Icons.store_outlined),
                label: const Text('Branch'),
                dropdownMenuEntries: branchOptions
                    .map(
                      (option) => DropdownMenuEntry<String>(
                        value: option.id,
                        label: option.label,
                      ),
                    )
                    .toList(),
                onSelected: (value) {
                  if (value == null) return;
                  ref
                      .read(menuViewModelProvider.notifier)
                      .filterByBranch(value);
                },
              ),
            ),
            const SizedBox(height: 24),
            AppCategorySelector(
              categories: categories.map((c) => c.label).toList(),
              selectedCategory: selectedChip.label,
              onCategorySelected: (label) {
                final chip =
                    categories.firstWhere((element) => element.label == label);
                ref
                    .read(menuViewModelProvider.notifier)
                    .filterByCategory(chip.id);
              },
            ),
            const SizedBox(height: 24),
            if (menuState.isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (menuState.error != null)
              Expanded(
                child: Center(
                  child: Text(menuState.error!,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              )
            else if (items.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No menu items match your filters.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              Expanded(
                child: CardContainer(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final categoryName = _resolveCategoryName(
                      menuState.categories,
                      item.categoryId,
                    );
                    return MenuItemCard(
                      title: item.name,
                      category: categoryName,
                      price: item.price,
                      imagePath: item.imageUrl,
                      onTap: () => _openItemDetail(context, item),
                    );
                  },
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
      MaterialPageRoute(
        builder: (context) => ViewMenuItemPage(menuItem: item),
      ),
    );
    if (mounted) {
      await ref.read(menuViewModelProvider.notifier).loadMenu();
    }
  }
}

class _CategoryChip {
  const _CategoryChip({required this.id, required this.label});
  final String id;
  final String label;
}

class _BranchOption {
  const _BranchOption({required this.id, required this.label});
  final String id;
  final String label;
}

String _resolveCategoryName(List<MenuCategory> categories, String categoryId) {
  for (final category in categories) {
    if (category.id == categoryId) {
      return category.name;
    }
  }
  return 'Unassigned';
}
