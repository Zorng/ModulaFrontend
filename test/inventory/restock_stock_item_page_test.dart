import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/inventory/data/inventory_paginated_result.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/view/restock_stock_item/restock_stock_item_page.dart';

import '../test_utils/pump_app.dart';
import 'inventory_test_fakes.dart';

class _MockStockItemRepository extends Mock implements StockItemRepository {}

InventoryPaginatedResult<StockItem> _stockPage(
  List<StockItem> items, {
  int limit = 200,
  int offset = 0,
  int total = 0,
  bool hasMore = false,
}) {
  return InventoryPaginatedResult<StockItem>(
    items: items,
    limit: limit,
    offset: offset,
    total: total,
    hasMore: hasMore,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'restock item picker searches across the full fetched stock catalog',
    (tester) async {
      final repository = _MockStockItemRepository();
      const firstPageItem = StockItem(
        id: 'item-1',
        name: 'Coffee Beans',
        baseUnit: 'g',
        pieceSize: 1,
        branchId: '',
        branchName: '',
        onHand: 0,
        minThreshold: 0,
        isActive: true,
      );
      const secondPageItem = StockItem(
        id: 'item-2',
        name: 'Matcha Powder',
        baseUnit: 'g',
        pieceSize: 1,
        branchId: '',
        branchName: '',
        onHand: 0,
        minThreshold: 0,
        isActive: true,
      );

      when(
        () => repository.fetchMasterStockItems(
          status: any(named: 'status'),
          search: any(named: 'search'),
          categoryId: any(named: 'categoryId'),
          pageSize: any(named: 'pageSize'),
          offset: 0,
        ),
      ).thenAnswer(
        (_) async => _stockPage(
          const [firstPageItem],
          offset: 0,
          total: 2,
          hasMore: true,
        ),
      );
      when(
        () => repository.fetchMasterStockItems(
          status: any(named: 'status'),
          search: any(named: 'search'),
          categoryId: any(named: 'categoryId'),
          pageSize: any(named: 'pageSize'),
          offset: 1,
        ),
      ).thenAnswer(
        (_) async => _stockPage(
          const [secondPageItem],
          offset: 1,
          total: 2,
          hasMore: false,
        ),
      );

      await pumpApp(
        tester,
        const RestockStockItemPage(),
        overrides: inventoryOverrides(stockItemRepository: repository),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Matcha');
      await tester.pumpAndSettle();

      expect(find.text('Matcha Powder'), findsOneWidget);
      verify(
        () => repository.fetchMasterStockItems(
          status: any(named: 'status'),
          search: any(named: 'search'),
          categoryId: any(named: 'categoryId'),
          pageSize: any(named: 'pageSize'),
          offset: 0,
        ),
      ).called(1);
      verify(
        () => repository.fetchMasterStockItems(
          status: any(named: 'status'),
          search: any(named: 'search'),
          categoryId: any(named: 'categoryId'),
          pageSize: any(named: 'pageSize'),
          offset: 1,
        ),
      ).called(1);
    },
  );
}
