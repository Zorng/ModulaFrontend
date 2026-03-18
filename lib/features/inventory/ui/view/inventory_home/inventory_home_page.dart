import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/buttons/app_add_new_button.dart';
import 'package:modular_pos/core/widgets/forms/app_search_bar.dart';
import 'package:modular_pos/core/widgets/layout/app_pagination_bar.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/models/inventory_branch_option.dart';
import 'package:modular_pos/features/inventory/ui/models/inventory_journal_date_filter.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/inventory_stock_items_utils.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_stock_items/widgets/stock_item_image.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_adjust_quantity/adjust_stock_quantity_request.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_journal_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_state.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_item_card.dart';
import 'package:modular_pos/features/inventory/ui/widgets/stock_items_required_dialog.dart';

class InventoryHomePage extends ConsumerStatefulWidget {
  const InventoryHomePage({super.key});

  @override
  ConsumerState<InventoryHomePage> createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends ConsumerState<InventoryHomePage> {
  static const int _pageSize = 10;

  String _categoryFilter = 'All Categories';
  _StockStatus _stockStatus = _StockStatus.all;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(branchControllerProvider.notifier).loadInitial();
      await ref.read(categoryControllerProvider.notifier).loadCategories();
      await ref
          .read(stockInventoryControllerProvider.notifier)
          .loadInventoryItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    final items = inventoryState.inventoryItems;
    final selectedBranchId = inventoryState.selectedInventoryBranchId;
    final hasInventoryItems = items.isNotEmpty;
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

    final filtered = items.where((item) {
      final displayCategory = categoryLabel(item, categoryLookup);
      final matchesCategory =
          _categoryFilter == 'All Categories' ||
          displayCategory == _categoryFilter;
      final matchesSearch =
          _searchController.text.isEmpty ||
          item.name.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );
      final matchesStatus = switch (_stockStatus) {
        _StockStatus.all => true,
        _StockStatus.healthy => item.onHand > item.minThreshold,
        _StockStatus.lowStock =>
          item.onHand > 0 && item.onHand <= item.minThreshold,
        _StockStatus.outOfStock => item.onHand <= 0,
      };
      return matchesCategory && matchesSearch && matchesStatus;
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
    final categoryList = (categoryState.categories.map((c) => c.name).toList()
      ..sort());
    final categories = ['All Categories', ...categoryList];

    if (AppBreakpoints.isLarge(MediaQuery.of(context).size.width)) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final desktopFilterWidth = (availableWidth * 0.16).clamp(
                      170.0,
                      220.0,
                    );
                    const desktopButtonWidth = 132.0;
                    final button = AppAddNewButton(
                      onPressed: () async {
                        await _openRestockFlow(
                          branchId: effectiveBranchId == 'all'
                              ? null
                              : effectiveBranchId,
                        );
                      },
                      label: 'Restock',
                    );

                    final categoryFilter = InventoryDropdown<String>(
                      initialValue: _categoryFilter,
                      entries: categories
                          .map(
                            (category) => DropdownMenuEntry(
                              value: category,
                              label: category,
                            ),
                          )
                          .toList(),
                      onSelected: (value) => setState(
                        () => _categoryFilter = value ?? 'All Categories',
                      ),
                    );

                    final statusFilter = InventoryDropdown<_StockStatus>(
                      initialValue: _stockStatus,
                      entries: const [
                        DropdownMenuEntry(
                          value: _StockStatus.all,
                          label: 'All statuses',
                        ),
                        DropdownMenuEntry(
                          value: _StockStatus.healthy,
                          label: 'Healthy',
                        ),
                        DropdownMenuEntry(
                          value: _StockStatus.lowStock,
                          label: 'Low stock',
                        ),
                        DropdownMenuEntry(
                          value: _StockStatus.outOfStock,
                          label: 'Out of stock',
                        ),
                      ],
                      onSelected: (value) => setState(
                        () => _stockStatus = value ?? _StockStatus.all,
                      ),
                    );

                    final branchFilter = InventoryDropdown<String>(
                      initialValue: effectiveBranchId,
                      entries: branchEntries
                          .map(
                            (branch) => DropdownMenuEntry(
                              value: branch.id,
                              label: branch.name,
                            ),
                          )
                          .toList(),
                      onSelected: (value) {
                        final selected = value ?? 'all';
                        _loadInventoryItemsPage(
                          branchId: selected == 'all' ? null : selected,
                        );
                      },
                    );

                    return Row(
                      children: [
                        Expanded(
                          child: AppSearchBar(
                            hintText: 'Search inventory',
                            fillColor: Colors.white,
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: desktopFilterWidth,
                          child: categoryFilter,
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: desktopFilterWidth,
                          child: statusFilter,
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: desktopFilterWidth,
                          child: branchFilter,
                        ),
                        const SizedBox(width: 12),
                        SizedBox(width: desktopButtonWidth, child: button),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
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
                const SizedBox(height: 16),
                _buildDesktopInventoryBody(
                  context: context,
                  inventoryState: inventoryState,
                  hasInventoryItems: hasInventoryItems,
                  filtered: filtered,
                  categoryLookup: categoryLookup,
                  viewHistoryButtonStyle: viewHistoryButtonStyle,
                  effectiveBranchId: effectiveBranchId,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final hasNavigationRail = AppBreakpoints.isLarge(
                  MediaQuery.of(context).size.width,
                );
                final availableWidth = constraints.maxWidth;
                final contentWidth = (availableWidth - 32).clamp(
                  0.0,
                  double.infinity,
                );
                final desktopFilterWidth = (availableWidth * 0.16).clamp(
                  170.0,
                  220.0,
                );
                final desktopButtonWidth = 132.0;
                final compactButtonWidth = contentWidth < 420 ? 108.0 : 120.0;
                final button = AppAddNewButton(
                  onPressed: () async {
                    await _openRestockFlow(
                      branchId: effectiveBranchId == 'all'
                          ? null
                          : effectiveBranchId,
                    );
                  },
                  label: 'Restock',
                );

                final categoryFilter = InventoryDropdown<String>(
                  initialValue: _categoryFilter,
                  entries: categories
                      .map(
                        (category) =>
                            DropdownMenuEntry(value: category, label: category),
                      )
                      .toList(),
                  onSelected: (value) => setState(
                    () => _categoryFilter = value ?? 'All Categories',
                  ),
                );

                final statusFilter = InventoryDropdown<_StockStatus>(
                  initialValue: _stockStatus,
                  entries: const [
                    DropdownMenuEntry(
                      value: _StockStatus.all,
                      label: 'All statuses',
                    ),
                    DropdownMenuEntry(
                      value: _StockStatus.healthy,
                      label: 'Healthy',
                    ),
                    DropdownMenuEntry(
                      value: _StockStatus.lowStock,
                      label: 'Low stock',
                    ),
                    DropdownMenuEntry(
                      value: _StockStatus.outOfStock,
                      label: 'Out of stock',
                    ),
                  ],
                  onSelected: (value) =>
                      setState(() => _stockStatus = value ?? _StockStatus.all),
                );

                final branchFilter = InventoryDropdown<String>(
                  initialValue: effectiveBranchId,
                  entries: branchEntries
                      .map(
                        (branch) => DropdownMenuEntry(
                          value: branch.id,
                          label: branch.name,
                        ),
                      )
                      .toList(),
                  onSelected: (value) {
                    final selected = value ?? 'all';
                    _loadInventoryItemsPage(
                      branchId: selected == 'all' ? null : selected,
                    );
                  },
                );

                if (hasNavigationRail) {
                  return Row(
                    children: [
                      Expanded(
                        child: AppSearchBar(
                          hintText: 'Search inventory',
                          fillColor: Colors.white,
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: desktopFilterWidth,
                        child: categoryFilter,
                      ),
                      const SizedBox(width: 12),
                      SizedBox(width: desktopFilterWidth, child: statusFilter),
                      const SizedBox(width: 12),
                      SizedBox(width: desktopFilterWidth, child: branchFilter),
                      const SizedBox(width: 12),
                      SizedBox(width: desktopButtonWidth, child: button),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppSearchBar(
                            hintText: 'Search inventory',
                            fillColor: Colors.white,
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(width: compactButtonWidth, child: button),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: statusFilter),
                        const SizedBox(width: 8),
                        Expanded(child: categoryFilter),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(children: [Expanded(child: branchFilter)]),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 0,
                color: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: inventoryState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : inventoryState.error != null
                    ? Center(
                        child: Text(
                          UserErrorMessage.build(
                            context: 'Failed to load inventory',
                            error: inventoryState.error,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Theme.of(context).hintColor),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : !hasInventoryItems
                    ? Center(
                        child: ConstrainedBox(
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
                                  'No on-hand inventory yet',
                                  style: Theme.of(context).textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Only items with stock appear here. Use Restock to add stock for a new item.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context).hintColor,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final hasNavigationRail = AppBreakpoints.isLarge(
                            MediaQuery.of(context).size.width,
                          );
                          if (!hasNavigationRail) {
                            if (filtered.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _inventoryEmptyFilterMessage(
                                          hasMorePages: inventoryState
                                              .hasNextInventoryPage,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).hintColor,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (inventoryState
                                          .hasNextInventoryPage) ...[
                                        const SizedBox(height: 16),
                                        inventoryState
                                                .isLoadingMoreInventoryItems
                                            ? const CircularProgressIndicator()
                                            : FilledButton(
                                                onPressed:
                                                    _loadMoreInventoryItems,
                                                child: const Text('Load more'),
                                              ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }
                            return ListView.separated(
                              padding: EdgeInsets.zero,
                              itemBuilder: (context, index) {
                                if (index >= filtered.length) {
                                  if (inventoryState
                                      .isLoadingMoreInventoryItems) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: FilledButton(
                                        onPressed: _loadMoreInventoryItems,
                                        child: const Text('Load more'),
                                      ),
                                    ),
                                  );
                                }
                                final item = filtered[index];
                                return InventoryItemCard(
                                  item: item,
                                  categoryLabel: categoryLabel(
                                    item,
                                    categoryLookup,
                                  ),
                                  onAdjust: () => _openAdjust(
                                    item,
                                    selectedBranchId: effectiveBranchId,
                                  ),
                                  onViewHistory: () => _openHistory(
                                    item,
                                    selectedBranchId: effectiveBranchId,
                                  ),
                                );
                              },
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemCount:
                                  filtered.length +
                                  (inventoryState.hasNextInventoryPage ? 1 : 0),
                            );
                          }

                          return _buildDesktopInventoryBody(
                            context: context,
                            inventoryState: inventoryState,
                            hasInventoryItems: hasInventoryItems,
                            filtered: filtered,
                            categoryLookup: categoryLookup,
                            viewHistoryButtonStyle: viewHistoryButtonStyle,
                            effectiveBranchId: effectiveBranchId,
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
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
      await _loadInventoryItemsPage(branchId: branchId);
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
    required bool hasInventoryItems,
    required List<StockItem> filtered,
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

    if (!hasInventoryItems) {
      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 64),
          child: Center(
            child: ConstrainedBox(
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
                      'No on-hand inventory yet',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Only items with stock appear here. Use Restock to add stock for a new item.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableContentWidth = constraints.maxWidth < 980
            ? 980.0
            : constraints.maxWidth;
        final body = filtered.isEmpty
            ? Container(
                decoration: BoxDecoration(
                  color: AppTableTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTableTheme.divider),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 72,
                  horizontal: 24,
                ),
                child: Center(
                  child: Text(
                    _inventoryEmptyFilterMessage(
                      hasMorePages: inventoryState.hasNextInventoryPage,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Container(
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
                      dataRowMinHeight: 60,
                      dataRowMaxHeight: 70,
                      headingRowColor: WidgetStateProperty.all(
                        AppTableTheme.headerBackground,
                      ),
                      dataRowColor: const WidgetStatePropertyAll(
                        AppTableTheme.background,
                      ),
                      dividerThickness: 1,
                      border: const TableBorder(
                        horizontalInside: BorderSide(
                          color: AppTableTheme.divider,
                        ),
                      ),
                      columns: const [
                        DataColumn(
                          label: Text('No.', style: AppTableTheme.headerText),
                        ),
                        DataColumn(
                          label: Text(
                            'Item Name',
                            style: AppTableTheme.headerText,
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Category',
                            style: AppTableTheme.headerText,
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Current On Hand',
                            style: AppTableTheme.headerText,
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Action',
                            style: AppTableTheme.headerText,
                          ),
                        ),
                      ],
                      rows: List<DataRow>.generate(filtered.length, (index) {
                        final item = filtered[index];
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                '${inventoryState.inventoryVisibleRangeStart + index}',
                                style: AppTableTheme.cellText,
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 280,
                                child: Row(
                                  children: [
                                    StockItemImage(imageUrl: item.imageUrl),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
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
                                decoration:
                                    AppTableTheme.categoryPillDecoration,
                                child: Text(
                                  categoryLabel(item, categoryLookup),
                                  style: AppTableTheme.categoryPillText,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${item.onHand} ${item.baseUnit}',
                                style: AppTableTheme.cellText,
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 260,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: () => _openAdjust(
                                          item,
                                          selectedBranchId: effectiveBranchId,
                                        ),
                                        child: const Text('Adjust'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
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

  String _inventoryEmptyFilterMessage({required bool hasMorePages}) {
    if (hasMorePages) {
      return 'No inventory items on this page match your filters.';
    }
    return 'No inventory items match your filters.';
  }

  Future<void> _loadInventoryItemsPage({
    String? branchId,
    int page = 1,
    bool accumulatePages = false,
  }) {
    return ref
        .read(stockInventoryControllerProvider.notifier)
        .loadInventoryItems(
          branchId: branchId,
          limit: _pageSize,
          page: page,
          pageTransition: page > 1 && !accumulatePages,
          accumulatePages: accumulatePages,
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

enum _StockStatus { all, healthy, lowStock, outOfStock }
