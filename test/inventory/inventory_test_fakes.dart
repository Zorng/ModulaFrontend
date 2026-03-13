import 'package:flutter_riverpod/misc.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/inventory/data/branch_stock_repository.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/on_hand_record.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
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
  FakeStockInventoryController(this._state);

  final StockInventoryState _state;

  @override
  StockInventoryState build() => _state;

  @override
  Future<void> loadStockItems({String status = 'all'}) async {}

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
    String style = 'DELTA',
    int? delta,
    int? countedOnHandInBaseUnit,
    String? note,
  }) async {}
}

class FakeInventoryJournalController extends InventoryJournalController {
  FakeInventoryJournalController(this._state);

  final InventoryJournalState _state;

  @override
  InventoryJournalState build() => _state;

  @override
  Future<void> load({
    String? branchId,
    String? stockItemId,
    InventoryJournalReason? reason,
    int limit = 50,
    int offset = 0,
    bool append = false,
  }) async {}
}

class FakeStockItemRepository extends StockItemRepository {
  FakeStockItemRepository(this._items);

  final List<StockItem> _items;

  @override
  Future<List<StockItem>> fetchMasterStockItems({int pageSize = 200}) async {
    return _items.take(pageSize).toList(growable: false);
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
  CategoryState? categoryState,
  StockInventoryState? stockInventoryState,
  List<InventoryJournalEntry>? journalEntries,
  InventoryJournalState? journalState,
  StockItemRepository? stockItemRepository,
  BranchStockRepository? branchStockRepository,
}) {
  return [
    loginControllerProvider.overrideWith(
      () => FakeLoginController(loginState ?? LoginState(session: testSession)),
    ),
    categoryControllerProvider.overrideWith(
      () => FakeCategoryController(
        categoryState ?? CategoryState(categories: testCategories),
      ),
    ),
    stockInventoryControllerProvider.overrideWith(
      () => FakeStockInventoryController(
        stockInventoryState ??
            StockInventoryState(
              inventoryItems: testStockItems,
              stockItems: testStockItems,
              batches: testBatches,
            ),
      ),
    ),
    inventoryJournalControllerProvider.overrideWith(
      () => FakeInventoryJournalController(
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
