import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/media/product_image.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/menu/ui/view/view_menu_item/view_menu_item_utils.dart';

/// A page to view the details of a menu item using only the hydrated item/modifier data.
class ViewMenuItemPage extends ConsumerWidget {
  const ViewMenuItemPage({super.key, required this.menuItem});

  final MenuItem menuItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuState = ref.watch(menuViewModelProvider);
    final menuVm = ref.read(menuViewModelProvider.notifier);
    final hydratedItem = menuState.hydratedItems[menuItem.id];
    final hydrationError = menuState.hydrationErrors[menuItem.id];

    if (hydratedItem == null) {
      // Trigger hydration if missing and show loading.
      menuVm.loadItemWithModifiers(menuItem.id);
      return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Text(
            menuItem.name.isNotEmpty ? menuItem.name : 'Menu Item',
          ),
        ),
        body: Center(
          child: hydrationError != null
              ? Text('Failed to load item details.\n$hydrationError')
              : const CircularProgressIndicator(),
        ),
      );
    }

    final latestItem = hydratedItem;
    final categoryName = resolveCategoryName(
      menuState.categories,
      latestItem.categoryId,
    );
    final modifiers = latestItem.modifierGroupIds
        .map((id) => menuState.hydratedModifierGroups[id])
        .whereType<ModifierGroup>()
        .toList();
    final branches = menuState.branches
        .where((branch) => latestItem.branchIds.contains(branch.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(latestItem.name),
        actions: [
          TextButton(
            onPressed: () async {
              final updated = await context.push<MenuItem>(
                AppRoute.adminMenuItemForm.path,
                extra: latestItem,
              );
              if (updated != null && context.mounted) {
                await menuVm.loadItemWithModifiers(updated.id);
              }
            },
            child: const Text('Edit'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            AspectRatio(
              aspectRatio: 160 / 142,
              child: ProductImage(imagePath: latestItem.imageUrl),
            ),
            const SizedBox(height: 16),
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
                  color: Colors.grey.shade100,
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
