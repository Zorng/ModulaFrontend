import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/inventory/data/dto/stock_item_dto.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';
import 'package:modular_pos/features/inventory/data/remote_stock_item_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_status.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

class _MockInventoryApi extends Mock implements InventoryApi {}

void main() {
  test('createStockItem forwards contract payload shape', () async {
    final api = _MockInventoryApi();
    final repository = RemoteStockItemRepository(api);

    when(
      () => api.createStockItem(
        any(),
        imagePath: any(named: 'imagePath'),
        imageBytes: any(named: 'imageBytes'),
      ),
    ).thenAnswer(
      (_) async => const StockItemDto(
        id: 'item-1',
        tenantId: 'tenant-1',
        categoryId: 'cat-1',
        name: 'Whole Milk',
        baseUnit: 'ml',
        imageUrl: null,
        lowStockThreshold: 1000,
        status: InventoryStatus.active,
        createdAt: '2026-02-20T00:00:00.000Z',
        updatedAt: '2026-02-21T00:00:00.000Z',
      ),
    );

    await repository.createStockItem(
      const StockItem(
        id: '',
        name: 'Whole Milk',
        categoryId: 'cat-1',
        baseUnit: 'ml',
        pieceSize: 1,
        branchId: '',
        branchName: '',
        onHand: 0,
        minThreshold: 1000,
        isActive: true,
      ),
    );

    final captured =
        verify(
              () => api.createStockItem(
                captureAny(),
                imagePath: captureAny(named: 'imagePath'),
                imageBytes: captureAny(named: 'imageBytes'),
              ),
            ).captured.first
            as Map<String, dynamic>;

    expect(captured['name'], 'Whole Milk');
    expect(captured['baseUnit'], 'ml');
    expect(captured['categoryId'], 'cat-1');
    expect(captured['lowStockThreshold'], 1000);
    expect(captured.containsKey('unitText'), isFalse);
    expect(captured.containsKey('pieceSize'), isFalse);
    expect(captured.containsKey('isActive'), isFalse);
  });

  test('updateStockItem forwards contract patch payload shape', () async {
    final api = _MockInventoryApi();
    final repository = RemoteStockItemRepository(api);

    when(
      () => api.updateStockItem(
        any(),
        any(),
        imagePath: any(named: 'imagePath'),
        imageBytes: any(named: 'imageBytes'),
      ),
    ).thenAnswer(
      (_) async => const StockItemDto(
        id: 'item-1',
        tenantId: 'tenant-1',
        categoryId: null,
        name: 'Whole Milk Updated',
        baseUnit: 'ml',
        imageUrl: null,
        lowStockThreshold: 1200,
        status: InventoryStatus.active,
        createdAt: '2026-02-20T00:00:00.000Z',
        updatedAt: '2026-02-21T00:00:00.000Z',
      ),
    );

    await repository.updateStockItem(
      const StockItem(
        id: 'item-1',
        name: 'Whole Milk Updated',
        categoryId: null,
        baseUnit: 'ml',
        pieceSize: 1,
        branchId: 'branch-1',
        branchName: 'Main Branch',
        onHand: 50,
        minThreshold: 1200,
        isActive: true,
      ),
    );

    final captured =
        verify(
              () => api.updateStockItem(
                'item-1',
                captureAny(),
                imagePath: captureAny(named: 'imagePath'),
                imageBytes: captureAny(named: 'imageBytes'),
              ),
            ).captured[0]
            as Map<String, dynamic>;

    expect(captured['name'], 'Whole Milk Updated');
    expect(captured['categoryId'], isNull);
    expect(captured['lowStockThreshold'], 1200);
    expect(captured['imageUrl'], isNull);
    expect(captured.containsKey('baseUnit'), isFalse);
    expect(captured.containsKey('unitText'), isFalse);
    expect(captured.containsKey('pieceSize'), isFalse);
    expect(captured.containsKey('isActive'), isFalse);
  });

  test('restoreStockItem delegates to restore endpoint adapter', () async {
    final api = _MockInventoryApi();
    final repository = RemoteStockItemRepository(api);

    when(() => api.restoreStockItem('item-1')).thenAnswer((_) async {});

    await repository.restoreStockItem('item-1');

    verify(() => api.restoreStockItem('item-1')).called(1);
  });

  test('archiveStockItem delegates to archive endpoint adapter', () async {
    final api = _MockInventoryApi();
    final repository = RemoteStockItemRepository(api);

    when(() => api.archiveStockItem('item-1')).thenAnswer((_) async {});

    await repository.archiveStockItem('item-1');

    verify(() => api.archiveStockItem('item-1')).called(1);
  });
}
