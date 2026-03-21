import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/core/sync/offline_command_queue_store.dart';

void main() {
  late AppDatabase database;
  late OfflineCommandQueueStore store;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    store = DriftOfflineCommandQueueStore(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('writes and reads queue records by client op id', () async {
    final createdAt = DateTime.utc(2026, 3, 17, 9);
    final record = OfflineCommandRecord(
      clientOpId: 'op-1',
      operationType: OfflineOperationType.attendanceStartWork,
      tenantId: 'tenant-1',
      branchId: 'branch-1',
      accountId: 'account-1',
      occurredAt: createdAt,
      payloadJson: jsonEncode({'occurredAt': '2026-03-17T09:00:00Z'}),
      status: OfflineCommandQueueStatus.pending,
      retryCount: 0,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    await store.write(record);

    final loaded = await store.read('op-1');

    expect(loaded, isNotNull);
    expect(loaded!.operationType, OfflineOperationType.attendanceStartWork);
    expect(loaded.status, OfflineCommandQueueStatus.pending);
    expect(
      loaded.decodePayload(),
      containsPair('occurredAt', '2026-03-17T09:00:00Z'),
    );
  });

  test(
    'listReplayReadyForContext returns pending and syncing only in order',
    () async {
      final createdAt = DateTime.utc(2026, 3, 17, 9);
      await store.write(
        OfflineCommandRecord(
          clientOpId: 'op-2',
          operationType: OfflineOperationType.cashSessionOpen,
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'account-1',
          occurredAt: createdAt.add(const Duration(minutes: 2)),
          payloadJson: '{}',
          status: OfflineCommandQueueStatus.pending,
          retryCount: 0,
          createdAt: createdAt.add(const Duration(minutes: 2)),
          updatedAt: createdAt.add(const Duration(minutes: 2)),
        ),
      );
      await store.write(
        OfflineCommandRecord(
          clientOpId: 'op-1',
          operationType: OfflineOperationType.cashSessionMovement,
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'account-1',
          occurredAt: createdAt,
          payloadJson: '{}',
          status: OfflineCommandQueueStatus.syncing,
          retryCount: 1,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
      await store.write(
        OfflineCommandRecord(
          clientOpId: 'op-3',
          operationType: OfflineOperationType.cashSessionClose,
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'account-1',
          occurredAt: createdAt.add(const Duration(minutes: 3)),
          payloadJson: '{}',
          status: OfflineCommandQueueStatus.failed,
          retryCount: 1,
          createdAt: createdAt.add(const Duration(minutes: 3)),
          updatedAt: createdAt.add(const Duration(minutes: 3)),
        ),
      );

      final records = await store.listReplayReadyForContext(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'account-1',
      );

      expect(records.map((record) => record.clientOpId), ['op-1', 'op-2']);
    },
  );
}
