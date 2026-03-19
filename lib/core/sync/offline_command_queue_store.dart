import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/storage/app_database.dart';

enum OfflineOperationType {
  checkoutCashFinalize('checkout.cash.finalize'),
  attendanceStartWork('attendance.startWork'),
  attendanceEndWork('attendance.endWork'),
  cashSessionOpen('cashSession.open'),
  cashSessionClose('cashSession.close'),
  cashSessionMovement('cashSession.movement');

  const OfflineOperationType(this.apiValue);

  final String apiValue;

  static OfflineOperationType fromApiValue(String value) {
    final normalized = value.trim();
    return OfflineOperationType.values.firstWhere(
      (type) => type.apiValue == normalized,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Unsupported offline operation type.',
      ),
    );
  }
}

enum OfflineCommandQueueStatus { pending, syncing, applied, duplicate, failed }

class OfflineCommandRecord {
  const OfflineCommandRecord({
    required this.clientOpId,
    required this.operationType,
    required this.tenantId,
    required this.branchId,
    required this.accountId,
    required this.occurredAt,
    required this.payloadJson,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    required this.updatedAt,
    this.dependsOnClientOpId,
    this.lastAttemptAt,
    this.lastSyncedAt,
    this.lastErrorCode,
    this.lastErrorMessage,
  });

  final String clientOpId;
  final OfflineOperationType operationType;
  final String tenantId;
  final String branchId;
  final String accountId;
  final DateTime occurredAt;
  final String payloadJson;
  final String? dependsOnClientOpId;
  final OfflineCommandQueueStatus status;
  final int retryCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAttemptAt;
  final DateTime? lastSyncedAt;
  final String? lastErrorCode;
  final String? lastErrorMessage;

  Map<String, dynamic> decodePayload() {
    try {
      final decoded = jsonDecode(payloadJson);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      // Corrupt payload should not crash queue reads.
    }
    return const <String, dynamic>{};
  }

  OfflineCommandRecord copyWith({
    String? clientOpId,
    String? payloadJson,
    Object? dependsOnClientOpId = _unset,
    OfflineCommandQueueStatus? status,
    int? retryCount,
    DateTime? updatedAt,
    Object? lastAttemptAt = _unset,
    Object? lastSyncedAt = _unset,
    Object? lastErrorCode = _unset,
    Object? lastErrorMessage = _unset,
  }) {
    return OfflineCommandRecord(
      clientOpId: clientOpId ?? this.clientOpId,
      operationType: operationType,
      tenantId: tenantId,
      branchId: branchId,
      accountId: accountId,
      occurredAt: occurredAt,
      payloadJson: payloadJson ?? this.payloadJson,
      dependsOnClientOpId: identical(dependsOnClientOpId, _unset)
          ? this.dependsOnClientOpId
          : dependsOnClientOpId as String?,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAttemptAt: identical(lastAttemptAt, _unset)
          ? this.lastAttemptAt
          : lastAttemptAt as DateTime?,
      lastSyncedAt: identical(lastSyncedAt, _unset)
          ? this.lastSyncedAt
          : lastSyncedAt as DateTime?,
      lastErrorCode: identical(lastErrorCode, _unset)
          ? this.lastErrorCode
          : lastErrorCode as String?,
      lastErrorMessage: identical(lastErrorMessage, _unset)
          ? this.lastErrorMessage
          : lastErrorMessage as String?,
    );
  }

  static const _unset = Object();
}

abstract class OfflineCommandQueueStore {
  Future<void> write(OfflineCommandRecord record);

  Future<OfflineCommandRecord?> read(String clientOpId);

  Future<void> delete(String clientOpId);

  Future<List<OfflineCommandRecord>> listForContext({
    required String tenantId,
    String? branchId,
    String? accountId,
    Set<OfflineCommandQueueStatus>? statuses,
    int limit = 100,
  });

  Future<List<OfflineCommandRecord>> listReplayReadyForContext({
    required String tenantId,
    String? branchId,
    String? accountId,
    int limit = 100,
  });

  Future<int> countForContext({
    required String tenantId,
    String? branchId,
    String? accountId,
    Set<OfflineCommandQueueStatus>? statuses,
  });
}

class DriftOfflineCommandQueueStore implements OfflineCommandQueueStore {
  DriftOfflineCommandQueueStore(this._db);

  final AppDatabase _db;

  @override
  Future<void> write(OfflineCommandRecord record) {
    return _db
        .into(_db.offlineCommandQueueEntries)
        .insertOnConflictUpdate(
          OfflineCommandQueueEntriesCompanion.insert(
            clientOpId: record.clientOpId.trim(),
            operationType: record.operationType.apiValue,
            tenantId: Value(record.tenantId.trim()),
            branchId: Value(record.branchId.trim()),
            accountId: Value(record.accountId.trim()),
            occurredAt: record.occurredAt,
            payloadJson: record.payloadJson,
            dependsOnClientOpId: Value(record.dependsOnClientOpId?.trim()),
            status: record.status.name,
            retryCount: Value(record.retryCount),
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            lastAttemptAt: Value(record.lastAttemptAt),
            lastSyncedAt: Value(record.lastSyncedAt),
            lastErrorCode: Value(record.lastErrorCode),
            lastErrorMessage: Value(record.lastErrorMessage),
          ),
        );
  }

  @override
  Future<OfflineCommandRecord?> read(String clientOpId) async {
    final row =
        await (_db.select(_db.offlineCommandQueueEntries)
              ..where((tbl) => tbl.clientOpId.equals(clientOpId.trim())))
            .getSingleOrNull();
    if (row == null) return null;
    return _mapRow(row);
  }

  @override
  Future<void> delete(String clientOpId) {
    return (_db.delete(
      _db.offlineCommandQueueEntries,
    )..where((tbl) => tbl.clientOpId.equals(clientOpId.trim()))).go();
  }

  @override
  Future<List<OfflineCommandRecord>> listForContext({
    required String tenantId,
    String? branchId,
    String? accountId,
    Set<OfflineCommandQueueStatus>? statuses,
    int limit = 100,
  }) async {
    final normalizedStatuses = statuses?.map((status) => status.name).toSet();
    final query =
        _baseContextQuery(
            tenantId: tenantId,
            branchId: branchId,
            accountId: accountId,
          )
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.occurredAt),
            (tbl) => OrderingTerm.asc(tbl.createdAt),
          ])
          ..limit(limit);

    if (normalizedStatuses != null && normalizedStatuses.isNotEmpty) {
      query.where((tbl) => tbl.status.isIn(normalizedStatuses));
    }

    final rows = await query.get();
    return rows.map(_mapRow).toList(growable: false);
  }

  @override
  Future<List<OfflineCommandRecord>> listReplayReadyForContext({
    required String tenantId,
    String? branchId,
    String? accountId,
    int limit = 100,
  }) {
    return listForContext(
      tenantId: tenantId,
      branchId: branchId,
      accountId: accountId,
      statuses: const {
        OfflineCommandQueueStatus.pending,
        OfflineCommandQueueStatus.syncing,
      },
      limit: limit,
    );
  }

  @override
  Future<int> countForContext({
    required String tenantId,
    String? branchId,
    String? accountId,
    Set<OfflineCommandQueueStatus>? statuses,
  }) async {
    final normalizedStatuses = statuses?.map((status) => status.name).toSet();
    final query = _baseContextQuery(
      tenantId: tenantId,
      branchId: branchId,
      accountId: accountId,
    );
    if (normalizedStatuses != null && normalizedStatuses.isNotEmpty) {
      query.where((tbl) => tbl.status.isIn(normalizedStatuses));
    }
    return query.get().then((rows) => rows.length);
  }

  SimpleSelectStatement<
    $OfflineCommandQueueEntriesTable,
    OfflineCommandQueueEntry
  >
  _baseContextQuery({
    required String tenantId,
    String? branchId,
    String? accountId,
  }) {
    final normalizedBranchId = (branchId ?? '').trim();
    final normalizedAccountId = (accountId ?? '').trim();
    return _db.select(_db.offlineCommandQueueEntries)
      ..where((tbl) => tbl.tenantId.equals(tenantId.trim()))
      ..where((tbl) => tbl.branchId.equals(normalizedBranchId))
      ..where((tbl) => tbl.accountId.equals(normalizedAccountId));
  }

  OfflineCommandRecord _mapRow(OfflineCommandQueueEntry row) {
    return OfflineCommandRecord(
      clientOpId: row.clientOpId,
      operationType: OfflineOperationType.fromApiValue(row.operationType),
      tenantId: row.tenantId,
      branchId: row.branchId,
      accountId: row.accountId,
      occurredAt: row.occurredAt,
      payloadJson: row.payloadJson,
      dependsOnClientOpId: row.dependsOnClientOpId,
      status: OfflineCommandQueueStatus.values.byName(row.status),
      retryCount: row.retryCount,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastAttemptAt: row.lastAttemptAt,
      lastSyncedAt: row.lastSyncedAt,
      lastErrorCode: row.lastErrorCode,
      lastErrorMessage: row.lastErrorMessage,
    );
  }
}

final offlineCommandQueueStoreProvider = Provider<OfflineCommandQueueStore>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return DriftOfflineCommandQueueStore(db);
});
