import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/storage/app_database.dart';

class SyncCheckpointRecord {
  const SyncCheckpointRecord({
    required this.deviceId,
    required this.tenantId,
    required this.branchId,
    required this.accountId,
    required this.moduleScopeSetKey,
    this.cursor,
    this.lastPullAt,
    this.lastSuccessfulPullAt,
    this.lastPullStatus,
    this.lastErrorCode,
  });

  final String deviceId;
  final String tenantId;
  final String branchId;
  final String accountId;
  final String moduleScopeSetKey;
  final String? cursor;
  final DateTime? lastPullAt;
  final DateTime? lastSuccessfulPullAt;
  final String? lastPullStatus;
  final String? lastErrorCode;

  SyncCheckpointRecord copyWith({
    String? cursor,
    DateTime? lastPullAt,
    DateTime? lastSuccessfulPullAt,
    String? lastPullStatus,
    String? lastErrorCode,
  }) {
    return SyncCheckpointRecord(
      deviceId: deviceId,
      tenantId: tenantId,
      branchId: branchId,
      accountId: accountId,
      moduleScopeSetKey: moduleScopeSetKey,
      cursor: cursor ?? this.cursor,
      lastPullAt: lastPullAt ?? this.lastPullAt,
      lastSuccessfulPullAt: lastSuccessfulPullAt ?? this.lastSuccessfulPullAt,
      lastPullStatus: lastPullStatus ?? this.lastPullStatus,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
    );
  }
}

abstract class SyncCheckpointStore {
  Future<SyncCheckpointRecord?> read({
    required String deviceId,
    required String tenantId,
    String? branchId,
    String? accountId,
    required String moduleScopeSetKey,
  });

  Future<void> write(SyncCheckpointRecord record);

  Future<void> clear({
    required String deviceId,
    required String tenantId,
    String? branchId,
    String? accountId,
    required String moduleScopeSetKey,
  });
}

class DriftSyncCheckpointStore implements SyncCheckpointStore {
  DriftSyncCheckpointStore(this._db);

  final AppDatabase _db;

  @override
  Future<SyncCheckpointRecord?> read({
    required String deviceId,
    required String tenantId,
    String? branchId,
    String? accountId,
    required String moduleScopeSetKey,
  }) async {
    final normalizedBranchId = (branchId ?? '').trim();
    final normalizedAccountId = (accountId ?? '').trim();

    final row =
        await (_db.select(_db.syncCheckpointEntries)
              ..where((tbl) => tbl.deviceId.equals(deviceId.trim()))
              ..where((tbl) => tbl.tenantId.equals(tenantId.trim()))
              ..where((tbl) => tbl.branchId.equals(normalizedBranchId))
              ..where((tbl) => tbl.accountId.equals(normalizedAccountId))
              ..where(
                (tbl) => tbl.moduleScopeSetKey.equals(moduleScopeSetKey.trim()),
              ))
            .getSingleOrNull();

    if (row == null) return null;
    return SyncCheckpointRecord(
      deviceId: row.deviceId,
      tenantId: row.tenantId,
      branchId: row.branchId,
      accountId: row.accountId,
      moduleScopeSetKey: row.moduleScopeSetKey,
      cursor: row.cursor,
      lastPullAt: row.lastPullAt,
      lastSuccessfulPullAt: row.lastSuccessfulPullAt,
      lastPullStatus: row.lastPullStatus,
      lastErrorCode: row.lastErrorCode,
    );
  }

  @override
  Future<void> write(SyncCheckpointRecord record) {
    return _db
        .into(_db.syncCheckpointEntries)
        .insertOnConflictUpdate(
          SyncCheckpointEntriesCompanion.insert(
            deviceId: record.deviceId.trim(),
            tenantId: Value(record.tenantId.trim()),
            branchId: Value(record.branchId.trim()),
            accountId: Value(record.accountId.trim()),
            moduleScopeSetKey: record.moduleScopeSetKey.trim(),
            cursor: Value(record.cursor),
            lastPullAt: Value(record.lastPullAt),
            lastSuccessfulPullAt: Value(record.lastSuccessfulPullAt),
            lastPullStatus: Value(record.lastPullStatus),
            lastErrorCode: Value(record.lastErrorCode),
          ),
        );
  }

  @override
  Future<void> clear({
    required String deviceId,
    required String tenantId,
    String? branchId,
    String? accountId,
    required String moduleScopeSetKey,
  }) {
    final normalizedBranchId = (branchId ?? '').trim();
    final normalizedAccountId = (accountId ?? '').trim();

    return (_db.delete(_db.syncCheckpointEntries)
          ..where((tbl) => tbl.deviceId.equals(deviceId.trim()))
          ..where((tbl) => tbl.tenantId.equals(tenantId.trim()))
          ..where((tbl) => tbl.branchId.equals(normalizedBranchId))
          ..where((tbl) => tbl.accountId.equals(normalizedAccountId))
          ..where(
            (tbl) => tbl.moduleScopeSetKey.equals(moduleScopeSetKey.trim()),
          ))
        .go();
  }
}

final syncCheckpointStoreProvider = Provider<SyncCheckpointStore>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftSyncCheckpointStore(db);
});
