import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/sync/offline_command_queue_store.dart';
import 'package:uuid/uuid.dart';

typedef CashSessionOfflineQueueNow = DateTime Function();

final cashSessionOfflineQueueNowProvider = Provider<CashSessionOfflineQueueNow>(
  (ref) {
    return DateTime.now;
  },
);

final cashSessionOfflineQueueProvider = Provider<CashSessionOfflineQueue>((
  ref,
) {
  return CashSessionOfflineQueue(
    queueStore: ref.read(offlineCommandQueueStoreProvider),
    now: ref.read(cashSessionOfflineQueueNowProvider),
  );
});

class CashSessionOfflineQueue {
  CashSessionOfflineQueue({
    required OfflineCommandQueueStore queueStore,
    required CashSessionOfflineQueueNow now,
    Uuid? uuid,
  }) : _queueStore = queueStore,
       _now = now,
       _uuid = uuid ?? const Uuid();

  final OfflineCommandQueueStore _queueStore;
  final CashSessionOfflineQueueNow _now;
  final Uuid _uuid;

  Future<OfflineCommandRecord> enqueueOpenSession({
    required String tenantId,
    required String branchId,
    required String accountId,
    required double openingFloatUsd,
    required double openingFloatKhr,
    String? note,
  }) {
    final payload = <String, dynamic>{
      'openingFloatUsd': openingFloatUsd,
      'openingFloatKhr': openingFloatKhr,
      if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
    };
    return _enqueue(
      operationType: OfflineOperationType.cashSessionOpen,
      tenantId: tenantId,
      branchId: branchId,
      accountId: accountId,
      payload: payload,
    );
  }

  Future<OfflineCommandRecord> enqueueCloseSession({
    required String tenantId,
    required String branchId,
    required String accountId,
    required String sessionId,
    required double countedCashUsd,
    required double countedCashKhr,
    String? note,
  }) {
    final payload = <String, dynamic>{
      'sessionId': sessionId,
      'countedCashUsd': countedCashUsd,
      'countedCashKhr': countedCashKhr,
      if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
    };
    return _enqueue(
      operationType: OfflineOperationType.cashSessionClose,
      tenantId: tenantId,
      branchId: branchId,
      accountId: accountId,
      payload: payload,
    );
  }

  Future<OfflineCommandRecord> enqueueMovement({
    required String tenantId,
    required String branchId,
    required String accountId,
    required String sessionId,
    required String movementType,
    required String reason,
    required double amountUsd,
    required double amountKhr,
    required double amountUsdDelta,
    required double amountKhrDelta,
  }) {
    final payload = <String, dynamic>{
      'sessionId': sessionId,
      'movementType': movementType.trim().toUpperCase(),
      'reason': reason.trim(),
      if (amountUsd != 0) 'amountUsd': amountUsd,
      if (amountKhr != 0) 'amountKhr': amountKhr,
      if (amountUsdDelta != 0) 'amountUsdDelta': amountUsdDelta,
      if (amountKhrDelta != 0) 'amountKhrDelta': amountKhrDelta,
    };
    return _enqueue(
      operationType: OfflineOperationType.cashSessionMovement,
      tenantId: tenantId,
      branchId: branchId,
      accountId: accountId,
      payload: payload,
    );
  }

  Future<OfflineCommandRecord> _enqueue({
    required OfflineOperationType operationType,
    required String tenantId,
    required String branchId,
    required String accountId,
    required Map<String, dynamic> payload,
  }) async {
    final timestamp = _now().toUtc();
    final record = OfflineCommandRecord(
      clientOpId: _uuid.v4(),
      operationType: operationType,
      tenantId: tenantId.trim(),
      branchId: branchId.trim(),
      accountId: accountId.trim(),
      occurredAt: timestamp,
      payloadJson: jsonEncode(payload),
      status: OfflineCommandQueueStatus.pending,
      retryCount: 0,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await _queueStore.write(record);
    return record;
  }
}
