import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
  Future<void> loadStockItems({String? branchId}) async {
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
        () => branchStockRepo.fetchStockItems(branchId: any(named: 'branchId')),
      ).thenAnswer(
        (_) async => const [
          StockItem(
            id: 'item-1',
            name: 'Iced Coffee',
            category: '',
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
        () => branchStockRepo.fetchOnHand(branchId: any(named: 'branchId')),
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
      expect(state.items.first.category, 'Beverages');
    },
  );

  test('StockInventoryController.adjustBatch throws when negative', () async {
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

    final notifier = container.read(stockInventoryControllerProvider.notifier);
    notifier.state = const StockInventoryState(
      items: [
        StockItem(
          id: 'item-1',
          name: 'Iced Coffee',
          category: 'Beverages',
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

    expect(
      () => notifier.adjustBatch(batchId: 'batch-1', delta: -5),
      throwsA(isA<StateError>()),
    );
  });

  test('InventoryJournalController.load hydrates missing item names', () async {
    final journalRepo = _MockInventoryJournalRepository();
    final stockRepo = _MockStockItemRepository();

    when(
      () => journalRepo.fetch(
        branchId: any(named: 'branchId'),
        stockItemId: any(named: 'stockItemId'),
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
          category: 'Beverages',
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
    expect(state.first.itemName, 'Iced Coffee');
  });
}
