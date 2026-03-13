import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/inventory/data/dto/inventory_journal_entry_dto.dart';
import 'package:modular_pos/features/inventory/data/dto/restock_batch_dto.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';
import 'package:modular_pos/features/inventory/data/remote_inventory_journal_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_status.dart';

class _MockInventoryApi extends Mock implements InventoryApi {}

void main() {
  test(
    'createRestockBatch maps to restock-batches create endpoint adapter',
    () async {
      final api = _MockInventoryApi();
      final repository = RemoteInventoryJournalRepository(api);

      when(
        () => api.createRestockBatch(
          branchId: 'branch-1',
          stockItemId: 'item-1',
          quantityInBaseUnit: 2400,
          receivedAt: '2026-02-20T00:00:00.000Z',
          expiryDate: '2026-03-20',
          supplierName: null,
          purchaseCostUsd: 15.75,
          note: 'Morning restock',
        ),
      ).thenAnswer(
        (_) async => InventoryJournalEntryDto.fromJson({
          'id': 'je-1',
          'branchId': 'branch-1',
          'branchName': 'Main Branch',
          'stockItemId': 'item-1',
          'stockItemName': 'Whole Milk',
          'reasonCode': 'RESTOCK',
          'direction': 'IN',
          'quantityInBaseUnit': 2400,
          'note': 'Morning restock',
          'actorAccountId': 'acct-1',
          'createdAt': '2026-02-20T00:00:00.000Z',
          'occurredAt': '2026-02-20T00:00:00.000Z',
        }),
      );

      final result = await repository.createRestockBatch(
        branchId: 'branch-1',
        stockItemId: 'item-1',
        qty: 2400,
        receivedAt: '2026-02-20T00:00:00.000Z',
        expiryDate: '2026-03-20',
        purchaseCostUsd: 15.75,
        note: 'Morning restock',
      );

      verify(
        () => api.createRestockBatch(
          branchId: 'branch-1',
          stockItemId: 'item-1',
          quantityInBaseUnit: 2400,
          receivedAt: '2026-02-20T00:00:00.000Z',
          expiryDate: '2026-03-20',
          supplierName: null,
          purchaseCostUsd: 15.75,
          note: 'Morning restock',
        ),
      ).called(1);
      expect(result, isNotNull);
      expect(result!.reason, isNotNull);
      expect(result.delta, 2400);
    },
  );

  test(
    'updateRestockBatchMetadata delegates to updateMeta endpoint adapter',
    () async {
      final api = _MockInventoryApi();
      final repository = RemoteInventoryJournalRepository(api);

      when(
        () => api.updateRestockBatchMetadata(
          batchId: 'batch-1',
          branchId: 'branch-1',
          expiryDate: '2026-03-25',
          supplierName: 'Supplier X',
          purchaseCostUsd: 16.25,
          note: 'Updated note',
        ),
      ).thenAnswer(
        (_) async => const RestockBatchDto(
          id: 'batch-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          stockItemId: 'item-1',
          quantityInBaseUnit: 2400,
          status: InventoryStatus.active,
          receivedAt: '2026-02-20T00:00:00.000Z',
          expiryDate: '2026-03-25',
          supplierName: 'Supplier X',
          purchaseCostUsd: 16.25,
          note: 'Updated note',
          createdByAccountId: 'acct-1',
          createdAt: '2026-02-20T00:00:00.000Z',
          updatedAt: '2026-02-21T00:00:00.000Z',
        ),
      );

      final updated = await repository.updateRestockBatchMetadata(
        batchId: 'batch-1',
        branchId: 'branch-1',
        expiryDate: '2026-03-25',
        supplierName: 'Supplier X',
        purchaseCostUsd: 16.25,
        note: 'Updated note',
      );

      verify(
        () => api.updateRestockBatchMetadata(
          batchId: 'batch-1',
          branchId: 'branch-1',
          expiryDate: '2026-03-25',
          supplierName: 'Supplier X',
          purchaseCostUsd: 16.25,
          note: 'Updated note',
        ),
      ).called(1);
      expect(updated.id, 'batch-1');
      expect(updated.expiryDate, '2026-03-25');
    },
  );

  test('applyAdjustment delegates to adjustments endpoint adapter', () async {
    final api = _MockInventoryApi();
    final repository = RemoteInventoryJournalRepository(api);

    when(
      () => api.applyAdjustment(
        branchId: 'branch-1',
        stockItemId: 'item-1',
        style: 'DELTA',
        deltaInBaseUnit: -250,
        countedOnHandInBaseUnit: null,
        reasonCode: 'WASTE',
        note: 'Spilled',
      ),
    ).thenAnswer((_) async => 1750);

    final resultingOnHand = await repository.applyAdjustment(
      branchId: 'branch-1',
      stockItemId: 'item-1',
      style: 'DELTA',
      deltaInBaseUnit: -250,
      reasonCode: 'WASTE',
      note: 'Spilled',
    );

    verify(
      () => api.applyAdjustment(
        branchId: 'branch-1',
        stockItemId: 'item-1',
        style: 'DELTA',
        deltaInBaseUnit: -250,
        countedOnHandInBaseUnit: null,
        reasonCode: 'WASTE',
        note: 'Spilled',
      ),
    ).called(1);
    expect(resultingOnHand, 1750);
  });

  test('archiveRestockBatch delegates to archive endpoint adapter', () async {
    final api = _MockInventoryApi();
    final repository = RemoteInventoryJournalRepository(api);

    when(
      () => api.archiveRestockBatch(batchId: 'batch-1', branchId: 'branch-1'),
    ).thenAnswer((_) async {});

    await repository.archiveRestockBatch(
      batchId: 'batch-1',
      branchId: 'branch-1',
    );

    verify(
      () => api.archiveRestockBatch(batchId: 'batch-1', branchId: 'branch-1'),
    ).called(1);
  });

  test(
    'fetch maps reason filter to contract reasonCode + limit/offset',
    () async {
      final api = _MockInventoryApi();
      final repository = RemoteInventoryJournalRepository(api);

      when(
        () => api.fetchJournal(
          branchId: 'branch-1',
          stockItemId: 'item-1',
          reasonCode: 'SALE_DEDUCTION',
          limit: 100,
          offset: 20,
        ),
      ).thenAnswer(
        (_) async => [
          InventoryJournalEntryDto.fromJson({
            'id': 'je-1',
            'branchId': 'branch-1',
            'branchName': 'Main Branch',
            'stockItemId': 'item-1',
            'stockItemName': 'Whole Milk',
            'reasonCode': 'SALE_DEDUCTION',
            'direction': 'OUT',
            'quantityInBaseUnit': 250,
            'note': 'Sale consumed',
            'actorAccountId': 'acct-1',
            'createdAt': '2026-02-20T00:00:00.000Z',
            'occurredAt': '2026-02-20T00:00:00.000Z',
          }),
        ],
      );

      final rows = await repository.fetch(
        branchId: 'branch-1',
        stockItemId: 'item-1',
        reason: InventoryJournalReason.sale,
        limit: 100,
        offset: 20,
      );

      verify(
        () => api.fetchJournal(
          branchId: 'branch-1',
          stockItemId: 'item-1',
          reasonCode: 'SALE_DEDUCTION',
          limit: 100,
          offset: 20,
        ),
      ).called(1);
      expect(rows, hasLength(1));
      expect(rows.first.reason, InventoryJournalReason.sale);
      expect(rows.first.delta, -250);
    },
  );

  test(
    'fetch normalizes domain reason filter values to contract reasonCode enums',
    () async {
      final cases = <(InventoryJournalReason, String)>[
        (InventoryJournalReason.restock, 'RESTOCK'),
        (InventoryJournalReason.add, 'ADJUSTMENT'),
        (InventoryJournalReason.remove, 'ADJUSTMENT'),
        (InventoryJournalReason.sale, 'SALE_DEDUCTION'),
        (InventoryJournalReason.voided, 'VOID_REVERSAL'),
        (InventoryJournalReason.reopen, 'OTHER'),
        (InventoryJournalReason.unknown, 'OTHER'),
      ];

      for (final (reason, expectedReasonCode) in cases) {
        final api = _MockInventoryApi();
        final repository = RemoteInventoryJournalRepository(api);
        when(
          () => api.fetchTenantJournal(
            branchId: any(named: 'branchId'),
            stockItemId: any(named: 'stockItemId'),
            reasonCode: any(named: 'reasonCode'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => const []);

        await repository.fetch(reason: reason);

        verify(
          () => api.fetchTenantJournal(
            branchId: null,
            stockItemId: null,
            reasonCode: expectedReasonCode,
            limit: 50,
            offset: 0,
          ),
        ).called(1);
      }
    },
  );

  test('fetch maps reasonCode enums back to domain reason values', () async {
    final api = _MockInventoryApi();
    final repository = RemoteInventoryJournalRepository(api);

    when(
      () => api.fetchTenantJournal(
        branchId: null,
        stockItemId: null,
        reasonCode: null,
        limit: 50,
        offset: 0,
      ),
    ).thenAnswer(
      (_) async => [
        InventoryJournalEntryDto.fromJson({
          'id': 'restock-1',
          'stockItemId': 'item-1',
          'reasonCode': 'RESTOCK',
          'direction': 'IN',
          'quantityInBaseUnit': 10,
          'createdAt': '2026-03-03T00:00:00.000Z',
          'occurredAt': '2026-03-03T00:00:00.000Z',
        }),
        InventoryJournalEntryDto.fromJson({
          'id': 'adj-add-1',
          'stockItemId': 'item-1',
          'reasonCode': 'ADJUSTMENT',
          'direction': 'IN',
          'quantityInBaseUnit': 5,
          'createdAt': '2026-03-03T00:00:00.000Z',
          'occurredAt': '2026-03-03T00:00:00.000Z',
        }),
        InventoryJournalEntryDto.fromJson({
          'id': 'adj-remove-1',
          'stockItemId': 'item-1',
          'reasonCode': 'ADJUSTMENT',
          'direction': 'OUT',
          'quantityInBaseUnit': 3,
          'createdAt': '2026-03-03T00:00:00.000Z',
          'occurredAt': '2026-03-03T00:00:00.000Z',
        }),
        InventoryJournalEntryDto.fromJson({
          'id': 'sale-1',
          'stockItemId': 'item-1',
          'reasonCode': 'SALE_DEDUCTION',
          'direction': 'OUT',
          'quantityInBaseUnit': 2,
          'createdAt': '2026-03-03T00:00:00.000Z',
          'occurredAt': '2026-03-03T00:00:00.000Z',
        }),
        InventoryJournalEntryDto.fromJson({
          'id': 'void-1',
          'stockItemId': 'item-1',
          'reasonCode': 'VOID_REVERSAL',
          'direction': 'IN',
          'quantityInBaseUnit': 1,
          'createdAt': '2026-03-03T00:00:00.000Z',
          'occurredAt': '2026-03-03T00:00:00.000Z',
        }),
        InventoryJournalEntryDto.fromJson({
          'id': 'reopen-1',
          'stockItemId': 'item-1',
          'reasonCode': 'REOPEN',
          'direction': 'IN',
          'quantityInBaseUnit': 1,
          'createdAt': '2026-03-03T00:00:00.000Z',
          'occurredAt': '2026-03-03T00:00:00.000Z',
        }),
        InventoryJournalEntryDto.fromJson({
          'id': 'other-1',
          'stockItemId': 'item-1',
          'reasonCode': 'OTHER',
          'direction': 'IN',
          'quantityInBaseUnit': 1,
          'createdAt': '2026-03-03T00:00:00.000Z',
          'occurredAt': '2026-03-03T00:00:00.000Z',
        }),
      ],
    );

    final rows = await repository.fetch();

    expect(rows.map((entry) => entry.reason), [
      InventoryJournalReason.restock,
      InventoryJournalReason.add,
      InventoryJournalReason.remove,
      InventoryJournalReason.sale,
      InventoryJournalReason.voided,
      InventoryJournalReason.reopen,
      InventoryJournalReason.unknown,
    ]);
  });
}
