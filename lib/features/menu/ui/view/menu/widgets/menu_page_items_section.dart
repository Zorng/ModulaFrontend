import 'package:flutter/material.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/widgets/display/menu_item_card.dart';
import 'package:modular_pos/core/widgets/layout/card_container.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/ui/view/menu/menu_page_utils.dart';

class MenuPageItemsSection extends StatelessWidget {
  const MenuPageItemsSection({
    super.key,
    required this.isLoading,
    required this.error,
    required this.items,
    required this.categories,
    required this.onItemTap,
  });

  final bool isLoading;
  final String? error;
  final List<MenuItem> items;
  final List<MenuCategory> categories;
  final ValueChanged<MenuItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Text(
          UserErrorMessage.build(context: 'Failed to load menu', error: error),
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No menu items match your filters.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return CardContainer(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final categoryName = resolveCategoryName(categories, item.categoryId);
        return MenuItemCard(
          title: item.name,
          category: categoryName,
          price: item.price,
          imagePath: item.imageUrl,
          onTap: () => onItemTap(item),
        );
      },
    );
  }
}
