import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/app_kebab_menu.dart';
import 'package:modular_pos/core/widgets/app_search_add_bar.dart';
import 'package:modular_pos/core/widgets/card_container.dart';
import 'package:modular_pos/core/widgets/menu_item_card.dart';
import 'package:modular_pos/core/widgets/app_category_selector.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/ui/view/categories_management_page.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form_page.dart';
import 'package:modular_pos/features/menu/ui/view/view_menu_item_page.dart';
import 'package:modular_pos/features/menu/ui/view/modifiers_management_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  // Mock data for UI display, replacing the ViewModel
  final List<MenuItem> _allItems = List.generate(
    20,
    (index) {
      final category = ['Coffee', 'Tea', 'Pastries'][index % 3];
      return MenuItem(
        id: 'item-$index',
        name: '$category Item ${index + 1}',
        category: category,
        price: 3.50 + (index * 0.25),
        imagePath: 'assets/images/latte.jpg',
      );
    },
  );
  late List<MenuItem> _filteredItems;
  String _selectedCategory = 'All';
  final List<String> _categories = const ['All', 'Coffee', 'Tea', 'Pastries'];
  // Mock data for available modifier groups
  final List<ModifierGroupInfo> _modifierGroups = [    
    ModifierGroupInfo(
      name: 'Size',
      options: [
        ModifierOption(name: 'Small', price: 2.50),
        ModifierOption(name: 'Medium', price: 3.50),
        ModifierOption(name: 'Large', price: 4.50),
      ],
    ),
    ModifierGroupInfo(
      name: 'Sugar Level',
      options: [
        ModifierOption(name: '100%'),
        ModifierOption(name: '75%'),
        ModifierOption(name: '50%'),
        ModifierOption(name: '25%'),
      ],
    ),
    ModifierGroupInfo(name: 'Toppings', options: [ModifierOption(name: 'Boba', price: 0.50)]),
    ModifierGroupInfo(name: 'Ice Level', options: [ModifierOption(name: 'Regular'), ModifierOption(name: 'Less Ice')]),
  ];

  @override
  void initState() {
    super.initState();
    _filteredItems = _allItems;
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'All') {
        _filteredItems = _allItems;
      } else {
        _filteredItems =
            _allItems.where((item) => item.category == category).toList();
      }
    });
  }

  void _searchItems(String query) {
    setState(() {
      _filteredItems = _allItems.where((item) {
        final matchesQuery = item.name.toLowerCase().contains(query.toLowerCase());
        final matchesCategory =
            _selectedCategory == 'All' || item.category == _selectedCategory;
        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Menu'),
        actions: [
          AppKebabMenu(
            items: [
              KebabMenuItem(
                  label: 'Categories Management',
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => const CategoriesManagementPage()));
                  }),
              KebabMenuItem(
                  label: 'Modifiers Management',
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => const ModifiersManagementPage()));
                  }),
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
              onSearchChanged: _searchItems,
              onAddPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return MenuItemFormPage(
                    categories: _categories,
                    modifierGroups: _modifierGroups,
                    onAdd: (newItem) {
                      setState(() {
                        _allItems.insert(0, newItem); // Add to the top of the list
                        _filterByCategory(_selectedCategory); // Re-apply current filter
                      });
                    },
                  );
                }));
              },
            ),
            const SizedBox(height: 24),
            AppCategorySelector(
              categories: _categories,
              selectedCategory: _selectedCategory,
              onCategorySelected: _filterByCategory,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: CardContainer(
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return MenuItemCard(
                    title: item.name,
                    category: item.category,
                    price: item.price,
                    imagePath: item.imagePath,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return ViewMenuItemPage(
                          menuItem: item,
                          categories: _categories,
                          modifierGroups: _modifierGroups,
                          onItemUpdated: (updatedItem) {
                            setState(() {
                              final index = _allItems.indexWhere((i) => i.id == updatedItem.id);
                              if (index != -1) {
                                _allItems[index] = updatedItem;
                                _filterByCategory(_selectedCategory);
                              }
                            });
                          },
                        );
                      }));
                    },
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
