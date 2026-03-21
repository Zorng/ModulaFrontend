import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/core/sync/sync_checkpoint_store.dart';

void main() {
  late AppDatabase database;
  late SyncCheckpointStore store;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    store = DriftSyncCheckpointStore(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('writes and reads checkpoint records by full context key', () async {
    const record = SyncCheckpointRecord(
      deviceId: 'device-1',
      tenantId: 'tenant-1',
      branchId: 'branch-1',
      accountId: '',
      moduleScopeSetKey: 'policy',
      cursor: 'cursor-1',
      lastPullStatus: 'success',
    );

    await store.write(record);

    final loaded = await store.read(
      deviceId: 'device-1',
      tenantId: 'tenant-1',
      branchId: 'branch-1',
      moduleScopeSetKey: 'policy',
    );

    expect(loaded, isNotNull);
    expect(loaded!.cursor, 'cursor-1');
    expect(loaded.lastPullStatus, 'success');
  });

  test('clear removes only the targeted checkpoint row', () async {
    await store.write(
      const SyncCheckpointRecord(
        deviceId: 'device-1',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: '',
        moduleScopeSetKey: 'policy',
        cursor: 'cursor-1',
      ),
    );
    await store.write(
      const SyncCheckpointRecord(
        deviceId: 'device-1',
        tenantId: 'tenant-1',
        branchId: 'branch-2',
        accountId: '',
        moduleScopeSetKey: 'policy',
        cursor: 'cursor-2',
      ),
    );

    await store.clear(
      deviceId: 'device-1',
      tenantId: 'tenant-1',
      branchId: 'branch-1',
      moduleScopeSetKey: 'policy',
    );

    final cleared = await store.read(
      deviceId: 'device-1',
      tenantId: 'tenant-1',
      branchId: 'branch-1',
      moduleScopeSetKey: 'policy',
    );
    final remaining = await store.read(
      deviceId: 'device-1',
      tenantId: 'tenant-1',
      branchId: 'branch-2',
      moduleScopeSetKey: 'policy',
    );

    expect(cleared, isNull);
    expect(remaining?.cursor, 'cursor-2');
  });
}
