import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/view/sale/widgets/sale_page_access_banner.dart';
import 'package:modular_pos/features/sale/ui/view/sale/widgets/sale_page_category_strip.dart';
import 'package:modular_pos/features/sale/ui/view/sale/widgets/sale_page_menu_catalog.dart';
import 'package:modular_pos/features/sale/ui/view/sale/widgets/sale_page_search_field.dart';
import 'package:modular_pos/features/sale/ui/view/sale/widgets/sale_page_state_message.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/sale_cart_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';

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
    final gate = ref.watch(saleAccessGateProvider);
    final role = (ref.watch(loginControllerProvider).user?.role ?? 'cashier')
        .trim()
        .toLowerCase();
    final cashSessionPath = role == 'admin'
        ? AppRoute.adminCashSession.path
        : AppRoute.cashierCashSession.path;

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
    final portalPath = role == 'admin'
        ? AppRoute.adminPortal.path
        : AppRoute.cashierPortal.path;

    VoidCallback retry() =>
        () => menuVm.loadMenu(
          branchId: menuState.selectedBranchId == 'all'
              ? null
              : menuState.selectedBranchId,
        );

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        leading: AppBackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(portalPath);
            }
          },
        ),
        title: const Text('Sale'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!gate.cashSessionLoading &&
                  gate.isBlockedByCashSessionPolicy) ...[
                SalePageAccessBanner(cashSessionPath: cashSessionPath),
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
