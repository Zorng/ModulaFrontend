import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/widgets/app_kebab_menu.dart';
import 'package:modular_pos/core/widgets/app_search_add_bar.dart';
import 'package:modular_pos/core/widgets/card_container.dart';
import 'package:modular_pos/core/widgets/menu_item_card.dart';
import 'package:modular_pos/core/widgets/app_category_selector.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_state.dart';

class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(menuViewModelProvider);
    final viewModel = ref.read(menuViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
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
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            AppSearchAddBar(
              searchHint: 'Search menu items...',
              onSearchChanged: viewModel.searchItems,
              onAddPressed: () {
                // TODO: Navigate to add new item page
              },
            ),
            const SizedBox(height: 24),
            AppCategorySelector(
              categories: const [
                'All', 'Coffee', 'Tea', 'Pastries', 'Juice', 'Smoothies'
              ],
              selectedCategory: state.selectedCategory,
              onCategorySelected: viewModel.filterByCategory,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _buildBody(context, state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MenuState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text('An error occurred: ${state.error}'));
    }

    return CardContainer(
      itemCount: state.filteredItems.length,
      itemBuilder: (context, index) {
        final item = state.filteredItems[index];
        return MenuItemCard(
          title: item.name,
          category: item.category,
          price: item.price,
          imagePath: item.imagePath,
          onTap: () {
            // TODO: Navigate to item details page
          },
        );
      },
    );
  }
}
