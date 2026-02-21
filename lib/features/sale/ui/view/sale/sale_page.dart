import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/ui/view/sale/widgets/sale_page_access_banner.dart';
import 'package:modular_pos/features/sale/ui/view/sale/widgets/sale_page_category_strip.dart';
import 'package:modular_pos/features/sale/ui/view/sale/widgets/sale_page_menu_catalog.dart';
import 'package:modular_pos/features/sale/ui/view/sale/widgets/sale_page_search_field.dart';
import 'package:modular_pos/features/sale/ui/view/sale/widgets/sale_page_state_message.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/mock_sale_data.dart';

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
    final useMockData = ref.watch(useMockSaleRepositoryProvider);
    final cashSessionState = ref.watch(cashSessionViewModelProvider);
    final showCashSessionBanner =
        cashSessionState.sessionStatus != SessionStatus.open;

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
    final categories = useMockData
        ? [
            const MenuCategory(id: 'all', name: 'All'),
            ...MockSaleData.categories,
          ]
        : [const MenuCategory(id: 'all', name: 'All'), ...menuState.categories];
    final filteredItems = useMockData
        ? MockSaleData.menuItems
        : menuState.filteredItems;
    final hasMenuItems = filteredItems.isNotEmpty;

    VoidCallback retry() =>
        () => menuVm.loadMenu(
          branchId: menuState.selectedBranchId == 'all'
              ? null
              : menuState.selectedBranchId,
        );

    Widget buildHeader({required bool constrainToMaxWidth}) {
      final content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showCashSessionBanner) ...[
            const SalePageAccessBanner(
              title: 'Cash session is not open',
              message: 'Add items as normal. Open session to checkout.',
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
      );

      if (!constrainToMaxWidth) return content;
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SizedBox(width: double.infinity, child: content),
        ),
      );
    }

    // Wide screen layout (menu catalog only - cart panel is handled by shell)
    if (isLarge) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!hasMenuItems) buildHeader(constrainToMaxWidth: false),
                Expanded(
                  child: switch ((
                    menuState.isLoading && !useMockData,
                    menuState.error,
                  )) {
                    (true, _) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    (false, final String? error)
                        when error != null && !useMockData =>
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
                        header: buildHeader(constrainToMaxWidth: false),
                        items: filteredItems,
                        categories: useMockData
                            ? MockSaleData.categories
                            : menuState.categories,
                        gridCount: gridCount,
                        itemAspectRatio: itemAspectRatio,
                        useMockData: useMockData,
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
              if (!hasMenuItems) buildHeader(constrainToMaxWidth: true),
              Expanded(
                child: switch ((
                  menuState.isLoading && !useMockData,
                  menuState.error,
                )) {
                  (true, _) => const Center(child: CircularProgressIndicator()),
                  (false, final String? error)
                      when error != null && !useMockData =>
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
                      header: buildHeader(constrainToMaxWidth: true),
                      items: filteredItems,
                      categories: useMockData
                          ? MockSaleData.categories
                          : menuState.categories,
                      gridCount: gridCount,
                      itemAspectRatio: itemAspectRatio,
                      useMockData: useMockData,
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
