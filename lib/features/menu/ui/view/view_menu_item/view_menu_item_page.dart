import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/media/product_image.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/menu/domain/models/menu_composition.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item_detail.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/view/view_menu_item/view_menu_item_utils.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

class ViewMenuItemPage extends ConsumerWidget {
  const ViewMenuItemPage({
    super.key,
    required this.menuItem,
    this.showBack = true,
  });

  final MenuItem menuItem;
  final bool showBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuState = ref.watch(menuViewModelProvider);
    final menuVm = ref.read(menuViewModelProvider.notifier);
    final inventoryState = ref.watch(stockInventoryControllerProvider);
    final detail = menuState.detailByItemId[menuItem.id];
    final detailError = menuState.detailErrorsByItemId[menuItem.id];

    if (detail == null) {
      menuVm.loadMenuItemDetail(menuItem.id);
      return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          automaticallyImplyLeading: showBack,
          leading: showBack
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
          title: Text(menuItem.name.isNotEmpty ? menuItem.name : 'Menu Item'),
        ),
        body: Center(
          child: detailError != null
              ? Text('Failed to load item details.\n$detailError')
              : const CircularProgressIndicator(),
        ),
      );
    }

    final latestItem = detail.item;
    final categoryName =
        detail.categoryName ??
        resolveCategoryName(menuState.categories, latestItem.categoryId);
    final modifiers = detail.modifierGroups;
    final branches = menuState.branches
        .where((branch) => latestItem.branchIds.contains(branch.id))
        .toList();
    final stockItems = inventoryState.stockItems.toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
    final compositionLoaded =
        menuState.compositionLoadedByItem[latestItem.id] == true;
    final compositionLoading =
        menuState.compositionLoadingByItem[latestItem.id] == true;
    final compositionError = menuState.compositionErrors[latestItem.id];

    if (!compositionLoaded && !compositionLoading) {
      menuVm.loadItemComposition(latestItem.id);
    }
    if (inventoryState.stockItems.isEmpty && !inventoryState.isLoading) {
      ref.read(stockInventoryControllerProvider.notifier).loadStockItems();
    }

    final composition = menuState.baseCompositionByItemId[latestItem.id] ??
        const <MenuComponent>[];

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        automaticallyImplyLeading: showBack,
        leading: showBack
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        title: Text(latestItem.name),
        actions: [
          TextButton(
            onPressed: () async {
              final updated = await context.push<MenuItem>(
                AppRoute.adminMenuItemForm.path,
                extra: latestItem,
              );
              if (updated != null && context.mounted) {
                await menuVm.loadMenuItemDetail(updated.id);
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
            Text(categoryName, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text(
              '\$ ${latestItem.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            _CompositionSummaryCard(
              components: composition,
              stockItems: stockItems,
              isLoading: compositionLoading,
              errorText: compositionError,
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
                        Text(
                          group.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
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
                    .map((branch) => Chip(label: Text(branch.name)))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompositionSummaryCard extends StatelessWidget {
  const _CompositionSummaryCard({
    required this.components,
    required this.stockItems,
    required this.isLoading,
    this.errorText,
  });

  final List<MenuComponent> components;
  final List<StockItem> stockItems;
  final bool isLoading;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Composition', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Base components stay on the item, and modifier options can add or remove components during evaluation.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (isLoading && components.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (errorText != null && errorText!.trim().isNotEmpty)
              Text(
                errorText!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              )
            else if (components.isEmpty)
              Text(
                'No base components configured yet.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              )
            else
              ...components.map(
                (component) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade100,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _stockItemLabel(stockItems, component.stockItemId),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Quantity: ${_formatQuantity(component.quantityInBaseUnit)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(component.trackingMode),
                          backgroundColor: component.trackingMode == 'TRACKED'
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.08)
                              : Colors.grey.shade300,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _stockItemLabel(List<StockItem> stockItems, String stockItemId) {
  for (final item in stockItems) {
    if (item.id == stockItemId) {
      final unit = item.baseUnit.toString().trim();
      return unit.isEmpty ? item.name.toString() : '${item.name} ($unit)';
    }
  }
  return 'Unknown stock item';
}

String _formatQuantity(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toString();
}
