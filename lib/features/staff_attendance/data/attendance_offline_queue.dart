import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/sync/offline_command_queue_store.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_cache_store.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_repository_contract.dart';

final attendanceOfflineQueueProvider = Provider<AttendanceOfflineQueue>((ref) {
  return AttendanceOfflineQueue(
    queueStore: ref.read(offlineCommandQueueStoreProvider),
  );
});

class AttendanceOfflineQueue {
  AttendanceOfflineQueue({required OfflineCommandQueueStore queueStore})
    : _queueStore = queueStore;

  final OfflineCommandQueueStore _queueStore;

  Future<OfflineCommandRecord> enqueueCheckIn({
    required AttendanceCacheScope scope,
    required AttendanceCheckInPayload payload,
  }) {
    return _enqueue(
      scope: scope,
      clientOpId: payload.clientOpId,
      operationType: OfflineOperationType.attendanceStartWork,
      occurredAt: payload.clientTs,
      payloadJson: jsonEncode(payload.toJson()),
    );
  }

  Future<OfflineCommandRecord> enqueueCheckOut({
    required AttendanceCacheScope scope,
    required AttendanceCheckOutPayload payload,
  }) {
    return _enqueue(
      scope: scope,
      clientOpId: payload.clientOpId,
      operationType: OfflineOperationType.attendanceEndWork,
      occurredAt: payload.clientTs,
      payloadJson: jsonEncode(payload.toJson()),
    );
  }

  Future<OfflineCommandRecord> _enqueue({
    required AttendanceCacheScope scope,
    required String clientOpId,
    required OfflineOperationType operationType,
    required String occurredAt,
    required String payloadJson,
  }) async {
    final occurredAtValue =
        DateTime.tryParse(occurredAt)?.toUtc() ?? DateTime.now().toUtc();
    final timestamp = DateTime.now().toUtc();
    final record = OfflineCommandRecord(
      clientOpId: clientOpId,
      operationType: operationType,
      tenantId: scope.tenantId,
      branchId: scope.branchId,
      accountId: scope.accountId,
      occurredAt: occurredAtValue,
      payloadJson: payloadJson,
      status: OfflineCommandQueueStatus.pending,
      retryCount: 0,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await _queueStore.write(record);
    return record;
  }
}
