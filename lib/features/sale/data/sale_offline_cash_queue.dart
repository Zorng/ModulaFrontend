import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/sync/offline_command_queue_store.dart';
import 'package:modular_pos/features/sale/data/sale_outage_store.dart';
import 'package:modular_pos/features/sale/domain/models/sale_outage_order.dart';
import 'package:uuid/uuid.dart';

final saleOfflineCashQueueProvider = Provider<SaleOfflineCashQueue>((ref) {
  return SaleOfflineCashQueue(
    queueStore: ref.read(offlineCommandQueueStoreProvider),
    outageStore: ref.read(saleOutageStoreProvider),
  );
});

class SaleOfflineCashQueue {
  SaleOfflineCashQueue({
    required OfflineCommandQueueStore queueStore,
    required SaleOutageStore outageStore,
    Uuid? uuid,
  }) : _queueStore = queueStore,
       _outageStore = outageStore,
       _uuid = uuid ?? const Uuid();

  final OfflineCommandQueueStore _queueStore;
  final SaleOutageStore _outageStore;
  final Uuid _uuid;

  Future<OfflineCommandRecord> enqueueCheckoutCashFinalize({
    required SaleOutageScope scope,
    required String localIntentId,
    required DateTime occurredAt,
    required Map<String, dynamic> payload,
  }) async {
    final timestamp = DateTime.now().toUtc();
    final normalizedPayload = Map<String, dynamic>.from(payload);
    final normalizedLocalIntentId = localIntentId.trim();
    if ((normalizedPayload['localIntentId'] ?? '').toString().trim().isEmpty) {
      normalizedPayload['localIntentId'] = normalizedLocalIntentId;
    }
    final record = OfflineCommandRecord(
      clientOpId: _uuid.v4(),
      operationType: OfflineOperationType.checkoutCashFinalize,
      tenantId: scope.tenantId,
      branchId: scope.branchId,
      accountId: scope.accountId,
      occurredAt: occurredAt.toUtc(),
      payloadJson: jsonEncode(normalizedPayload),
      status: OfflineCommandQueueStatus.pending,
      retryCount: 0,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await _queueStore.write(record);
    return record;
  }

  Future<OfflineCommandRecord> enqueueManualExternalPaymentClaimCapture({
    required SaleOutageScope scope,
    required String localIntentId,
    required DateTime occurredAt,
    required Map<String, dynamic> payload,
  }) async {
    final timestamp = DateTime.now().toUtc();
    final normalizedPayload = Map<String, dynamic>.from(payload);
    final normalizedLocalIntentId = localIntentId.trim();
    if ((normalizedPayload['localIntentId'] ?? '').toString().trim().isEmpty) {
      normalizedPayload['localIntentId'] = normalizedLocalIntentId;
    }
    final record = OfflineCommandRecord(
      clientOpId: _uuid.v4(),
      operationType:
          OfflineOperationType.orderManualExternalPaymentClaimCapture,
      tenantId: scope.tenantId,
      branchId: scope.branchId,
      accountId: scope.accountId,
      occurredAt: occurredAt.toUtc(),
      payloadJson: jsonEncode(normalizedPayload),
      status: OfflineCommandQueueStatus.pending,
      retryCount: 0,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await _queueStore.write(record);
    return record;
  }

  Future<int> repairQueuedCashReplayPayloads({
    required SaleOutageScope scope,
    int limit = 200,
  }) async {
    final outageRecords = await _outageStore.list(scope);
    if (outageRecords.isEmpty) return 0;

    final outageByLocalIntentId = {
      for (final record in outageRecords)
        if (_isStandardCashOutage(record)) record.localIntentId: record,
    };
    if (outageByLocalIntentId.isEmpty) return 0;

    final queue = await _queueStore.listForContext(
      tenantId: scope.tenantId,
      branchId: scope.branchId,
      accountId: scope.accountId,
      statuses: const {
        OfflineCommandQueueStatus.pending,
        OfflineCommandQueueStatus.syncing,
        OfflineCommandQueueStatus.failed,
      },
      limit: limit,
    );

    var repairedCount = 0;
    for (final record in queue) {
      if (record.operationType != OfflineOperationType.checkoutCashFinalize) {
        continue;
      }

      final payload = record.decodePayload();
      final localIntentId = _resolveLocalIntentId(record, payload);
      if (localIntentId.isEmpty) continue;

      final outageRecord = outageByLocalIntentId[localIntentId];
      if (outageRecord == null) continue;

      final repairedPayload = _repairReplayPayload(
        payload: payload,
        record: outageRecord,
        localIntentId: localIntentId,
      );
      final payloadChanged = jsonEncode(repairedPayload) != jsonEncode(payload);
      final shouldRetryAfterRepair = _shouldRetryAfterRepair(record);
      if (!payloadChanged && !shouldRetryAfterRepair) continue;

      final updatedRecord = shouldRetryAfterRepair
          ? record.copyWith(
              payloadJson: jsonEncode(repairedPayload),
              status: OfflineCommandQueueStatus.pending,
              updatedAt: DateTime.now().toUtc(),
              lastErrorCode: null,
              lastErrorMessage: null,
            )
          : record.copyWith(
              payloadJson: jsonEncode(repairedPayload),
              updatedAt: DateTime.now().toUtc(),
            );
      await _queueStore.write(updatedRecord);
      repairedCount += 1;
    }

    return repairedCount;
  }

  Future<int> backfillManualClaimCaptureOperations({
    required SaleOutageScope scope,
    int limit = 200,
  }) async {
    final outageRecords = await _outageStore.list(scope);
    if (outageRecords.isEmpty) return 0;

    final candidateOutages = outageRecords
        .where((record) {
          return _isManualClaimOutage(record) &&
              (record.backendOrderId ?? '').trim().isEmpty;
        })
        .toList(growable: false);
    if (candidateOutages.isEmpty) return 0;

    final queueRecords = await _queueStore.listForContext(
      tenantId: scope.tenantId,
      branchId: scope.branchId,
      statuses: const {
        OfflineCommandQueueStatus.pending,
        OfflineCommandQueueStatus.syncing,
        OfflineCommandQueueStatus.applied,
        OfflineCommandQueueStatus.duplicate,
        OfflineCommandQueueStatus.failed,
      },
      limit: limit,
    );
    final queuedLocalIntentIds = <String>{
      for (final record in queueRecords)
        if (record.operationType ==
            OfflineOperationType.orderManualExternalPaymentClaimCapture)
          _resolveLocalIntentId(record, record.decodePayload()),
    };

    var enqueuedCount = 0;
    for (final outageRecord in candidateOutages) {
      if (queuedLocalIntentIds.contains(outageRecord.localIntentId)) {
        continue;
      }
      await enqueueManualExternalPaymentClaimCapture(
        scope: scope,
        localIntentId: outageRecord.localIntentId,
        occurredAt: outageRecord.createdAt,
        payload: _buildManualClaimCapturePayloadFromRecord(outageRecord),
      );
      queuedLocalIntentIds.add(outageRecord.localIntentId);
      enqueuedCount += 1;
    }
    return enqueuedCount;
  }

  bool _isStandardCashOutage(SaleOutageOrderRecord record) {
    return SaleOutageSourceModes.normalize(record.sourceMode) ==
            SaleOutageSourceModes.standardOpenOrder &&
        record.paymentMethodRequested.trim().toLowerCase() == 'cash';
  }

  bool _isManualClaimOutage(SaleOutageOrderRecord record) {
    return SaleOutageSourceModes.normalize(record.sourceMode) ==
            SaleOutageSourceModes.manualExternalPaymentClaim &&
        record.paymentMethodRequested.trim().toLowerCase() == 'qr';
  }

  String _resolveLocalIntentId(
    OfflineCommandRecord record,
    Map<String, dynamic> payload,
  ) {
    final payloadLocalIntentId = (payload['localIntentId'] ?? '')
        .toString()
        .trim();
    if (payloadLocalIntentId.isNotEmpty) return payloadLocalIntentId;
    return record.clientOpId.trim();
  }

  Map<String, dynamic> _repairReplayPayload({
    required Map<String, dynamic> payload,
    required SaleOutageOrderRecord record,
    required String localIntentId,
  }) {
    final repaired = Map<String, dynamic>.from(payload);
    repaired['localIntentId'] = localIntentId;

    final rawItems = repaired['items'];
    final existingItems = rawItems is List ? rawItems : const <dynamic>[];
    final repairedItems = <Map<String, dynamic>>[];
    final maxLength = existingItems.length > record.lines.length
        ? existingItems.length
        : record.lines.length;

    for (var index = 0; index < maxLength; index += 1) {
      final existingItem = index < existingItems.length
          ? _asMutableMap(existingItems[index])
          : <String, dynamic>{};
      final outageLine = index < record.lines.length
          ? record.lines[index]
          : null;
      if (outageLine == null) {
        repairedItems.add(existingItem);
        continue;
      }

      existingItem['menuItemId'] =
          (existingItem['menuItemId'] ?? outageLine.menuItemId).toString();
      existingItem['menuItemNameSnapshot'] =
          (existingItem['menuItemNameSnapshot'] ?? outageLine.name).toString();
      existingItem['unitPrice'] = _normalizedAmount(
        existingItem['unitPrice'] ?? existingItem['unitPriceUsd'],
        outageLine.unitPriceUsd,
      );
      existingItem['quantity'] = _normalizedQuantity(
        existingItem['quantity'],
        outageLine.quantity,
      );
      existingItem['lineSubtotal'] = _normalizedAmount(
        existingItem['lineSubtotal'] ?? existingItem['lineTotalUsdExact'],
        outageLine.lineTotalUsdExact,
      );
      existingItem['modifierSnapshot'] = _normalizedModifierSnapshot(
        existingItem['modifierSnapshot'],
        outageLine.modifierLabels,
      );
      final existingSelections = existingItem['modifierSelections'];
      if (existingSelections is! List || existingSelections.isEmpty) {
        final selections = _buildModifierSelections(outageLine);
        if (selections.isNotEmpty) {
          existingItem['modifierSelections'] = selections;
        }
      }

      repairedItems.add(existingItem);
    }

    repaired['items'] = repairedItems;
    return repaired;
  }

  Map<String, dynamic> _buildManualClaimCapturePayloadFromRecord(
    SaleOutageOrderRecord record,
  ) {
    return <String, dynamic>{
      'localIntentId': record.localIntentId,
      'orderId': _uuid.v4(),
      'items': record.lines
          .map(
            (line) => <String, dynamic>{
              'menuItemId': line.menuItemId,
              'menuItemNameSnapshot': line.name,
              'unitPrice': line.unitPriceUsd,
              'quantity': line.quantity,
              'lineSubtotal': line.lineTotalUsdExact,
              'modifierSnapshot': line.modifierLabels
                  .map(
                    (label) => <String, dynamic>{
                      'label': label,
                      'priceAdjustmentUsd': 0,
                    },
                  )
                  .toList(growable: false),
              if (line.selectedOptionIds.isNotEmpty)
                'modifierSelections': _buildModifierSelections(line),
            },
          )
          .toList(growable: false),
    };
  }

  Map<String, dynamic> _asMutableMap(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }

  int _normalizedQuantity(dynamic value, int fallback) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  double _normalizedAmount(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  List<Map<String, dynamic>> _normalizedModifierSnapshot(
    dynamic value,
    List<String> fallbackLabels,
  ) {
    if (value is List) {
      final normalized = <Map<String, dynamic>>[];
      for (final item in value) {
        if (item is Map<String, dynamic>) {
          normalized.add(Map<String, dynamic>.from(item));
          continue;
        }
        if (item is Map) {
          normalized.add(
            item.map((key, payload) => MapEntry(key.toString(), payload)),
          );
          continue;
        }
        if (item != null) {
          normalized.add(<String, dynamic>{'label': item.toString()});
        }
      }
      return normalized;
    }
    return fallbackLabels
        .map(
          (label) => <String, dynamic>{'label': label, 'priceAdjustmentUsd': 0},
        )
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _buildModifierSelections(
    SaleOutageLineSnapshot line,
  ) {
    final selections = <Map<String, dynamic>>[];
    final sortedGroupIds = line.selectedOptionIds.keys.toList()..sort();
    for (final groupId in sortedGroupIds) {
      final optionIds = List<String>.from(line.selectedOptionIds[groupId] ?? [])
        ..sort();
      if (optionIds.isEmpty) continue;
      selections.add(<String, dynamic>{
        'groupId': groupId,
        'optionIds': optionIds,
      });
    }
    return selections;
  }

  bool _shouldRetryAfterRepair(OfflineCommandRecord record) {
    if (record.status != OfflineCommandQueueStatus.failed) return false;
    if ((record.lastErrorCode ?? '').trim() != 'SALE_ORDER_VALIDATION_FAILED') {
      return false;
    }
    final message = (record.lastErrorMessage ?? '').trim();
    return message.contains('menuItemNameSnapshot') ||
        message.contains('modifierLabels') ||
        message.contains('modifierSnapshot') ||
        message.contains('unitPrice') ||
        message.contains('lineSubtotal');
  }
}
