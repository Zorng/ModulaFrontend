import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/menu_item_card.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart_page.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';

class SalePage extends ConsumerStatefulWidget {
  const SalePage({super.key});

  @override
  ConsumerState<SalePage> createState() => _SalePageState();
}

class _SalePageState extends ConsumerState<SalePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(menuViewModelProvider.notifier).loadMenu();
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuViewModelProvider);
    final menuVm = ref.read(menuViewModelProvider.notifier);

    final width = MediaQuery.of(context).size.width;
    final isSmall = AppBreakpoints.isSmall(width);
    final gridCount = AppBreakpoints.isLarge(width)
        ? 4
        : AppBreakpoints.isMedium(width)
            ? 3
            : 2;
    final itemAspectRatio = isSmall ? 0.72 : 0.85;
    final categories = [
      const MenuCategory(id: 'all', name: 'All'),
      ...menuState.categories,
    ];
    final filteredItems = menuState.filteredItems;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Sale'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SearchField(
                onChanged: menuVm.searchItems,
              ),
              const SizedBox(height: 12),
              _CategoryStrip(
                categories: categories,
                selectedCategoryId: menuState.selectedCategoryId,
                onSelected: menuVm.filterByCategory,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: switch ((menuState.isLoading, menuState.error)) {
                  (true, _) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  (false, final String? error) when error != null => _ErrorState(
                      message: error,
                      onRetry: () => menuVm.loadMenu(
                        branchId: menuState.selectedBranchId == 'all'
                            ? null
                            : menuState.selectedBranchId,
                      ),
                    ),
                  _ => RefreshIndicator(
                      onRefresh: () => menuVm.loadMenu(
                        branchId: menuState.selectedBranchId == 'all'
                            ? null
                            : menuState.selectedBranchId,
                      ),
                      child: _MenuCatalog(
                        items: filteredItems,
                        categories: menuState.categories,
                        gridCount: gridCount,
                        itemAspectRatio: itemAspectRatio,
                        ref: ref,
                      ),
                    ),
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 12, bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SaleCartPage()),
            );
          },
          icon: const Icon(Icons.shopping_cart_outlined),
          label: const Text('Cart'),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search menu items',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<MenuCategory> categories;
  final String selectedCategoryId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(category.name),
                selected: category.id == selectedCategoryId,
                onSelected: (_) => onSelected(category.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuCatalog extends StatelessWidget {
  const _MenuCatalog({
    required this.items,
    required this.categories,
    required this.gridCount,
    required this.itemAspectRatio,
    required this.ref,
  });

  final List<MenuItem> items;
  final List<MenuCategory> categories;
  final int gridCount;
  final double itemAspectRatio;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No menu items found.'),
      );
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
        final categoryName =
            categoryLookup[item.categoryId] ?? 'Uncategorized';
        return MenuItemCard(
          title: item.name,
          category: categoryName,
          price: item.price,
          imagePath: item.imageUrl,
          onTap: () async {
            final selection = await Navigator.push<SaleItemSelectionResult>(
              context,
              MaterialPageRoute(
                builder: (_) => SaleItemDetailPage(
                  item: item,
                ),
              ),
            );
            if (selection != null && context.mounted) {
              try {
                await ref.read(saleCartProvider.notifier).addSelection(selection);
              } catch (e, st) {
                if (kDebugMode) {
                  debugPrint('Add item failed: $e');
                  debugPrintStack(stackTrace: st);
                }
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to add item: $e')),
                );
              }
            }
          },
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
