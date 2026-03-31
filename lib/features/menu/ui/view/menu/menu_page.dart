import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/sync/sync_freshness.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/sync/sync_freshness_banner.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/ui/view/menu/widgets/menu_page_filter_bar.dart';
import 'package:modular_pos/features/menu/ui/view/menu/widgets/menu_page_items_section.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

class MenuPage extends ConsumerStatefulWidget {
  const MenuPage({super.key});

  @override
  ConsumerState<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends ConsumerState<MenuPage> {
  static const int _pageSize = 10;

  int _currentPage = 1;
  bool _accumulatePages = false;

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
    final notifier = ref.read(menuViewModelProvider.notifier);
    final workspaceFreshness = ref.watch(branchWorkspaceSyncFreshnessProvider);
    final filteredItems = menuState.filteredItems;
    final totalPages = _totalPagesFor(filteredItems);
    final currentPage = _effectiveCurrentPageFor(filteredItems);
    final items = _visibleItemsFor(filteredItems, currentPage: currentPage);
    final visibleRangeStart = _visibleRangeStartFor(
      filteredItems,
      visibleItems: items,
      currentPage: currentPage,
    );
    final visibleRangeEnd = _visibleRangeEndFor(
      filteredItems,
      visibleItems: items,
      currentPage: currentPage,
    );
    final isWideScreen = AppBreakpoints.isLarge(
      MediaQuery.of(context).size.width,
    );
    final hasPreviousPage = !_accumulatePages && currentPage > 1;
    final hasNextPage = currentPage < totalPages;
    final freshness = workspaceFreshness.asData?.value;

    final categories = <MenuCategory>[
      const MenuCategory(id: 'all', name: 'All'),
      ...menuState.categories,
    ];

    final branchOptions = <DropdownMenuEntry<String>>[
      const DropdownMenuEntry<String>(value: 'all', label: 'All branches'),
      ...menuState.branches.map(
        (branch) =>
            DropdownMenuEntry<String>(value: branch.id, label: branch.name),
      ),
    ];
    const statusOptions = <DropdownMenuEntry<String>>[
      DropdownMenuEntry<String>(value: 'active', label: 'Active'),
      DropdownMenuEntry<String>(value: 'archived', label: 'Archived'),
    ];
    final selectedCategoryName = categories
        .firstWhere(
          (category) => category.id == menuState.selectedCategoryId,
          orElse: () => categories.first,
        )
        .name;
    final emptyMessage =
        menuState.selectedStatus == 'archived' &&
            menuState.selectedCategoryId != 'all'
        ? 'No archived menu items found in $selectedCategoryName.'
        : 'No menu items match your filters.';

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          key: const ValueKey('menu-page-scroll-view'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MenuPageFilterBar(
                categories: categories,
                selectedCategoryId: menuState.selectedCategoryId,
                onCategorySelected: (categoryId) =>
                    _onCategorySelected(notifier, categoryId),
                branchOptions: branchOptions,
                selectedBranchId: menuState.selectedBranchId,
                onBranchSelected: (branchId) =>
                    _onBranchSelected(notifier, branchId),
                statusOptions: statusOptions,
                selectedStatus: menuState.selectedStatus,
                onStatusSelected: (status) =>
                    _onStatusSelected(notifier, status),
                onSearchChanged: (query) => _onSearchChanged(notifier, query),
                onAddPressed: () async {
                  final result = await context.push<MenuItem>(
                    AppRoute.adminMenuItemForm.path,
                  );
                  if (result != null && mounted) {
                    await notifier.loadMenu();
                  }
                },
              ),
              if (freshness != null) ...[
                const SizedBox(height: 12),
                SyncFreshnessBanner(freshness: freshness),
              ],
              if (menuState.isLoading && filteredItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(minHeight: 2),
              ],
              MenuPageItemsSection(
                isLoading: menuState.isLoading,
                error: menuState.error,
                items: items,
                categories: menuState.categories,
                branches: menuState.branches,
                emptyMessage: emptyMessage,
                currentPage: currentPage,
                totalPages: totalPages,
                visibleRangeStart: visibleRangeStart,
                visibleRangeEnd: visibleRangeEnd,
                hasPreviousPage: hasPreviousPage,
                hasNextPage: hasNextPage,
                useDesktopPagination: isWideScreen,
                onGoToPage: _goToPage,
                onPreviousPage: _goToPreviousPage,
                onNextPage: _goToNextPage,
                onLoadMore: _loadMoreItems,
                onItemTap: (item) => _openItemDetail(context, item),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetPagination() {
    if (!mounted) return;
    setState(() {
      _currentPage = 1;
      _accumulatePages = false;
    });
  }

  int _totalPagesFor(List<MenuItem> items) {
    if (items.isEmpty) return 1;
    return (items.length + _pageSize - 1) ~/ _pageSize;
  }

  int _effectiveCurrentPageFor(List<MenuItem> items) {
    final totalPages = _totalPagesFor(items);
    if (_currentPage < 1) return 1;
    if (_currentPage > totalPages) return totalPages;
    return _currentPage;
  }

  List<MenuItem> _visibleItemsFor(
    List<MenuItem> items, {
    required int currentPage,
  }) {
    if (items.isEmpty) return const [];
    if (_accumulatePages) {
      return items.take(currentPage * _pageSize).toList(growable: false);
    }
    final start = (currentPage - 1) * _pageSize;
    return items.skip(start).take(_pageSize).toList(growable: false);
  }

  int _visibleRangeStartFor(
    List<MenuItem> items, {
    required List<MenuItem> visibleItems,
    required int currentPage,
  }) {
    if (items.isEmpty || visibleItems.isEmpty) return 0;
    if (_accumulatePages) return 1;
    return ((currentPage - 1) * _pageSize) + 1;
  }

  int _visibleRangeEndFor(
    List<MenuItem> items, {
    required List<MenuItem> visibleItems,
    required int currentPage,
  }) {
    if (items.isEmpty || visibleItems.isEmpty) return 0;
    if (_accumulatePages) return visibleItems.length;
    final rawEnd = ((currentPage - 1) * _pageSize) + visibleItems.length;
    return rawEnd > items.length ? items.length : rawEnd;
  }

  void _goToPage(int page) {
    final totalPages = _totalPagesFor(
      ref.read(menuViewModelProvider).filteredItems,
    );
    if (page < 1 || page > totalPages) return;
    setState(() {
      _currentPage = page;
      _accumulatePages = false;
    });
  }

  void _goToNextPage() {
    final items = ref.read(menuViewModelProvider).filteredItems;
    final currentPage = _effectiveCurrentPageFor(items);
    final totalPages = _totalPagesFor(items);
    if (currentPage >= totalPages) return;
    setState(() {
      _currentPage = currentPage + 1;
      _accumulatePages = false;
    });
  }

  void _goToPreviousPage() {
    final items = ref.read(menuViewModelProvider).filteredItems;
    final currentPage = _effectiveCurrentPageFor(items);
    if (currentPage <= 1) return;
    setState(() {
      _currentPage = currentPage - 1;
      _accumulatePages = false;
    });
  }

  void _loadMoreItems() {
    final items = ref.read(menuViewModelProvider).filteredItems;
    final currentPage = _effectiveCurrentPageFor(items);
    final totalPages = _totalPagesFor(items);
    if (currentPage >= totalPages) return;
    setState(() {
      _currentPage = currentPage + 1;
      _accumulatePages = true;
    });
  }

  void _onCategorySelected(MenuViewModel notifier, String categoryId) {
    _resetPagination();
    notifier.filterByCategory(categoryId);
  }

  Future<void> _onBranchSelected(
    MenuViewModel notifier,
    String branchId,
  ) async {
    _resetPagination();
    await notifier.filterByBranch(branchId);
  }

  Future<void> _onStatusSelected(MenuViewModel notifier, String status) async {
    _resetPagination();
    await notifier.filterByStatus(status);
  }

  void _onSearchChanged(MenuViewModel notifier, String query) {
    _resetPagination();
    notifier.searchItems(query);
  }

  Future<void> _openItemDetail(BuildContext context, MenuItem item) async {
    await context.push<MenuItem>(AppRoute.adminMenuItemForm.path, extra: item);
    if (mounted) {
      await ref.read(menuViewModelProvider.notifier).loadMenu();
    }
  }
}
