import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/inventory/data/mock_inventory_store.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

void main() {
  test(
    'branch inventory hides never-stocked items and keeps zero-on-hand positions',
    () {
      final store = MockInventoryStore.seeded();

      final items = store.fetchInventoryStockItems(branchId: 'mock-branch-1');
      final names = items.map((item) => item.name).toList(growable: false);

      expect(names, contains('Whole Milk'));
      expect(names, contains('Arabica Beans'));
      expect(names, isNot(contains('Paper Cups')));
      expect(
        items.firstWhere((item) => item.name == 'Arabica Beans').onHand,
        0,
      );
    },
  );

  test('restock and adjustment update the same shared stock position', () {
    final store = MockInventoryStore.seeded();
    final created = store.createStockItem(
      const StockItem(
        id: '',
        name: 'Cocoa Powder',
        categoryId: null,
        baseUnit: 'g',
        pieceSize: 1000,
        branchId: '',
        branchName: '',
        onHand: 0,
        minThreshold: 250,
        isActive: true,
      ),
    );

    expect(
      store
          .fetchInventoryStockItems(branchId: 'mock-branch-1')
          .where((item) => item.id == created.id),
      isEmpty,
    );

    store.createRestockBatch(
      branchId: 'mock-branch-1',
      stockItemId: created.id,
      qty: 600,
      receivedAt: '2026-03-13',
      note: 'Initial restock',
    );

    expect(
      store
          .fetchInventoryStockItems(branchId: 'mock-branch-1')
          .firstWhere((item) => item.id == created.id)
          .onHand,
      600,
    );

    final resultingOnHand = store.applyAdjustment(
      branchId: 'mock-branch-1',
      stockItemId: created.id,
      style: 'DELTA',
      deltaInBaseUnit: -600,
      reasonCode: 'WASTE',
      note: 'Disposed',
    );

    expect(resultingOnHand, 0);
    expect(
      store
          .fetchInventoryStockItems(branchId: 'mock-branch-1')
          .firstWhere((item) => item.id == created.id)
          .onHand,
      0,
    );
  });

  test('restock batches support branch and status filtering', () {
    final store = MockInventoryStore.seeded();

    final activeBatches = store.fetchRestockBatches(
      branchId: 'mock-branch-1',
      status: 'active',
    );
    expect(activeBatches, isNotEmpty);

    final archivedTarget = activeBatches.first;
    store.archiveRestockBatch(
      batchId: archivedTarget.id,
      branchId: archivedTarget.branchId,
    );

    final refreshedActive = store.fetchRestockBatches(
      branchId: 'mock-branch-1',
      status: 'active',
    );
    final archived = store.fetchRestockBatches(
      branchId: 'mock-branch-1',
      status: 'archived',
    );

    expect(
      refreshedActive.any((batch) => batch.id == archivedTarget.id),
      isFalse,
    );
    expect(
      archived.any((batch) => batch.id == archivedTarget.id),
      isTrue,
    );
  });

  test('archiving a category detaches items to uncategorized', () {
    final store = MockInventoryStore.seeded();
    final dairy = store
        .fetchCategories(status: 'active')
        .firstWhere((category) => category.name == 'Dairy');

    store.archiveCategory(dairy.id);

    final milk = store.fetchStockItemById('mock-stock-milk');
    final archivedCategory = store
        .fetchCategories(status: 'archived')
        .firstWhere((category) => category.id == dairy.id);

    expect(milk.categoryId, isNull);
    expect(archivedCategory.isActive, isFalse);
  });

  test('archiving and restoring a stock item preserves local data', () {
    final store = MockInventoryStore.seeded();
    final before = store.fetchStockItemById('mock-stock-syrup');

    store.archiveStockItem(before.id);
    final archived = store.fetchStockItemById(before.id);
    store.restoreStockItem(before.id);
    final restored = store.fetchStockItemById(before.id);

    expect(archived.isActive, isFalse);
    expect(restored.isActive, isTrue);
    expect(restored.name, before.name);
    expect(restored.categoryId, before.categoryId);
  });

  test('invalid branch targets raise BRANCH_NOT_FOUND', () {
    final store = MockInventoryStore.seeded();

    expect(
      () => store.fetchInventoryStockItems(branchId: 'missing-branch'),
      throwsA(
        isA<ApiClientException>().having((error) => error.code, 'code', 'BRANCH_NOT_FOUND'),
      ),
    );
  });
}
