import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/logging/app_log.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/display/menu_item_card.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail/sale_item_detail_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';
// import 'package:modular_pos/features/sale/ui/viewmodels/mock_sale_data.dart';

class SalePageMenuCatalog extends ConsumerWidget {
  const SalePageMenuCatalog({
    super.key,
    required this.items,
    required this.categories,
    required this.gridCount,
    required this.itemAspectRatio,
    this.header,
    this.useMockData = false,
  });

  final List<MenuItem> items;
  final List<MenuCategory> categories;
  final int gridCount;
  final double itemAspectRatio;
  final Widget? header;
  final bool useMockData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const Center(child: Text('No menu items found.'));
    }

    final categoryLookup = <String, String>{
      for (final category in categories) category.id: category.name,
    };

    final width = MediaQuery.of(context).size.width;
    final isLarge = AppBreakpoints.isLarge(width);

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 2.0;
        const minTileWidth = 170.0;
        const minTileHeight = 250.0;
        final fittingColumns =
            ((constraints.maxWidth + spacing) / (minTileWidth + spacing))
                .floor();
        final effectiveGridCount = fittingColumns.clamp(1, gridCount);
        final tileWidth =
            (constraints.maxWidth - ((effectiveGridCount - 1) * spacing)) /
            effectiveGridCount;
        final tileHeight = (tileWidth / itemAspectRatio) < minTileHeight
            ? minTileHeight
            : (tileWidth / itemAspectRatio);

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (header != null) SliverToBoxAdapter(child: header),
            SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: effectiveGridCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                mainAxisExtent: tileHeight,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = items[index];
                final categoryName =
                    categoryLookup[item.categoryId] ?? 'Uncategorized';
                final card = MenuItemCard(
                  title: item.name,
                  category: categoryName,
                  price: item.price,
                  imagePath: item.imageUrl,
                  onTap: () async {
                    SaleItemSelectionResult? selection;

                    // Show modal dialog on wide screens, navigate on mobile
                    if (isLarge) {
                      selection = await showDialog<SaleItemSelectionResult>(
                        context: context,
                        builder: (context) => Dialog(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 600,
                              maxHeight: 700,
                            ),
                            child: SaleItemDetailPage(
                              item: item,
                              useMockData: useMockData,
                            ),
                          ),
                        ),
                      );
                    } else {
                      selection = await context.push<SaleItemSelectionResult>(
                        AppRoute.saleItemDetail.path,
                        extra: SaleItemDetailRouteExtra(
                          item: item,
                          useMockData: useMockData,
                        ),
                      );
                    }

                    if (selection != null && context.mounted) {
                      final gate = ref.read(saleAccessGateProvider);
                      if (!gate.canAddToCart) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              gate.blockingMessage ??
                                  'Sale action is currently blocked.',
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

                if (!isLarge) return card;

                final theme = Theme.of(context);
                final textTheme = theme.textTheme;
                final compactWideTextTheme = textTheme.copyWith(
                  titleMedium: textTheme.titleMedium?.copyWith(
                    fontSize: (textTheme.titleMedium?.fontSize ?? 16) - 4.5,
                  ),
                  titleSmall: textTheme.titleSmall?.copyWith(
                    fontSize: (textTheme.titleSmall?.fontSize ?? 14) - 1,
                  ),
                  bodySmall: textTheme.bodySmall?.copyWith(
                    fontSize: (textTheme.bodySmall?.fontSize ?? 12) - 1,
                  ),
                );

                return Theme(
                  data: theme.copyWith(textTheme: compactWideTextTheme),
                  child: card,
                );
              }, childCount: items.length),
            ),
          ],
        );
      },
    );
  }
}
