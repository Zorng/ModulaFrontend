import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/view/sale/widgets/sale_page_access_banner.dart';
import 'package:modular_pos/features/sale/ui/view/sale/widgets/sale_page_category_strip.dart';
import 'package:modular_pos/features/sale/ui/view/sale/widgets/sale_page_menu_catalog.dart';
import 'package:modular_pos/features/sale/ui/view/sale/widgets/sale_page_search_field.dart';
import 'package:modular_pos/features/sale/ui/view/sale/widgets/sale_page_state_message.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/mock_sale_data.dart';

class SalePage extends ConsumerStatefulWidget {
  const SalePage({super.key});

  @override
  ConsumerState<SalePage> createState() => _SalePageState();
}

class _SalePageState extends ConsumerState<SalePage> {
  bool _useMockData = false;

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
    final gate = ref.watch(saleAccessGateProvider);
    final cashSessionPath = AppRoute.cashSession.path;

    final width = MediaQuery.of(context).size.width;
    final isSmall = AppBreakpoints.isSmall(width);
    final isLarge = AppBreakpoints.isLarge(width);
    final gridCount = AppBreakpoints.isLarge(width)
        ? 4
        : AppBreakpoints.isMedium(width)
        ? 3
        : 2;
    final itemAspectRatio = isSmall ? 0.72 : 0.85;

    // Use mock data if enabled, otherwise use real data
    final categories = _useMockData
        ? [
            const MenuCategory(id: 'all', name: 'All'),
            ...MockSaleData.categories,
          ]
        : [const MenuCategory(id: 'all', name: 'All'), ...menuState.categories];
    final filteredItems = _useMockData
        ? MockSaleData.menuItems
        : menuState.filteredItems;

    VoidCallback retry() =>
        () => menuVm.loadMenu(
          branchId: menuState.selectedBranchId == 'all'
              ? null
              : menuState.selectedBranchId,
        );

    // Wide screen layout (menu catalog only - cart panel is handled by shell)
    if (isLarge) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sale',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Mock data toggle for testing
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _useMockData = !_useMockData),
                      icon: Icon(
                        _useMockData ? Icons.storage : Icons.cloud_off,
                      ),
                      label: Text(_useMockData ? 'Mock Data' : 'Real Data'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!gate.cashSessionLoading &&
                    gate.isBlockedByCashSessionPolicy) ...[
                  SalePageAccessBanner(cashSessionPath: cashSessionPath),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Menu',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SalePageSearchField(onChanged: menuVm.searchItems),
                const SizedBox(height: 12),
                SalePageCategoryStrip(
                  categories: categories,
                  selectedCategoryId: menuState.selectedCategoryId,
                  onSelected: menuVm.filterByCategory,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: switch ((
                    menuState.isLoading && !_useMockData,
                    menuState.error,
                  )) {
                    (true, _) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    (false, final String? error)
                        when error != null && !_useMockData =>
                      SalePageStateMessage(
                        message: UserErrorMessage.build(
                          context: 'Failed to load menu',
                          error: error,
                        ),
                        onRetry: retry(),
                      ),
                    _ when filteredItems.isEmpty => SalePageStateMessage(
                      message: 'No menu items found for this branch.',
                      onRetry: retry(),
                    ),
                    _ => RefreshIndicator(
                      onRefresh: () async => retry()(),
                      child: SalePageMenuCatalog(
                        items: filteredItems,
                        categories: _useMockData
                            ? MockSaleData.categories
                            : menuState.categories,
                        gridCount: gridCount,
                        itemAspectRatio: itemAspectRatio,
                        useMockData: _useMockData,
                      ),
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mobile/Tablet layout (original)
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!gate.cashSessionLoading &&
                            gate.isBlockedByCashSessionPolicy) ...[
                          SalePageAccessBanner(
                            cashSessionPath: cashSessionPath,
                          ),
                          const SizedBox(height: 12),
                        ],
                        SalePageSearchField(onChanged: menuVm.searchItems),
                        const SizedBox(height: 12),
                        SalePageCategoryStrip(
                          categories: categories,
                          selectedCategoryId: menuState.selectedCategoryId,
                          onSelected: menuVm.filterByCategory,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: switch ((menuState.isLoading, menuState.error)) {
                  (true, _) => const Center(child: CircularProgressIndicator()),
                  (false, final String? error) when error != null =>
                    SalePageStateMessage(
                      message: UserErrorMessage.build(
                        context: 'Failed to load menu',
                        error: error,
                      ),
                      onRetry: retry(),
                    ),
                  _ when filteredItems.isEmpty => SalePageStateMessage(
                    message: 'No menu items found for this branch.',
                    onRetry: retry(),
                  ),
                  _ => RefreshIndicator(
                    onRefresh: () async => retry()(),
                    child: SalePageMenuCatalog(
                      items: filteredItems,
                      categories: menuState.categories,
                      gridCount: gridCount,
                      itemAspectRatio: itemAspectRatio,
                    ),
                  ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
