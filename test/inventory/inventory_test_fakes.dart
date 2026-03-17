import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_state.dart';
import 'package:modular_pos/features/inventory/data/branch_stock_repository.dart';
import 'package:modular_pos/features/inventory/data/inventory_paginated_result.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/on_hand_record.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/models/inventory_journal_date_filter.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_state.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_journal_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_journal_state.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_state.dart';

const _branch = UserBranch(
  id: 'assignment-1',
  name: 'Main Branch',
  role: 'manager',
  active: true,
  branchId: 'branch-1',
);

final testUser = User(
  id: 'user-1',
  name: 'Alex Manager',
  role: 'manager',
  tenantId: 'tenant-1',
  branches: const [_branch],
);

final testSession = AuthSession(
  user: testUser,
  memberships: const <TenantMembership>[],
  activeTenantId: 'tenant-1',
  accessToken: 'token',
  refreshToken: 'refresh',
  accessTokenExpiresAt: DateTime.utc(2030, 1, 1),
  refreshTokenExpiresAt: DateTime.utc(2030, 1, 1),
);

final testCategories = <InventoryCategory>[
  const InventoryCategory(
    id: 'cat-1',
    name: 'Beverages',
    isActive: true,
    description: 'Cold drinks',
  ),
  const InventoryCategory(
    id: 'cat-2',
    name: 'Bakery',
    isActive: false,
    description: 'Fresh pastries',
  ),
];

final testStockItems = <StockItem>[
  const StockItem(
    id: 'item-1',
    name: 'Iced Coffee',
    categoryId: 'cat-1',
    baseUnit: 'ml',
    pieceSize: 1,
    branchId: 'branch-1',
    branchName: 'Main Branch',
    onHand: 12,
    minThreshold: 3,
    isActive: true,
  ),
  const StockItem(
    id: 'item-2',
    name: 'Croissant',
    categoryId: 'cat-2',
    baseUnit: 'pcs',
    pieceSize: 1,
    branchId: 'branch-1',
    branchName: 'Main Branch',
    onHand: 0,
    minThreshold: 5,
    isActive: false,
  ),
];

final testBatches = <StockBatch>[
  const StockBatch(
    id: 'batch-1',
    stockItemId: 'item-1',
    branchId: 'branch-1',
    onHand: 12,
    receivedDate: '2025-12-20',
  ),
];

final testJournalEntries = <InventoryJournalEntry>[
  InventoryJournalEntry(
    id: 'entry-1',
    itemId: 'item-1',
    itemName: 'Iced Coffee',
    branchId: 'branch-1',
    branchName: 'Main Branch',
    reason: InventoryJournalReason.restock,
    delta: 10,
    note: 'Restock recorded',
    actor: 'Alex',
    createdAt: DateTime(2025, 12, 20),
    occurredAt: DateTime(2025, 12, 20),
  ),
];

class FakeLoginController extends LoginController {
  FakeLoginController(this._state);

  final LoginState _state;

  @override
  LoginState build() => _state;
}

class FakeBranchController extends BranchController {
  FakeBranchController(this._state);

  final BranchState _state;

  @override
  BranchState build() => _state;

  @override
  Future<void> loadInitial() async {}

  @override
  Future<void> refreshBranches() async {}
}

class FakeCategoryController extends CategoryController {
  FakeCategoryController(this._state);

  final CategoryState _state;

  @override
  CategoryState build() => _state;

  @override
  Future<void> loadCategories({String status = 'all'}) async {}

  @override
  Future<void> addCategory(
    String name, {
    String? description,
    bool isActive = true,
  }) async {}

  @override
  Future<void> updateCategory(InventoryCategory category) async {}

  @override
  Future<void> deleteCategory(String id) async {}
}

class FakeStockInventoryController extends StockInventoryController {
  FakeStockInventoryController(
    this._state, {
    this.onGoToStockItemsPage,
    this.onGoToNextStockItemsPage,
    this.onGoToPreviousStockItemsPage,
    this.onLoadMoreStockItems,
  });

  final StockInventoryState _state;
  final ValueChanged<int>? onGoToStockItemsPage;
  final VoidCallback? onGoToNextStockItemsPage;
  final VoidCallback? onGoToPreviousStockItemsPage;
  final VoidCallback? onLoadMoreStockItems;

  @override
  StockInventoryState build() => _state;

  @override
  Future<void> loadStockItems({String status = 'all'}) async {}

  @override
  Future<void> loadStockItemsPage({
    String status = 'all',
    String? search,
    String? categoryId,
    int limit = 10,
    int page = 1,
    bool pageTransition = false,
    bool accumulatePages = false,
  }) async {}

  @override
  Future<void> goToStockItemsPage(int page) async {
    onGoToStockItemsPage?.call(page);
  }

  @override
  Future<void> goToNextStockItemsPage() async {
    onGoToNextStockItemsPage?.call();
  }

  @override
  Future<void> goToPreviousStockItemsPage() async {
    onGoToPreviousStockItemsPage?.call();
  }

  @override
  Future<void> loadMoreStockItems() async {
    onLoadMoreStockItems?.call();
  }

  @override
  Future<void> loadInventoryItems({
    String? branchId,
    String status = 'all',
  }) async {}

  @override
  Future<StockItem> loadStockItemDetail(String id) async {
    return [
      ..._state.stockItems,
      ..._state.inventoryItems,
    ].firstWhere((item) => item.id == id);
  }

  @override
  Future<StockItem> addStockItem(
    StockItem draft, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    return draft;
  }

  @override
  Future<StockItem> updateStockItem(
    StockItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    return item;
  }

  @override
  Future<void> createRestockBatch({
    required String itemId,
    required int baseQty,
    String? restockDate,
    String? expiryDate,
    String? supplierName,
    num? purchaseCostUsd,
    String? note,
    String? branchId,
  }) async {}

  @override
  Future<void> archiveStockItem(String id) async {}

  @override
  Future<void> restoreStockItem(String id) async {}

  @override
  Future<void> applyInventoryAdjustment({
    required String stockItemId,
    String? batchId,
    String? branchId,
    String style = 'DELTA',
    int? delta,
    int? countedOnHandInBaseUnit,
    String? note,
  }) async {}
}

class FakeInventoryJournalController extends InventoryJournalController {
  FakeInventoryJournalController(
    this._state, {
    this.onGoToPage,
    this.onGoToNextPage,
    this.onGoToPreviousPage,
    this.onLoadNextChunk,
  });

  final InventoryJournalState _state;
  final ValueChanged<int>? onGoToPage;
  final VoidCallback? onGoToNextPage;
  final VoidCallback? onGoToPreviousPage;
  final VoidCallback? onLoadNextChunk;

  @override
  InventoryJournalState build() => _state;

  @override
  Future<void> load({
    String? branchId,
    String? stockItemId,
    InventoryJournalReason? reason,
    InventoryJournalDateFilter? dateFilter,
    int limit = 10,
    int page = 1,
    bool pageTransition = false,
    bool accumulatePages = false,
  }) async {}

  @override
  Future<void> goToPage(
    int page, {
    String? branchId,
    String? stockItemId,
    InventoryJournalReason? reason,
  }) async {
    onGoToPage?.call(page);
  }

  @override
  Future<void> goToNextPage({
    String? branchId,
    String? stockItemId,
    InventoryJournalReason? reason,
  }) async {
    onGoToNextPage?.call();
  }

  @override
  Future<void> goToPreviousPage({
    String? branchId,
    String? stockItemId,
    InventoryJournalReason? reason,
  }) async {
    onGoToPreviousPage?.call();
  }

  @override
  Future<void> loadNextChunk({
    String? branchId,
    String? stockItemId,
    InventoryJournalReason? reason,
  }) async {
    onLoadNextChunk?.call();
  }
}

class FakeStockItemRepository extends StockItemRepository {
  FakeStockItemRepository(this._items);

  final List<StockItem> _items;

  @override
  Future<InventoryPaginatedResult<StockItem>> fetchMasterStockItems({
    String status = 'all',
    String? search,
    String? categoryId,
    int pageSize = 200,
    int offset = 0,
  }) async {
    final normalizedStatus = status.trim().toLowerCase();
    final normalizedSearch = search?.trim().toLowerCase() ?? '';
    final normalizedCategoryId = categoryId?.trim() ?? '';
    final filtered = _items
        .where((item) {
          final matchesStatus = switch (normalizedStatus) {
            'active' => item.isActive,
            'archived' => !item.isActive,
            _ => true,
          };
          final matchesSearch =
              normalizedSearch.isEmpty ||
              item.name.toLowerCase().contains(normalizedSearch);
          final matchesCategory =
              normalizedCategoryId.isEmpty ||
              item.categoryId == normalizedCategoryId;
          return matchesStatus && matchesSearch && matchesCategory;
        })
        .toList(growable: false);
    final safeOffset = offset.clamp(0, filtered.length);
    final end = (safeOffset + pageSize).clamp(0, filtered.length);
    final items = filtered.sublist(safeOffset, end);
    return InventoryPaginatedResult<StockItem>(
      items: items,
      limit: pageSize,
      offset: safeOffset,
      total: filtered.length,
      hasMore: end < filtered.length,
    );
  }

  @override
  Future<StockItem> fetchStockItemById(String id) async {
    final match = _items.where((item) => item.id == id);
    if (match.isNotEmpty) return match.first;
    throw StateError('Stock item not found: $id');
  }

  @override
  Future<StockItem> createStockItem(
    StockItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    return item;
  }

  @override
  Future<StockItem> updateStockItem(
    StockItem item, {
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    return item;
  }

  @override
  Future<void> archiveStockItem(String id) async {}

  @override
  Future<void> restoreStockItem(String id) async {}
}

class FakeBranchStockRepository extends BranchStockRepository {
  FakeBranchStockRepository(this._items);

  final List<StockItem> _items;

  @override
  Future<List<OnHandRecord>> fetchOnHand({
    String? branchId,
    String status = 'all',
  }) async {
    return _items
        .where(
          (item) =>
              branchId == null || branchId.isEmpty || item.branchId == branchId,
        )
        .map(
          (item) => OnHandRecord(
            stockItemId: item.id,
            branchId: item.branchId,
            onHand: item.onHand,
            minThreshold: item.minThreshold,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<StockItem>> fetchStockItems({
    String? branchId,
    String status = 'all',
  }) async {
    final filteredByStatus = _items.where((item) {
      switch (status.trim().toLowerCase()) {
        case 'active':
          return item.isActive;
        case 'archived':
          return !item.isActive;
        case 'all':
        default:
          return true;
      }
    });
    if (branchId == null || branchId.isEmpty) {
      return filteredByStatus.toList(growable: false);
    }
    return filteredByStatus
        .where((item) => item.branchId == branchId)
        .toList(growable: false);
  }

  @override
  Future<void> assignToBranch({
    required String stockItemId,
    required String branchId,
    required int minThreshold,
  }) async {}
}

List<Override> inventoryOverrides({
  LoginState? loginState,
  BranchState? branchState,
  CategoryState? categoryState,
  StockInventoryState? stockInventoryState,
  StockInventoryController? stockInventoryController,
  List<InventoryJournalEntry>? journalEntries,
  InventoryJournalState? journalState,
  InventoryJournalController? inventoryJournalController,
  StockItemRepository? stockItemRepository,
  BranchStockRepository? branchStockRepository,
}) {
  return [
    loginControllerProvider.overrideWith(
      () => FakeLoginController(loginState ?? LoginState(session: testSession)),
    ),
    branchControllerProvider.overrideWith(
      () => FakeBranchController(
        branchState ??
            const BranchState(
              branches: <BranchListItem>[
                BranchListItem(
                  branchId: 'branch-1',
                  tenantId: 'tenant-1',
                  branchName: 'Main Branch',
                  status: 'ACTIVE',
                ),
              ],
            ),
      ),
    ),
    categoryControllerProvider.overrideWith(
      () => FakeCategoryController(
        categoryState ?? CategoryState(categories: testCategories),
      ),
    ),
    stockInventoryControllerProvider.overrideWith(
      () =>
          stockInventoryController ??
          FakeStockInventoryController(
            stockInventoryState ??
                StockInventoryState(
                  inventoryItems: testStockItems,
                  stockItems: testStockItems,
                  batches: testBatches,
                ),
          ),
    ),
    inventoryJournalControllerProvider.overrideWith(
      () =>
          inventoryJournalController ??
          FakeInventoryJournalController(
            journalState ??
                InventoryJournalState(
                  entries: journalEntries ?? testJournalEntries,
                ),
          ),
    ),
    if (stockItemRepository != null)
      stockItemRepositoryProvider.overrideWithValue(stockItemRepository),
    if (branchStockRepository != null)
      branchStockRepositoryProvider.overrideWithValue(branchStockRepository),
  ];
}
