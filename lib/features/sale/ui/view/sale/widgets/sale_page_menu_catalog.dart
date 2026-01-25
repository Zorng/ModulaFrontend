import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/logging/app_log.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/display/menu_item_card.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail/sale_item_detail_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';

class SalePageMenuCatalog extends ConsumerWidget {
  const SalePageMenuCatalog({
    super.key,
    required this.items,
    required this.categories,
    required this.gridCount,
    required this.itemAspectRatio,
  });

  final List<MenuItem> items;
  final List<MenuCategory> categories;
  final int gridCount;
  final double itemAspectRatio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const Center(child: Text('No menu items found.'));
    }

    final categoryLookup = <String, String>{
      for (final category in categories) category.id: category.name,
    };

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: itemAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final categoryName = categoryLookup[item.categoryId] ?? 'Uncategorized';
        return MenuItemCard(
          title: item.name,
          category: categoryName,
          price: item.price,
          imagePath: item.imageUrl,
          onTap: () async {
            final selection = await context.push<SaleItemSelectionResult>(
              AppRoute.saleItemDetail.path,
              extra: item,
            );
            if (selection != null && context.mounted) {
              final gate = ref.read(saleAccessGateProvider);
              if (!gate.canMutateCart) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      gate.blockingMessage ??
                          'Cash session required. Start one to begin selling.',
                    ),
                  ),
                );
                return;
              }
              try {
                await ref
                    .read(saleCartProvider.notifier)
                    .addSelection(selection);
              } catch (e, st) {
                AppLog.e('Add item failed', error: e, stackTrace: st);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      UserErrorMessage.build(
                        context: 'Failed to add item',
                        error: e,
                      ),
                    ),
                  ),
                );
              }
            }
          },
        );
      },
    );
  }
}
