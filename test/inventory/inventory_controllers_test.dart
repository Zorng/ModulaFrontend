import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/inventory/data/branch_stock_repository.dart';
import 'package:modular_pos/features/inventory/data/inventory_category_repository.dart';
import 'package:modular_pos/features/inventory/data/inventory_journal_repository.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_state.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_journal_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_state.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

import '../test_utils/riverpod_test_utils.dart';
import 'inventory_test_fakes.dart';

class _MockCategoryRepository extends Mock
    implements InventoryCategoryRepository {}

class _MockStockItemRepository extends Mock implements StockItemRepository {}

class _MockBranchStockRepository extends Mock
    implements BranchStockRepository {}

class _MockJournalRepository extends Mock
    implements InventoryJournalRepository {}

class _SpyStockInventoryController extends StockInventoryController {
  bool loadCalled = false;

  @override
  StockInventoryState build() => const StockInventoryState();

  @override
  Future<void> loadStockItems({String? branchId, String status = 'all'}) async {
    loadCalled = true;
  }
}

class _MockInventoryJournalRepository extends Mock
    implements InventoryJournalRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const InventoryCategory(id: 'fallback', name: 'Fallback', isActive: true),
    );
    registerFallbackValue(
      const StockItem(
        id: 'fallback-item',
        name: 'Fallback Item',
        baseUnit: 'pcs',
        pieceSize: 1,
        branchId: '',
        branchName: '',
        onHand: 0,
        minThreshold: 0,
        isActive: true,
      ),
    );
  });

  test('CategoryController.loadCategories updates state', () async {
    final repo = _MockCategoryRepository();
    when(() => repo.fetchCategories()).thenAnswer(
      (_) async => const [
        InventoryCategory(id: 'cat-1', name: 'Beverages', isActive: true),
      ],
    );

    final container = createTestContainer(
      overrides: [inventoryCategoryRepositoryProvider.overrideWithValue(repo)],
    );

    final notifier = container.read(categoryControllerProvider.notifier);
    await notifier.loadCategories();

    final state = container.read(categoryControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.categories, hasLength(1));
  });

  test(
    'CategoryController.updateCategory triggers inventory refresh',
    () async {
      final repo = _MockCategoryRepository();
      final spy = _SpyStockInventoryController();
      const category = InventoryCategory(
        id: 'cat-1',
        name: 'Beverages',
        isActive: true,
      );
      const updated = InventoryCategory(
        id: 'cat-1',
        name: 'Beverages',
        isActive: false,
      );

      when(() => repo.updateCategory(any())).thenAnswer((_) async => updated);

      final container = createTestContainer(
        overrides: [
          inventoryCategoryRepositoryProvider.overrideWithValue(repo),
          stockInventoryControllerProvider.overrideWith(() => spy),
        ],
      );

      final notifier = container.read(categoryControllerProvider.notifier);
      notifier.state = const CategoryState(categories: [category]);
      await notifier.updateCategory(updated);

      final state = container.read(categoryControllerProvider);
      expect(state.categories.first.isActive, isFalse);
      expect(spy.loadCalled, isTrue);
    },
  );

  test(
    'StockInventoryController.loadStockItems maps category labels',
    () async {
      final stockRepo = _MockStockItemRepository();
      final branchStockRepo = _MockBranchStockRepository();
      final journalRepo = _MockJournalRepository();

      when(
        () => branchStockRepo.fetchStockItems(
          branchId: any(named: 'branchId'),
          status: any(named: 'status'),
        ),
      ).thenAnswer(
        (_) async => const [
          StockItem(
            id: 'item-1',
            name: 'Iced Coffee',
            categoryId: 'cat-1',
            baseUnit: 'ml',
            pieceSize: 1,
            branchId: 'branch-1',
            branchName: '',
            onHand: 10,
            minThreshold: 2,
            isActive: true,
          ),
        ],
      );
      when(
        () => branchStockRepo.fetchOnHand(
          branchId: any(named: 'branchId'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => const []);

      final container = createTestContainer(
        overrides: [
          stockItemRepositoryProvider.overrideWithValue(stockRepo),
          branchStockRepositoryProvider.overrideWithValue(branchStockRepo),
          inventoryJournalRepositoryProvider.overrideWithValue(journalRepo),
          loginControllerProvider.overrideWith(
            () => FakeLoginController(LoginState(session: testSession)),
          ),
          categoryControllerProvider.overrideWith(
            () => FakeCategoryController(
              const CategoryState(
                categories: [
                  InventoryCategory(
                    id: 'cat-1',
                    name: 'Beverages',
                    isActive: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      );

      final notifier = container.read(
        stockInventoryControllerProvider.notifier,
      );
      await notifier.loadStockItems(branchId: 'branch-1');

      final state = container.read(stockInventoryControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.items.first.categoryId, 'cat-1');
    },
  );

  test(
    'StockInventoryController.loadStockItems falls back to master list when branch stock read fails',
    () async {
      final stockRepo = _MockStockItemRepository();
      final branchStockRepo = _MockBranchStockRepository();
      final journalRepo = _MockJournalRepository();

      when(
        () => branchStockRepo.fetchStockItems(
          branchId: any(named: 'branchId'),
          status: any(named: 'status'),
        ),
      ).thenThrow(
        const ApiClientException(
          message: 'Branch context is missing',
          code: 'BRANCH_CONTEXT_REQUIRED',
          statusCode: 403,
        ),
      );
      when(
        () => branchStockRepo.fetchOnHand(
          branchId: any(named: 'branchId'),
          status: any(named: 'status'),
        ),
      ).thenThrow(
        const ApiClientException(
          message: 'Branch context is missing',
          code: 'BRANCH_CONTEXT_REQUIRED',
          statusCode: 403,
        ),
      );
      when(
        () => stockRepo.fetchMasterStockItems(pageSize: any(named: 'pageSize')),
      ).thenAnswer(
        (_) async => const [
          StockItem(
            id: 'item-1',
            name: 'Whole Milk',
            categoryId: 'cat-1',
            baseUnit: 'ml',
            pieceSize: 1,
            branchId: '',
            branchName: '',
            onHand: 0,
            minThreshold: 300,
            isActive: true,
          ),
        ],
      );

      final container = createTestContainer(
        overrides: [
          stockItemRepositoryProvider.overrideWithValue(stockRepo),
          branchStockRepositoryProvider.overrideWithValue(branchStockRepo),
          inventoryJournalRepositoryProvider.overrideWithValue(journalRepo),
        ],
      );

      final notifier = container.read(
        stockInventoryControllerProvider.notifier,
      );
      await notifier.loadStockItems(branchId: 'branch-1');

      final state = container.read(stockInventoryControllerProvider);
      expect(state.error, isNull);
      expect(state.errorCode, isNull);
      expect(state.items, hasLength(1));
      expect(state.items.first.id, 'item-1');
      expect(state.items.first.branchId, 'branch-1');
    },
  );

  test(
    'StockInventoryController.loadStockItemDetail merges detail with branch fields',
    () async {
      final stockRepo = _MockStockItemRepository();
      final branchStockRepo = _MockBranchStockRepository();
      final journalRepo = _MockJournalRepository();

      when(() => stockRepo.fetchStockItemById('item-1')).thenAnswer(
        (_) async => const StockItem(
          id: 'item-1',
          name: 'Iced Coffee Updated',
          categoryId: 'cat-1',
          baseUnit: 'ml',
          pieceSize: 1,
          branchId: '',
          branchName: '',
          onHand: 0,
          minThreshold: 10,
          isActive: true,
        ),
      );

      final container = createTestContainer(
        overrides: [
          stockItemRepositoryProvider.overrideWithValue(stockRepo),
          branchStockRepositoryProvider.overrideWithValue(branchStockRepo),
          inventoryJournalRepositoryProvider.overrideWithValue(journalRepo),
        ],
      );

      final notifier = container.read(
        stockInventoryControllerProvider.notifier,
      );
      notifier.state = const StockInventoryState(
        items: [
          StockItem(
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
        ],
      );

      final merged = await notifier.loadStockItemDetail('item-1');
      final state = container.read(stockInventoryControllerProvider);

      expect(merged.name, 'Iced Coffee Updated');
      expect(merged.branchId, 'branch-1');
      expect(merged.branchName, 'Main Branch');
      expect(merged.onHand, 12);
      expect(merged.minThreshold, 3);
      expect(state.items.first.name, 'Iced Coffee Updated');
      expect(state.items.first.branchId, 'branch-1');
      expect(state.error, isNull);
      expect(state.errorCode, isNull);
    },
  );

  test(
    'StockInventoryController.archiveStockItem removes item and related batches',
    () async {
      final stockRepo = _MockStockItemRepository();
      final branchStockRepo = _MockBranchStockRepository();
      final journalRepo = _MockJournalRepository();

      when(() => stockRepo.archiveStockItem('item-1')).thenAnswer((_) async {});

      final container = createTestContainer(
        overrides: [
          stockItemRepositoryProvider.overrideWithValue(stockRepo),
          branchStockRepositoryProvider.overrideWithValue(branchStockRepo),
          inventoryJournalRepositoryProvider.overrideWithValue(journalRepo),
        ],
      );

      final notifier = container.read(
        stockInventoryControllerProvider.notifier,
      );
      notifier.state = const StockInventoryState(
        items: [
          StockItem(
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
          StockItem(
            id: 'item-2',
            name: 'Lemon Tea',
            categoryId: 'cat-1',
            baseUnit: 'ml',
            pieceSize: 1,
            branchId: 'branch-1',
            branchName: 'Main Branch',
            onHand: 7,
            minThreshold: 2,
            isActive: true,
          ),
        ],
        batches: [
          StockBatch(
            id: 'batch-1',
            stockItemId: 'item-1',
            branchId: 'branch-1',
            onHand: 12,
            receivedDate: '2026-02-20',
          ),
          StockBatch(
            id: 'batch-2',
            stockItemId: 'item-2',
            branchId: 'branch-1',
            onHand: 7,
            receivedDate: '2026-02-19',
          ),
        ],
      );

      await notifier.archiveStockItem('item-1');
      final state = container.read(stockInventoryControllerProvider);

      expect(state.items, hasLength(1));
      expect(state.items.first.id, 'item-2');
      expect(state.batches, hasLength(1));
      expect(state.batches.first.id, 'batch-2');
      expect(state.error, isNull);
      expect(state.errorCode, isNull);
      verify(() => stockRepo.archiveStockItem('item-1')).called(1);
    },
  );

  test(
    'StockInventoryController.updateStockItem returns saved item with imageUrl and updates state',
    () async {
      final stockRepo = _MockStockItemRepository();
      final branchStockRepo = _MockBranchStockRepository();
      final journalRepo = _MockJournalRepository();

      const updatedDto = StockItem(
        id: 'item-1',
        name: 'Iced Coffee Updated',
        categoryId: 'cat-1',
        baseUnit: 'ml',
        pieceSize: 1,
        branchId: 'branch-1',
        branchName: '',
        onHand: 12,
        minThreshold: 3,
        isActive: true,
        imageUrl: 'https://cdn.example.com/item-1.jpg',
      );

      when(
        () => stockRepo.updateStockItem(
          any(),
          imagePath: any(named: 'imagePath'),
          imageBytes: any(named: 'imageBytes'),
        ),
      ).thenAnswer((_) async => updatedDto);

      final container = createTestContainer(
        overrides: [
          stockItemRepositoryProvider.overrideWithValue(stockRepo),
          branchStockRepositoryProvider.overrideWithValue(branchStockRepo),
          inventoryJournalRepositoryProvider.overrideWithValue(journalRepo),
        ],
      );

      final notifier = container.read(
        stockInventoryControllerProvider.notifier,
      );
      notifier.state = const StockInventoryState(
        items: [
          StockItem(
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
        ],
      );

      final saved = await notifier.updateStockItem(
        const StockItem(
          id: 'item-1',
          name: 'Iced Coffee Updated',
          categoryId: 'cat-1',
          baseUnit: 'ml',
          pieceSize: 1,
          branchId: 'branch-1',
          branchName: 'Main Branch',
          onHand: 12,
          minThreshold: 3,
          isActive: true,
        ),
        imageBytes: [1, 2, 3],
      );

      final state = container.read(stockInventoryControllerProvider);
      expect(saved.imageUrl, 'https://cdn.example.com/item-1.jpg');
      expect(state.items.first.imageUrl, 'https://cdn.example.com/item-1.jpg');
      expect(state.items.first.name, 'Iced Coffee Updated');
    },
  );

  test(
    'StockInventoryController.restoreStockItem marks item active in state',
    () async {
      final stockRepo = _MockStockItemRepository();
      final branchStockRepo = _MockBranchStockRepository();
      final journalRepo = _MockJournalRepository();

      when(() => stockRepo.restoreStockItem('item-1')).thenAnswer((_) async {});

      final container = createTestContainer(
        overrides: [
          stockItemRepositoryProvider.overrideWithValue(stockRepo),
          branchStockRepositoryProvider.overrideWithValue(branchStockRepo),
          inventoryJournalRepositoryProvider.overrideWithValue(journalRepo),
        ],
      );

      final notifier = container.read(
        stockInventoryControllerProvider.notifier,
      );
      notifier.state = const StockInventoryState(
        items: [
          StockItem(
            id: 'item-1',
            name: 'Iced Coffee',
            categoryId: 'cat-1',
            baseUnit: 'ml',
            pieceSize: 1,
            branchId: 'branch-1',
            branchName: 'Main Branch',
            onHand: 12,
            minThreshold: 3,
            isActive: false,
          ),
        ],
      );

      await notifier.restoreStockItem('item-1');
      final state = container.read(stockInventoryControllerProvider);

      expect(state.items.first.isActive, isTrue);
      expect(state.error, isNull);
      expect(state.errorCode, isNull);
      verify(() => stockRepo.restoreStockItem('item-1')).called(1);
    },
  );

  test(
    'StockInventoryController.loadRestockBatches hydrates state batches',
    () async {
      final stockRepo = _MockStockItemRepository();
      final branchStockRepo = _MockBranchStockRepository();
      final journalRepo = _MockJournalRepository();

      when(
        () => journalRepo.fetchRestockBatches(
          status: 'active',
          stockItemId: 'item-1',
          limit: 200,
          offset: 0,
        ),
      ).thenAnswer(
        (_) async => const [
          StockBatch(
            id: 'batch-1',
            stockItemId: 'item-1',
            branchId: 'branch-1',
            onHand: 2400,
            receivedDate: '2026-02-20',
            expiryDate: '2026-03-20',
          ),
        ],
      );

      final container = createTestContainer(
        overrides: [
          stockItemRepositoryProvider.overrideWithValue(stockRepo),
          branchStockRepositoryProvider.overrideWithValue(branchStockRepo),
          inventoryJournalRepositoryProvider.overrideWithValue(journalRepo),
        ],
      );

      final notifier = container.read(
        stockInventoryControllerProvider.notifier,
      );
      await notifier.loadRestockBatches(stockItemId: 'item-1');

      final state = container.read(stockInventoryControllerProvider);
      expect(state.batches, hasLength(1));
      expect(state.batches.first.id, 'batch-1');
      expect(state.restockBatchOffset, 1);
      expect(state.hasMoreRestockBatches, isFalse);
      expect(state.error, isNull);
      expect(state.errorCode, isNull);
    },
  );

  test(
    'StockInventoryController.loadMoreRestockBatches appends next page',
    () async {
      final stockRepo = _MockStockItemRepository();
      final branchStockRepo = _MockBranchStockRepository();
      final journalRepo = _MockJournalRepository();

      when(
        () => journalRepo.fetchRestockBatches(
          status: 'active',
          stockItemId: 'item-1',
          limit: 1,
          offset: 0,
        ),
      ).thenAnswer(
        (_) async => const [
          StockBatch(
            id: 'batch-1',
            stockItemId: 'item-1',
            branchId: 'branch-1',
            onHand: 2400,
            receivedDate: '2026-02-20',
          ),
        ],
      );
      when(
        () => journalRepo.fetchRestockBatches(
          status: 'active',
          stockItemId: 'item-1',
          limit: 1,
          offset: 1,
        ),
      ).thenAnswer(
        (_) async => const [
          StockBatch(
            id: 'batch-2',
            stockItemId: 'item-1',
            branchId: 'branch-1',
            onHand: 1200,
            receivedDate: '2026-02-21',
          ),
        ],
      );

      final container = createTestContainer(
        overrides: [
          stockItemRepositoryProvider.overrideWithValue(stockRepo),
          branchStockRepositoryProvider.overrideWithValue(branchStockRepo),
          inventoryJournalRepositoryProvider.overrideWithValue(journalRepo),
        ],
      );

      final notifier = container.read(
        stockInventoryControllerProvider.notifier,
      );
      await notifier.loadRestockBatches(
        stockItemId: 'item-1',
        limit: 1,
        offset: 0,
      );
      await notifier.loadMoreRestockBatches();

      final state = container.read(stockInventoryControllerProvider);
      expect(state.batches, hasLength(2));
      expect(state.batches.first.id, 'batch-1');
      expect(state.batches.last.id, 'batch-2');
      expect(state.restockBatchOffset, 2);
      expect(state.hasMoreRestockBatches, isTrue);
    },
  );

  test(
    'StockInventoryController.updateRestockBatchMetadata updates batch expiry in state',
    () async {
      final stockRepo = _MockStockItemRepository();
      final branchStockRepo = _MockBranchStockRepository();
      final journalRepo = _MockJournalRepository();

      when(
        () => journalRepo.updateRestockBatchMetadata(
          batchId: 'batch-1',
          expiryDate: '2026-03-25',
          supplierName: 'Supplier X',
          purchaseCostUsd: 16.25,
          note: 'Updated note',
        ),
      ).thenAnswer(
        (_) async => const StockBatch(
          id: 'batch-1',
          stockItemId: 'item-1',
          branchId: 'branch-1',
          onHand: 2400,
          receivedDate: '2026-02-20',
          expiryDate: '2026-03-25',
        ),
      );

      final container = createTestContainer(
        overrides: [
          stockItemRepositoryProvider.overrideWithValue(stockRepo),
          branchStockRepositoryProvider.overrideWithValue(branchStockRepo),
          inventoryJournalRepositoryProvider.overrideWithValue(journalRepo),
        ],
      );

      final notifier = container.read(
        stockInventoryControllerProvider.notifier,
      );
      notifier.state = const StockInventoryState(
        batches: [
          StockBatch(
            id: 'batch-1',
            stockItemId: 'item-1',
            branchId: 'branch-1',
            onHand: 2400,
            receivedDate: '2026-02-20',
            expiryDate: '2026-03-20',
          ),
        ],
      );

      await notifier.updateRestockBatchMetadata(
        batchId: 'batch-1',
        expiryDate: '2026-03-25',
        supplierName: 'Supplier X',
        purchaseCostUsd: 16.25,
        note: 'Updated note',
      );

      final state = container.read(stockInventoryControllerProvider);
      expect(state.batches, hasLength(1));
      expect(state.batches.first.expiryDate, '2026-03-25');
      expect(state.error, isNull);
      expect(state.errorCode, isNull);
    },
  );

  test(
    'StockInventoryController.archiveRestockBatch removes batch from state',
    () async {
      final stockRepo = _MockStockItemRepository();
      final branchStockRepo = _MockBranchStockRepository();
      final journalRepo = _MockJournalRepository();

      when(
        () => journalRepo.archiveRestockBatch(batchId: 'batch-1'),
      ).thenAnswer((_) async {});

      final container = createTestContainer(
        overrides: [
          stockItemRepositoryProvider.overrideWithValue(stockRepo),
          branchStockRepositoryProvider.overrideWithValue(branchStockRepo),
          inventoryJournalRepositoryProvider.overrideWithValue(journalRepo),
        ],
      );

      final notifier = container.read(
        stockInventoryControllerProvider.notifier,
      );
      notifier.state = const StockInventoryState(
        batches: [
          StockBatch(
            id: 'batch-1',
            stockItemId: 'item-1',
            branchId: 'branch-1',
            onHand: 2400,
            receivedDate: '2026-02-20',
            expiryDate: '2026-03-20',
          ),
          StockBatch(
            id: 'batch-2',
            stockItemId: 'item-2',
            branchId: 'branch-1',
            onHand: 500,
            receivedDate: '2026-02-18',
          ),
        ],
      );

      await notifier.archiveRestockBatch(batchId: 'batch-1');

      final state = container.read(stockInventoryControllerProvider);
      expect(state.batches, hasLength(1));
      expect(state.batches.first.id, 'batch-2');
      expect(state.error, isNull);
      expect(state.errorCode, isNull);
      verify(
        () => journalRepo.archiveRestockBatch(batchId: 'batch-1'),
      ).called(1);
    },
  );

  test(
    'StockInventoryController.createRestockBatch sends restock-batch contract fields',
    () async {
      final stockRepo = _MockStockItemRepository();
      final branchStockRepo = _MockBranchStockRepository();
      final journalRepo = _MockJournalRepository();

      when(
        () => journalRepo.createRestockBatch(
          branchId: 'branch-1',
          stockItemId: 'item-1',
          qty: 2400,
          receivedAt: any(named: 'receivedAt'),
          expiryDate: '2026-03-20',
          supplierName: 'Farm Supplier Co.',
          purchaseCostUsd: 15.75,
          note: 'Morning restock',
        ),
      ).thenAnswer((_) async => null);
      when(
        () => branchStockRepo.fetchStockItems(
          branchId: 'branch-1',
          status: any(named: 'status'),
        ),
      ).thenAnswer(
        (_) async => const [
          StockItem(
            id: 'item-1',
            name: 'Whole Milk',
            categoryId: 'cat-1',
            baseUnit: 'ml',
            pieceSize: 1,
            branchId: 'branch-1',
            branchName: 'Main Branch',
            onHand: 1200,
            minThreshold: 300,
            isActive: true,
          ),
        ],
      );
      when(
        () => branchStockRepo.fetchOnHand(
          branchId: 'branch-1',
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => const []);

      final container = createTestContainer(
        overrides: [
          stockItemRepositoryProvider.overrideWithValue(stockRepo),
          branchStockRepositoryProvider.overrideWithValue(branchStockRepo),
          inventoryJournalRepositoryProvider.overrideWithValue(journalRepo),
        ],
      );

      final notifier = container.read(
        stockInventoryControllerProvider.notifier,
      );
      notifier.state = const StockInventoryState(
        items: [
          StockItem(
            id: 'item-1',
            name: 'Whole Milk',
            categoryId: 'cat-1',
            baseUnit: 'ml',
            pieceSize: 1,
            branchId: 'branch-1',
            branchName: 'Main Branch',
            onHand: 1200,
            minThreshold: 300,
            isActive: true,
          ),
        ],
      );

      await notifier.createRestockBatch(
        itemId: 'item-1',
        baseQty: 2400,
        restockDate: '2026-02-20',
        expiryDate: '2026-03-20',
        supplierName: 'Farm Supplier Co.',
        purchaseCostUsd: 15.75,
        note: 'Morning restock',
        branchId: 'branch-1',
      );

      final captured = verify(
        () => journalRepo.createRestockBatch(
          branchId: 'branch-1',
          stockItemId: 'item-1',
          qty: 2400,
          receivedAt: captureAny(named: 'receivedAt'),
          expiryDate: '2026-03-20',
          supplierName: captureAny(named: 'supplierName'),
          purchaseCostUsd: 15.75,
          note: 'Morning restock',
        ),
      ).captured;
      final receivedAtCaptured = captured.first as String?;
      final supplierNameCaptured = captured.last as String?;
      expect(supplierNameCaptured, 'Farm Supplier Co.');
      expect(receivedAtCaptured, isNotNull);
      expect(receivedAtCaptured!.contains('T'), isTrue);
      expect(receivedAtCaptured.endsWith('Z'), isTrue);
    },
  );

  test(
    'StockInventoryController.applyInventoryAdjustment uses adjustments API and updates local on-hand',
    () async {
      final stockRepo = _MockStockItemRepository();
      final branchStockRepo = _MockBranchStockRepository();
      final journalRepo = _MockJournalRepository();

      when(
        () => journalRepo.applyAdjustment(
          stockItemId: 'item-1',
          style: 'DELTA',
          deltaInBaseUnit: -1,
          countedOnHandInBaseUnit: null,
          reasonCode: 'WASTE',
          note: 'Spilled',
        ),
      ).thenAnswer((_) async => 1);

      final container = createTestContainer(
        overrides: [
          stockItemRepositoryProvider.overrideWithValue(stockRepo),
          branchStockRepositoryProvider.overrideWithValue(branchStockRepo),
          inventoryJournalRepositoryProvider.overrideWithValue(journalRepo),
        ],
      );

      final notifier = container.read(
        stockInventoryControllerProvider.notifier,
      );
      notifier.state = const StockInventoryState(
        items: [
          StockItem(
            id: 'item-1',
            name: 'Iced Coffee',
            baseUnit: 'ml',
            pieceSize: 1,
            branchId: 'branch-1',
            branchName: 'Main Branch',
            onHand: 2,
            minThreshold: 1,
            isActive: true,
          ),
        ],
        batches: [
          StockBatch(
            id: 'batch-1',
            stockItemId: 'item-1',
            branchId: 'branch-1',
            onHand: 2,
            receivedDate: '2025-12-20',
          ),
        ],
      );

      await notifier.applyInventoryAdjustment(
        stockItemId: 'item-1',
        batchId: 'batch-1',
        style: 'DELTA',
        delta: -1,
        note: 'Spilled',
      );

      final state = container.read(stockInventoryControllerProvider);
      expect(state.items.first.onHand, 1);
      expect(state.batches.first.onHand, 1);
      verify(
        () => journalRepo.applyAdjustment(
          stockItemId: 'item-1',
          style: 'DELTA',
          deltaInBaseUnit: -1,
          countedOnHandInBaseUnit: null,
          reasonCode: 'WASTE',
          note: 'Spilled',
        ),
      ).called(1);
    },
  );

  test(
    'StockInventoryController.applyInventoryAdjustment supports SET_TO_COUNT and updates local on-hand',
    () async {
      final stockRepo = _MockStockItemRepository();
      final branchStockRepo = _MockBranchStockRepository();
      final journalRepo = _MockJournalRepository();

      when(
        () => journalRepo.applyAdjustment(
          stockItemId: 'item-1',
          style: 'SET_TO_COUNT',
          deltaInBaseUnit: null,
          countedOnHandInBaseUnit: 7,
          reasonCode: 'COUNT_CORRECTION',
          note: 'Counted again',
        ),
      ).thenAnswer((_) async => 7);

      final container = createTestContainer(
        overrides: [
          stockItemRepositoryProvider.overrideWithValue(stockRepo),
          branchStockRepositoryProvider.overrideWithValue(branchStockRepo),
          inventoryJournalRepositoryProvider.overrideWithValue(journalRepo),
        ],
      );

      final notifier = container.read(
        stockInventoryControllerProvider.notifier,
      );
      notifier.state = const StockInventoryState(
        items: [
          StockItem(
            id: 'item-1',
            name: 'Iced Coffee',
            baseUnit: 'ml',
            pieceSize: 1,
            branchId: 'branch-1',
            branchName: 'Main Branch',
            onHand: 2,
            minThreshold: 1,
            isActive: true,
          ),
        ],
        batches: [
          StockBatch(
            id: 'batch-1',
            stockItemId: 'item-1',
            branchId: 'branch-1',
            onHand: 2,
            receivedDate: '2025-12-20',
          ),
        ],
      );

      await notifier.applyInventoryAdjustment(
        stockItemId: 'item-1',
        batchId: 'batch-1',
        style: 'SET_TO_COUNT',
        countedOnHandInBaseUnit: 7,
        note: 'Counted again',
      );

      final state = container.read(stockInventoryControllerProvider);
      expect(state.items.first.onHand, 7);
      expect(state.batches.first.onHand, 7);
      verify(
        () => journalRepo.applyAdjustment(
          stockItemId: 'item-1',
          style: 'SET_TO_COUNT',
          deltaInBaseUnit: null,
          countedOnHandInBaseUnit: 7,
          reasonCode: 'COUNT_CORRECTION',
          note: 'Counted again',
        ),
      ).called(1);
    },
  );

  test(
    'StockInventoryController.applyInventoryAdjustment throws coded quantity error when negative',
    () async {
      final stockRepo = _MockStockItemRepository();
      final branchStockRepo = _MockBranchStockRepository();
      final journalRepo = _MockJournalRepository();

      final container = createTestContainer(
        overrides: [
          stockItemRepositoryProvider.overrideWithValue(stockRepo),
          branchStockRepositoryProvider.overrideWithValue(branchStockRepo),
          inventoryJournalRepositoryProvider.overrideWithValue(journalRepo),
        ],
      );

      final notifier = container.read(
        stockInventoryControllerProvider.notifier,
      );
      notifier.state = const StockInventoryState(
        items: [
          StockItem(
            id: 'item-1',
            name: 'Iced Coffee',
            baseUnit: 'ml',
            pieceSize: 1,
            branchId: 'branch-1',
            branchName: 'Main Branch',
            onHand: 2,
            minThreshold: 1,
            isActive: true,
          ),
        ],
        batches: [
          StockBatch(
            id: 'batch-1',
            stockItemId: 'item-1',
            branchId: 'branch-1',
            onHand: 2,
            receivedDate: '2025-12-20',
          ),
        ],
      );

      await expectLater(
        notifier.applyInventoryAdjustment(
          stockItemId: 'item-1',
          batchId: 'batch-1',
          style: 'DELTA',
          delta: -5,
        ),
        throwsA(
          isA<ApiClientException>().having(
            (e) => e.code,
            'code',
            'INVENTORY_QUANTITY_INVALID',
          ),
        ),
      );

      final state = container.read(stockInventoryControllerProvider);
      expect(state.errorCode, InventoryErrorCode.quantityInvalid);
    },
  );

  test('InventoryJournalController.load hydrates missing item names', () async {
    final journalRepo = _MockInventoryJournalRepository();
    final stockRepo = _MockStockItemRepository();

    when(
      () => journalRepo.fetch(
        stockItemId: any(named: 'stockItemId'),
        reason: null,
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer(
      (_) async => [
        InventoryJournalEntry(
          id: 'entry-1',
          itemId: 'item-1',
          itemName: 'Item',
          branchId: 'branch-1',
          branchName: 'Main Branch',
          reason: InventoryJournalReason.restock,
          delta: 5,
          note: 'Restock',
          actor: 'Alex',
          createdAt: DateTime(2025, 12, 20),
          occurredAt: DateTime(2025, 12, 20),
        ),
      ],
    );
    when(
      () => stockRepo.fetchMasterStockItems(pageSize: any(named: 'pageSize')),
    ).thenAnswer(
      (_) async => const [
        StockItem(
          id: 'item-1',
          name: 'Iced Coffee',
          baseUnit: 'ml',
          pieceSize: 1,
          branchId: '',
          branchName: '',
          onHand: 0,
          minThreshold: 0,
          isActive: true,
        ),
      ],
    );

    final container = createTestContainer(
      overrides: [
        inventoryJournalRepositoryProvider.overrideWithValue(journalRepo),
        stockItemRepositoryProvider.overrideWithValue(stockRepo),
        loginControllerProvider.overrideWith(
          () => FakeLoginController(const LoginState()),
        ),
      ],
    );

    final notifier = container.read(
      inventoryJournalControllerProvider.notifier,
    );
    await notifier.load();

    final state = container.read(inventoryJournalControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.errorCode, isNull);
    expect(state.entries.first.itemName, 'Iced Coffee');
  });

  test(
    'InventoryJournalController.load maps errors to explicit errorCode',
    () async {
      final journalRepo = _MockInventoryJournalRepository();
      final stockRepo = _MockStockItemRepository();

      when(
        () => journalRepo.fetch(
          stockItemId: any(named: 'stockItemId'),
          reason: null,
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenThrow(
        const ApiClientException(
          message: 'Branch context is missing',
          code: 'BRANCH_CONTEXT_REQUIRED',
          statusCode: 403,
        ),
      );

      final container = createTestContainer(
        overrides: [
          inventoryJournalRepositoryProvider.overrideWithValue(journalRepo),
          stockItemRepositoryProvider.overrideWithValue(stockRepo),
          loginControllerProvider.overrideWith(
            () => FakeLoginController(const LoginState()),
          ),
        ],
      );

      final notifier = container.read(
        inventoryJournalControllerProvider.notifier,
      );
      await notifier.load();

      final state = container.read(inventoryJournalControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.entries, isEmpty);
      expect(state.error, isNotNull);
      expect(state.errorCode, InventoryErrorCode.branchContextRequired);
    },
  );

  test('InventoryJournalController.loadMore appends paged entries', () async {
    final journalRepo = _MockInventoryJournalRepository();
    final stockRepo = _MockStockItemRepository();

    when(
      () => journalRepo.fetch(
        stockItemId: any(named: 'stockItemId'),
        reason: null,
        limit: 1,
        offset: 0,
      ),
    ).thenAnswer(
      (_) async => [
        InventoryJournalEntry(
          id: 'entry-1',
          itemId: 'item-1',
          itemName: 'Item',
          branchId: 'branch-1',
          branchName: 'Main Branch',
          reason: InventoryJournalReason.restock,
          delta: 5,
          note: 'Restock',
          actor: 'Alex',
          createdAt: DateTime(2025, 12, 20),
          occurredAt: DateTime(2025, 12, 20),
        ),
      ],
    );
    when(
      () => journalRepo.fetch(
        stockItemId: any(named: 'stockItemId'),
        reason: null,
        limit: 1,
        offset: 1,
      ),
    ).thenAnswer(
      (_) async => [
        InventoryJournalEntry(
          id: 'entry-2',
          itemId: 'item-2',
          itemName: 'Item',
          branchId: 'branch-1',
          branchName: 'Main Branch',
          reason: InventoryJournalReason.add,
          delta: 2,
          note: 'Adjust',
          actor: 'Alex',
          createdAt: DateTime(2025, 12, 21),
          occurredAt: DateTime(2025, 12, 21),
        ),
      ],
    );
    when(
      () => stockRepo.fetchMasterStockItems(pageSize: any(named: 'pageSize')),
    ).thenAnswer(
      (_) async => const [
        StockItem(
          id: 'item-1',
          name: 'Iced Coffee',
          baseUnit: 'ml',
          pieceSize: 1,
          branchId: '',
          branchName: '',
          onHand: 0,
          minThreshold: 0,
          isActive: true,
        ),
        StockItem(
          id: 'item-2',
          name: 'Lemon Tea',
          baseUnit: 'ml',
          pieceSize: 1,
          branchId: '',
          branchName: '',
          onHand: 0,
          minThreshold: 0,
          isActive: true,
        ),
      ],
    );

    final container = createTestContainer(
      overrides: [
        inventoryJournalRepositoryProvider.overrideWithValue(journalRepo),
        stockItemRepositoryProvider.overrideWithValue(stockRepo),
        loginControllerProvider.overrideWith(
          () => FakeLoginController(const LoginState()),
        ),
      ],
    );

    final notifier = container.read(
      inventoryJournalControllerProvider.notifier,
    );
    await notifier.load(limit: 1);
    await notifier.loadMore();

    final state = container.read(inventoryJournalControllerProvider);
    expect(state.entries, hasLength(2));
    expect(state.offset, 2);
    expect(state.hasMore, isTrue);
  });
}
