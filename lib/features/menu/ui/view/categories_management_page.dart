import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/app_search_add_bar.dart';
import 'package:modular_pos/features/menu/ui/view/add_category_page.dart';
import 'package:modular_pos/features/menu/ui/view/edit_category_page.dart';

/// A page for managing menu categories.
class CategoriesManagementPage extends StatefulWidget {
  const CategoriesManagementPage({super.key});

  @override
  State<CategoriesManagementPage> createState() => _CategoriesManagementPageState();
}

class CategoryInfo {
  final String name;
  final int itemCount;
  final bool isActive;

  CategoryInfo({required this.name, required this.itemCount, required this.isActive});
}

class _CategoriesManagementPageState extends State<CategoriesManagementPage> {
  // Mock data for display
  final List<CategoryInfo> _categories = [
    CategoryInfo(name: 'Coffee', itemCount: 12, isActive: true),
    CategoryInfo(name: 'Tea', itemCount: 8, isActive: true),
    CategoryInfo(name: 'Pastries', itemCount: 15, isActive: true),
    CategoryInfo(name: 'Juice', itemCount: 5, isActive: false),
    CategoryInfo(name: 'Sandwiches', itemCount: 7, isActive: true),
  ];

  @override
  Widget build(BuildContext context) {
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
              onSearchChanged: (value) {
                // TODO: Implement search logic
              },
              onAddPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return AddCategoryPage(onAdd: (newCategory) {
                    setState(() {
                      _categories.add(newCategory);
                    });
                  });
                }));
              },
            ),
            const SizedBox(height: 16),
            // --- List of Categories ---
            Expanded(
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final bool isEnabled = category.isActive;
                  final Color cardColor = isEnabled ? Colors.white : Colors.grey.shade200;

                  void navigateToEdit() {
                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                      return EditCategoryPage(
                        category: category,
                        onSave: (updatedCategory) {
                          setState(() => _categories[index] = updatedCategory);
                        },
                      );
                    }));
                  }

                  return InkWell(
                    onTap: isEnabled ? navigateToEdit : null, // Disable tap if not active
                    canRequestFocus: isEnabled, // Prevent focus if disabled
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      color: cardColor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(category.name, style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text('${category.itemCount} items', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                            Row(
                              children: [
                                Chip(
                                  label: Text(category.isActive ? 'Active' : 'Inactive'),
                                  backgroundColor: category.isActive ? Colors.green.shade100 : Colors.grey.shade300,
                                  side: BorderSide.none,
                                  labelStyle: TextStyle(
                                    color: category.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                onPressed: isEnabled ? navigateToEdit : null, // Disable button if not active
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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