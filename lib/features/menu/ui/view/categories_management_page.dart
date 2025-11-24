import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/widgets/app_search_add_bar.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/ui/view/add_category_page.dart';
import 'package:modular_pos/features/menu/ui/view/edit_category_page.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

/// A page for managing menu categories.
class CategoriesManagementPage extends ConsumerWidget {
  const CategoriesManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuState = ref.watch(menuViewModelProvider);
    final categories = menuState.categories;
    final items = menuState.allItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AppSearchAddBar(
              searchHint: 'Search categories...',
              onSearchChanged: (_) {},
              onAddPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddCategoryPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: categories.isEmpty
                  ? const Center(child: Text('No categories yet'))
                  : ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final count = items
                            .where((item) => item.categoryId == category.id)
                            .length;
                        return _CategoryTile(
                          category: category,
                          itemCount: count,
                          onTap: category.isActive
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditCategoryPage(category: category),
                                    ),
                                  )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.itemCount,
    this.onTap,
  });

  final MenuCategory category;
  final int itemCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = category.isActive;
    final cardColor = isEnabled ? Colors.white : Colors.grey.shade200;

    return InkWell(
      onTap: onTap,
      canRequestFocus: onTap != null,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('$itemCount items',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              Row(
                children: [
                  Chip(
                    label: Text(isEnabled ? 'Active' : 'Inactive'),
                    backgroundColor: isEnabled
                        ? Colors.green.shade100
                        : Colors.grey.shade300,
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: isEnabled
                          ? Colors.green.shade800
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onTap,
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
