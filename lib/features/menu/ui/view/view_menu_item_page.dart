import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form_page.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

/// A page to view the details of a menu item.
class ViewMenuItemPage extends ConsumerWidget {
  const ViewMenuItemPage({super.key, required this.menuItem});

  final MenuItem menuItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuState = ref.watch(menuViewModelProvider);
    final latestItem = menuState.allItems
        .firstWhere((item) => item.id == menuItem.id, orElse: () => menuItem);
    final categoryName = _resolveCategoryName(
      menuState.categories,
      latestItem.categoryId,
    );
    final modifiers = menuState.modifierGroups
        .where((group) => latestItem.modifierGroupIds.contains(group.id))
        .toList();
    final branches = menuState.branches
        .where((branch) => latestItem.branchIds.contains(branch.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(latestItem.name),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MenuItemFormPage(initialItem: latestItem),
                ),
              );
            },
            child: const Text('Edit'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text(
              latestItem.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              categoryName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              '\$${latestItem.price.toStringAsFixed(2)}',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 24),
            Text('Modifiers', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (modifiers.isEmpty)
              Text(
                'No modifier groups assigned.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ...modifiers.map(
                (group) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        const Divider(),
                        ...group.options.map(
                          (option) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(option.name),
                                if (option.price > 0)
                                  Text(
                                    '+ \$${option.price.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey[700]),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text('Branches', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (branches.isEmpty)
              Text(
                'Not assigned to any branch.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: branches
                    .map(
                      (branch) => Chip(
                        label: Text(branch.name),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

String _resolveCategoryName(
  List<MenuCategory> categories,
  String categoryId,
) {
  for (final category in categories) {
    if (category.id == categoryId) return category.name;
  }
  return 'Unassigned category';
}
