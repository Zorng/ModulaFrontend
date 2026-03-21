import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/forms/app_search_add_bar.dart';
import 'package:modular_pos/core/widgets/layout/app_pagination_bar.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/domain/utils/stock_quantity_formatter.dart';
import 'package:modular_pos/features/inventory/ui/models/inventory_branch_option.dart';
import 'package:modular_pos/features/inventory/ui/models/inventory_journal_date_filter.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_home/inventory_home_filter_models.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/inventory_stock_items_utils.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_home/widgets/inventory_home_filter_section.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_home/widgets/inventory_home_filter_sheet.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/widgets/stock_item_image.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_adjust_quantity/adjust_stock_quantity_request.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_journal_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_state.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_item_card.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_stock_status_chip.dart';
import 'package:modular_pos/features/inventory/ui/widgets/stock_items_required_dialog.dart';

class InventoryHomePage extends ConsumerStatefulWidget {
  const InventoryHomePage({super.key});

  @override
  ConsumerState<InventoryHomePage> createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends ConsumerState<InventoryHomePage> {
  static const int _pageSize = 10;

  late final TextEditingController _searchController;
  Timer? _searchDebounce;
  String _searchQuery = '';
  String _categoryFilterId = 'all';
  InventoryHomeStockStatusFilter _stockStatus =
      InventoryHomeStockStatusFilter.all;

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(stockInventoryControllerProvider);
    _searchQuery = initialState.inventorySearch;
    _categoryFilterId = initialState.inventoryCategoryId.isEmpty
        ? 'all'
        : initialState.inventoryCategoryId;
    _stockStatus = inventoryHomeStockStatusFilterFromValue(
      initialState.inventoryStockLevel,
    );
    _searchController = TextEditingController(text: _searchQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(branchControllerProvider.notifier).loadInitial();
      await ref.read(categoryControllerProvider.notifier).loadCategories();
      await _reloadInventoryItems();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isLargeScreen = AppBreakpoints.isLarge(width);
    final inventoryState = ref.watch(stockInventoryControllerProvider);
    final categoryState = ref.watch(categoryControllerProvider);
    final loginState = ref.watch(loginControllerProvider);
    final activeTenantId =
        (loginState.session?.activeTenantId ??
                loginState.session?.user.tenantId)
            ?.trim() ??
        '';
    final tenantBranches = ref
        .watch(branchControllerProvider.select((state) => state.branches))
        .where(
          (branch) =>
              activeTenantId.isEmpty ||
              branch.tenantId.trim().isEmpty ||
              branch.tenantId.trim() == activeTenantId,
        )
        .toList(growable: false);
    final items = [...inventoryState.inventoryItems]
      ..sort((a, b) => a.name.compareTo(b.name));
    final selectedBranchId = inventoryState.selectedInventoryBranchId;
    final branchEntries = buildInventoryBranchOptions(
      items: items,
      tenantBranches: tenantBranches,
      userBranches: loginState.user?.branches ?? const [],
    );
    final effectiveBranchId =
        branchEntries.any((entry) => entry.id == selectedBranchId)
        ? selectedBranchId
        : 'all';
    final categoryLookup = {
      for (final c in categoryState.categories) c.id: c.name,
    };
    final categoryEntries = <DropdownMenuEntry<String>>[
      const DropdownMenuEntry<String>(value: 'all', label: 'All categories'),
      ...categoryState.categories
          .map(
            (category) => DropdownMenuEntry<String>(
              value: category.id,
              label: category.name,
            ),
          )
          .toList(growable: false)
        ..sort((a, b) => a.label.compareTo(b.label)),
    ];
    final currentBranchEntries = branchEntries
        .where((entry) => entry.id == effectiveBranchId)
        .toList(growable: false);
    final currentBranchName = currentBranchEntries.isNotEmpty
        ? currentBranchEntries.first.name
        : null;
    final inventoryScopeTextStyle = Theme.of(context).textTheme.bodyMedium;
    final inventoryScopeBranchTextStyle = inventoryScopeTextStyle?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final inventoryScopeMessage = effectiveBranchId == 'all'
        ? TextSpan(
            style: inventoryScopeTextStyle,
            children: [
              const TextSpan(text: 'Current on hand is aggregated across '),
              TextSpan(
                text: 'all branches',
                style: inventoryScopeBranchTextStyle,
              ),
              const TextSpan(text: '.'),
            ],
          )
        : TextSpan(
            style: inventoryScopeTextStyle,
            children: [
              const TextSpan(text: 'Current on hand is shown for '),
              TextSpan(
                text: currentBranchName ?? 'the selected',
                style: inventoryScopeBranchTextStyle,
              ),
              const TextSpan(text: ' branch.'),
            ],
          );
    final tableActionTextStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600);
    final viewHistoryButtonStyle = OutlinedButton.styleFrom(
      foregroundColor: AppTableTheme.actionButtonColor,
      side: const BorderSide(color: AppTableTheme.actionButtonColor),
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: tableActionTextStyle,
    );
    final hasActivePopupFilters =
        _categoryFilterId != 'all' ||
        _stockStatus != InventoryHomeStockStatusFilter.all ||
        effectiveBranchId != 'all';
    final hasActiveFilters =
        _searchQuery.trim().isNotEmpty || hasActivePopupFilters;
    final filterStatusItems = _filterStatusItems(
      categoryLookup: categoryLookup,
      branchEntries: branchEntries,
      effectiveBranchId: effectiveBranchId,
    );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text.rich(inventoryScopeMessage)),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: AppSearchAddBar(
                searchHint: 'Search inventory by name',
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                onAddPressed: () async {
                  await _openRestockFlow(
                    branchId: effectiveBranchId == 'all'
                        ? null
                        : effectiveBranchId,
                  );
                },
                addButtonLabel: 'Restock',
                addButtonMaxWidth: 132,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: InventoryHomeFilterSection(
                filterStatusItems: filterStatusItems,
                hasFiltersApplied: hasActivePopupFilters,
                onFilterPressed: () => _openFilterModal(
                  context,
                  branchEntries: branchEntries,
                  categoryEntries: categoryEntries,
                  selectedBranchId: effectiveBranchId,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
          body: isLargeScreen
              ? ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDesktopInventoryBody(
                      context: context,
                      inventoryState: inventoryState,
                      items: items,
                      hasActiveFilters: hasActiveFilters,
                      categoryLookup: categoryLookup,
                      viewHistoryButtonStyle: viewHistoryButtonStyle,
                      effectiveBranchId: effectiveBranchId,
                    ),
                  ],
                )
              : _buildMobileInventoryBody(
                  context: context,
                  inventoryState: inventoryState,
                  items: items,
                  hasActiveFilters: hasActiveFilters,
                  categoryLookup: categoryLookup,
                  effectiveBranchId: effectiveBranchId,
                ),
        ),
      ),
    );
  }

  Widget _buildMobileCenteredBody(Widget child) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(hasScrollBody: false, child: Center(child: child)),
      ],
    );
  }

  Widget _buildMobileInventoryBody({
    required BuildContext context,
    required StockInventoryState inventoryState,
    required List<StockItem> items,
    required bool hasActiveFilters,
    required Map<String, String> categoryLookup,
    required String effectiveBranchId,
  }) {
    if (inventoryState.isLoading) {
      return _buildMobileCenteredBody(const CircularProgressIndicator());
    }

    if (inventoryState.error != null) {
      return _buildMobileCenteredBody(
        Text(
          UserErrorMessage.build(
            context: 'Failed to load inventory',
            error: inventoryState.error,
          ),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (items.isEmpty) {
      return _buildMobileCenteredBody(
        _buildInventoryEmptyState(context, hasActiveFilters: hasActiveFilters),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        if (index >= items.length) {
          if (inventoryState.isLoadingMoreInventoryItems) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FilledButton(
                onPressed: _loadMoreInventoryItems,
                child: const Text('Load more'),
              ),
            ),
          );
        }
        final item = items[index];
        return InventoryItemCard(
          item: item,
          categoryLabel: categoryLabel(item, categoryLookup),
          onAdjust: () =>
              _openAdjust(item, selectedBranchId: effectiveBranchId),
          onViewHistory: () =>
              _openHistory(item, selectedBranchId: effectiveBranchId),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemCount: items.length + (inventoryState.hasNextInventoryPage ? 1 : 0),
    );
  }

  Widget _buildInventoryEmptyState(
    BuildContext context, {
    required bool hasActiveFilters,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 450),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              hasActiveFilters
                  ? 'No inventory items match your filters'
                  : 'No on-hand inventory yet',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasActiveFilters
                  ? 'Try a different branch, category, status, or search term.'
                  : 'Only items with stock appear here. Use Restock to add stock for a new item.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<InventoryHomeFilterStatusItem> _filterStatusItems({
    required Map<String, String> categoryLookup,
    required List<InventoryBranchOption> branchEntries,
    required String effectiveBranchId,
  }) {
    return [
      InventoryHomeFilterStatusItem(
        label: 'Branch',
        value: _branchLabel(branchEntries, effectiveBranchId),
        isEmphasized: effectiveBranchId != 'all',
      ),
      InventoryHomeFilterStatusItem(
        label: 'Category',
        value: _selectedCategoryLabel(categoryLookup),
        isEmphasized: _categoryFilterId != 'all',
      ),
      InventoryHomeFilterStatusItem(
        label: 'Status',
        value: inventoryHomeStockStatusFilterLabel(_stockStatus),
        isEmphasized: _stockStatus != InventoryHomeStockStatusFilter.all,
      ),
    ];
  }

  String _selectedCategoryLabel(Map<String, String> categoryLookup) {
    if (_categoryFilterId == 'all') return 'All categories';
    final label = categoryLookup[_categoryFilterId]?.trim();
    if (label != null && label.isNotEmpty) return label;
    return 'Selected category';
  }

  String _branchLabel(
    List<InventoryBranchOption> branchEntries,
    String branchId,
  ) {
    for (final entry in branchEntries) {
      if (entry.id == branchId) return entry.name;
    }
    return branchId == 'all' ? 'All branches' : branchId;
  }

  Future<void> _openFilterModal(
    BuildContext context, {
    required List<InventoryBranchOption> branchEntries,
    required List<DropdownMenuEntry<String>> categoryEntries,
    required String selectedBranchId,
  }) async {
    final draft = await showInventoryHomeFilterModal(
      context,
      branchOptions: branchEntries,
      categoryEntries: categoryEntries,
      initialDraft: InventoryHomeFilterDraft(
        categoryId: _categoryFilterId,
        branchId: selectedBranchId,
        stockStatus: _stockStatus,
      ),
    );
    if (draft == null || !mounted) return;

    setState(() {
      _categoryFilterId = draft.categoryId;
      _stockStatus = draft.stockStatus;
    });

    await _loadInventoryItemsPage(
      branchId: draft.branchId == 'all' ? null : draft.branchId,
      search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      categoryId: draft.categoryId == 'all' ? null : draft.categoryId,
      stockLevel: inventoryHomeStockStatusFilterValue(draft.stockStatus),
    );
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _reloadInventoryItems();
    });
  }

  void _openAdjust(StockItem item, {required String selectedBranchId}) {
    context.push(
      AppRoute.inventoryAdjustStock.path,
      extra: AdjustStockQuantityRequest(
        item: item,
        initialBranchId: selectedBranchId == 'all' ? null : selectedBranchId,
      ),
    );
  }

  Future<void> _openHistory(
    StockItem item, {
    required String selectedBranchId,
  }) async {
    final branchId = selectedBranchId == 'all'
        ? (item.branchId == 'all' || item.branchId.isEmpty
              ? null
              : item.branchId)
        : selectedBranchId;
    await ref
        .read(inventoryJournalControllerProvider.notifier)
        .load(
          branchId: branchId,
          stockItemId: item.id,
          dateFilter: const InventoryJournalDateFilter(
            preset: InventoryJournalDatePreset.today,
          ),
        );
    if (!mounted) return;
    context.go(AppRoute.inventoryJournal.path);
  }

  Future<void> _openRestockFlow({String? branchId}) async {
    final controller = ref.read(stockInventoryControllerProvider.notifier);

    try {
      final hasStockItems = await controller.hasStockItems();
      if (!mounted) return;

      if (!hasStockItems) {
        final openStockPage = await _showStockItemsRequiredDialog();
        if (!mounted || openStockPage != true) return;
        context.go(AppRoute.inventoryStockItems.path);
        return;
      }

      await context.push(AppRoute.inventoryRestock.path);
      if (!mounted) return;
      await _reloadInventoryItems(branchId: branchId);
    } catch (e) {
      if (!mounted) return;
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to open restock.',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapped.message)));
    }
  }

  Future<bool?> _showStockItemsRequiredDialog() {
    return showStockItemsRequiredDialog(context);
  }

  Widget _buildDesktopInventoryBody({
    required BuildContext context,
    required StockInventoryState inventoryState,
    required List<StockItem> items,
    required bool hasActiveFilters,
    required Map<String, String> categoryLookup,
    required ButtonStyle viewHistoryButtonStyle,
    required String effectiveBranchId,
  }) {
    if (inventoryState.isLoading) {
      return const SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 96),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (inventoryState.error != null) {
      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 16),
          child: Center(
            child: Text(
              UserErrorMessage.build(
                context: 'Failed to load inventory',
                error: inventoryState.error,
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 64),
          child: Center(
            child: _buildInventoryEmptyState(
              context,
              hasActiveFilters: hasActiveFilters,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableContentWidth = constraints.maxWidth < 1100
            ? 1100.0
            : constraints.maxWidth;
        final body = Container(
          decoration: BoxDecoration(
            color: AppTableTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTableTheme.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: DataTable(
                horizontalMargin: 16,
                columnSpacing: 20,
                dataRowMinHeight: 60,
                dataRowMaxHeight: 70,
                headingRowColor: WidgetStateProperty.all(
                  AppTableTheme.headerBackground,
                ),
                dataRowColor: const WidgetStatePropertyAll(
                  AppTableTheme.background,
                ),
                dividerThickness: AppTableTheme.dataTableDividerThickness,
                border: AppTableTheme.dataTableBorder,
                columns: const [
                  DataColumn(
                    label: SizedBox(
                      width: 32,
                      child: Text('No.', style: AppTableTheme.headerText),
                    ),
                  ),
                  DataColumn(
                    label: Text('Item Name', style: AppTableTheme.headerText),
                  ),
                  DataColumn(
                    label: Text('Category', style: AppTableTheme.headerText),
                  ),
                  DataColumn(
                    label: Text('Status', style: AppTableTheme.headerText),
                  ),
                  DataColumn(
                    label: Text(
                      'Current On Hand',
                      style: AppTableTheme.headerText,
                    ),
                  ),
                  DataColumn(
                    label: Text('Action', style: AppTableTheme.headerText),
                  ),
                ],
                rows: List<DataRow>.generate(items.length, (index) {
                  final item = items[index];
                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${inventoryState.inventoryVisibleRangeStart + index}',
                            style: AppTableTheme.cellText,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 260,
                          child: Row(
                            children: [
                              StockItemImage(imageUrl: item.imageUrl),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: AppTableTheme.categoryPillDecoration,
                          child: Text(
                            categoryLabel(item, categoryLookup),
                            style: AppTableTheme.categoryPillText,
                          ),
                        ),
                      ),
                      DataCell(InventoryStockStatusChip(item: item)),
                      DataCell(
                        Text(
                          StockQuantityFormatter(
                            baseQty: item.onHand,
                            pieceSize: item.pieceSize,
                            baseUnit: item.baseUnit,
                          ).format(),
                          style: AppTableTheme.cellText,
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 248,
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: viewHistoryButtonStyle,
                                  onPressed: () => _openHistory(
                                    item,
                                    selectedBranchId: effectiveBranchId,
                                  ),
                                  child: const Text('View history'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => _openAdjust(
                                    item,
                                    selectedBranchId: effectiveBranchId,
                                  ),
                                  child: const Text('Adjust'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableContentWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                body,
                if (inventoryState.inventoryTotalPages > 1) ...[
                  const SizedBox(height: 16),
                  AppPaginationBar(
                    rangeLabel:
                        'Showing ${inventoryState.inventoryVisibleRangeStart}-${inventoryState.inventoryVisibleRangeEnd} entries',
                    currentPage: inventoryState.inventoryCurrentPage,
                    totalPages: inventoryState.inventoryTotalPages,
                    canGoPrevious: inventoryState.hasPreviousInventoryPage,
                    canGoNext: inventoryState.hasNextInventoryPage,
                    isLoading: inventoryState.isInventoryPageLoading,
                    onPageSelected: _goToInventoryPage,
                    onPrevious: _goToPreviousInventoryPage,
                    onNext: _goToNextInventoryPage,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadInventoryItemsPage({
    String? branchId,
    String? search,
    String? categoryId,
    String stockLevel = 'all',
    int page = 1,
    bool accumulatePages = false,
  }) {
    return ref
        .read(stockInventoryControllerProvider.notifier)
        .loadInventoryItems(
          branchId: branchId,
          search: search,
          categoryId: categoryId,
          stockLevel: stockLevel,
          limit: _pageSize,
          page: page,
          pageTransition: page > 1 && !accumulatePages,
          accumulatePages: accumulatePages,
        );
  }

  Future<void> _reloadInventoryItems({String? branchId}) {
    final currentState = ref.read(stockInventoryControllerProvider);
    final effectiveBranchId =
        branchId ?? currentState.selectedInventoryBranchId;
    return _loadInventoryItemsPage(
      branchId: effectiveBranchId == 'all' ? null : effectiveBranchId,
      search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      categoryId: _categoryFilterId == 'all' ? null : _categoryFilterId,
      stockLevel: inventoryHomeStockStatusFilterValue(_stockStatus),
    );
  }

  Future<void> _goToInventoryPage(int page) {
    return ref
        .read(stockInventoryControllerProvider.notifier)
        .goToInventoryPage(page);
  }

  Future<void> _goToNextInventoryPage() {
    return ref
        .read(stockInventoryControllerProvider.notifier)
        .goToNextInventoryPage();
  }

  Future<void> _goToPreviousInventoryPage() {
    return ref
        .read(stockInventoryControllerProvider.notifier)
        .goToPreviousInventoryPage();
  }

  Future<void> _loadMoreInventoryItems() {
    return ref
        .read(stockInventoryControllerProvider.notifier)
        .loadMoreInventoryItems();
  }
}
