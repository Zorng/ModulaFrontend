import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/core/widgets/forms/app_search_add_bar.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/menu/ui/view/categories_management/widgets/category_tile.dart';
import 'package:modular_pos/features/menu/ui/view/categories_management/widgets/edit_category_sheet.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

/// A page for managing menu categories.
class CategoriesManagementPage extends ConsumerStatefulWidget {
  const CategoriesManagementPage({super.key});

  @override
  ConsumerState<CategoriesManagementPage> createState() =>
      _CategoriesManagementPageState();
}

class _CategoriesManagementPageState
    extends ConsumerState<CategoriesManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(menuViewModelProvider.notifier).refreshCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuViewModelProvider);
    final categories = menuState.categories;
    final items = menuState.allItems;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AppSearchAddBar(
              searchHint: 'Search categories...',
              onSearchChanged: (_) {},
              addButtonLabel: 'Add category',
              onAddPressed: () {
                context.push(AppRoute.adminMenuAddCategory.path);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: menuState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : categories.isEmpty
                      ? const Center(child: Text('No categories yet'))
                      : ListView.builder(
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final count = items
                                .where((item) => item.categoryId == category.id)
                                .length;
                            return CategoryTile(
                              category: category,
                              itemCount: count,
                              onTap: () => _openCategorySheet(context, category),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCategorySheet(
      BuildContext context, MenuCategory category) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: EditCategorySheet(category: category),
        );
      },
    );
  }
}
