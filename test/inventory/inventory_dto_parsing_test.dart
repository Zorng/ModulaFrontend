import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/inventory/data/dto/branch_stock_item_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/inventory_category_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/inventory_journal_entry_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/on_hand_record_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/stock_item_dto.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_status.dart';

import 'inventory_fixture_harness.dart';

void main() {
  group('Inventory fixture DTO parsing', () {
    test('InventoryCategoryDto parses canonical category list payload', () {
      final rows = readInventoryDataListFixture('categories_list_v0.json');
      final first = InventoryCategoryDto.fromJson(rows.first);
      final second = InventoryCategoryDto.fromJson(rows[1]);

      expect(rows, hasLength(2));
      expect(first.id, 'cat-1');
      expect(first.tenantId, 'tenant-1');
      expect(first.name, 'Dairy');
      expect(first.status, InventoryStatus.active);
      expect(first.isActive, isTrue);

      expect(second.id, 'cat-2');
      expect(second.status, InventoryStatus.archived);
      expect(second.isActive, isFalse);
    });

    test('StockItemDto parses contract and fallback item fields', () {
      final rows = readInventoryDataListFixture('items_list_v0.json');
      final first = StockItemDto.fromJson(rows.first);
      final second = StockItemDto.fromJson(rows[1]);

      expect(first.id, 'item-1');
      expect(first.categoryId, 'cat-1');
      expect(first.baseUnit, 'ml');
      expect(first.imageUrl, 'https://cdn.example.com/inventory/item-1.jpg');
      expect(first.lowStockThreshold, 1000);
      expect(first.status, InventoryStatus.active);

      expect(second.id, 'item-2');
      expect(second.categoryId, isNull);
      expect(second.baseUnit, 'g');
      expect(second.lowStockThreshold, 500);
      expect(second.status, InventoryStatus.archived);
      expect(second.isActive, isFalse);
    });

    test('BranchStockItemDto parses nested and flat branch stock payloads', () {
      final rows = readInventoryDataListFixture('branch_stock_list_v0.json');
      final nested = BranchStockItemDto.fromJson(rows.first);
      final flat = BranchStockItemDto.fromJson(
        rows[1],
        branchIdHint: 'branch-1',
      );

      expect(nested.stockItemId, 'item-1');
      expect(nested.stockItemName, 'Whole Milk');
      expect(nested.branchId, 'branch-1');
      expect(nested.onHand, 6400);
      expect(nested.minThreshold, 1000);
      expect(nested.isLowStock, isFalse);
      expect(nested.stockItem.id, 'item-1');
      expect(nested.stockItem.status, InventoryStatus.active);

      expect(flat.stockItemId, 'item-2');
      expect(flat.stockItemName, 'Raw Sugar');
      expect(flat.branchId, 'branch-1');
      expect(flat.onHand, 220);
      expect(flat.minThreshold, 500);
      expect(flat.isLowStock, isTrue);
      expect(flat.stockItem.baseUnit, 'g');
    });

    test('OnHandRecordDto parses contract on-hand projection fields', () {
      final rows = readInventoryDataListFixture('on_hand_records_v0.json');
      final first = OnHandRecordDto.fromJson(rows.first);
      final second = OnHandRecordDto.fromJson(
        rows[1],
        branchIdHint: 'branch-1',
      );

      expect(first.stockItemId, 'item-1');
      expect(first.branchId, 'branch-1');
      expect(first.onHand, 6400);
      expect(first.minThreshold, 1000);

      expect(second.stockItemId, 'item-2');
      expect(second.branchId, 'branch-1');
      expect(second.onHand, 120);
      expect(second.minThreshold, 200);
    });

    test(
      'InventoryJournalEntryDto parses reasonCode and quantityInBaseUnit',
      () {
        final rows = readInventoryDataListFixture('journal_entries_v0.json');
        final contractRow = InventoryJournalEntryDto.fromJson(rows.first);
        final fallbackRow = InventoryJournalEntryDto.fromJson(rows[1]);

        expect(contractRow.id, 'je-1');
        expect(contractRow.stockItemId, 'item-1');
        expect(contractRow.reason, 'SALE_DEDUCTION');
        expect(contractRow.delta, -250);
        expect(contractRow.actorId, 'acct-1');
        expect(contractRow.note, 'POS sale deduction');
        expect(contractRow.createdAt.isUtc, isTrue);
        expect(contractRow.occurredAt.isUtc, isTrue);

        expect(fallbackRow.id, 'je-2');
        expect(fallbackRow.stockItemId, 'item-2');
        expect(fallbackRow.reason, 'restock');
        expect(fallbackRow.delta, 500);
        expect(fallbackRow.actorId, 'Alex');
        expect(fallbackRow.actorName, 'Alex');
      },
    );

    test('InventoryStatus parser normalizes status values', () {
      expect(inventoryStatusFromRaw('ACTIVE'), InventoryStatus.active);
      expect(inventoryStatusFromRaw('archived'), InventoryStatus.archived);
      expect(inventoryStatusFromRaw(''), InventoryStatus.unknown);
      expect(inventoryStatusFromRaw('INVALID'), InventoryStatus.unknown);
    });
  });
}
