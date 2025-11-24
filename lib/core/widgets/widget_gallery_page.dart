import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/app_category_selector.dart';
import 'package:modular_pos/core/widgets/app_kebab_menu.dart';
import 'package:modular_pos/core/widgets/app_search_add_bar.dart';
import 'package:modular_pos/core/widgets/card_container.dart';
import 'package:modular_pos/core/widgets/menu_item_card.dart';

class WidgetGalleryPage extends StatelessWidget {
  const WidgetGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Gallery'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          // Use a key to help Flutter identify the ListView
          // when hot reloading, especially with nested scaffolds.
          key: const PageStorageKey('widget_gallery_list'),
          children: [
            const SizedBox(height: 16),
            // --- MENU PAGE LAYOUT EXAMPLE ---
            SizedBox(
              // Constrain the height of the nested Scaffold example
              height: 600,
              child: Scaffold(
                appBar: AppBar(
                  // The back button will appear automatically if this
                  // page is pushed onto the navigation stack.
                  // For this gallery, we add it manually.
                  leading: const BackButton(),
                  title: const Text('Menu'),
                  actions: [
                    AppKebabMenu(
                      items: [
                        KebabMenuItem(label: 'Categories Management', onTap: () {}),
                        KebabMenuItem(label: 'Modifiers Management', onTap: () {}),
                      ],
                    ),
                  ],
                ),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // --- Top Action Bar ---
                      SizedBox(
                        height: 58,
                        child: AppSearchAddBar(
                          searchHint: 'Search...',
                          onSearchChanged: (val) {},
                          onAddPressed: () {},
                        ),
                      ),
                      const SizedBox(height: 16),
                      // --- Category Selector ---
                      AppCategorySelector(
                        categories: const [
                          'All',
                          'Coffee',
                          'Tea',
                          'Pastries',
                          'Juice',
                          'Smoothies',
                          'Sandwiches',
                        ],
                        onCategorySelected: (category) {
                          // This callback can be used to filter items.
                        },
                      ),
                      const SizedBox(height: 16),
                      // --- Responsive Grid of Menu Items ---
                      Expanded(
                        child: CardContainer(
                          itemCount: 12,
                          itemBuilder: (context, index) {
                            return MenuItemCard(
                              title: 'Iced Latte ${index + 1}',
                              category: 'Coffee',
                              price: 4.50,
                              imagePath: 'assets/images/latte.jpg',
                              onTap: () {},
                            );
                          },
                        ),
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
