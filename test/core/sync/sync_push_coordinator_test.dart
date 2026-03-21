import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/sync/offline_command_queue_store.dart';
import 'package:modular_pos/core/sync/sync_checkpoint_store.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_pull_api.dart';
import 'package:modular_pos/core/sync/sync_pull_orchestrator.dart';
import 'package:modular_pos/core/sync/sync_push_api.dart';
import 'package:modular_pos/core/sync/sync_push_coordinator.dart';

void main() {
  const context = SyncPullContext(
    deviceId: 'device-1',
    tenantId: 'tenant-1',
    branchId: 'branch-1',
    accountId: 'account-1',
  );
  const op1 = '11111111-1111-4111-8111-111111111111';
  const op2 = '22222222-2222-4222-8222-222222222222';

  test(
    'replayPending updates queue rows and triggers pull after success',
    () async {
      final queueStore = _MemoryOfflineCommandQueueStore([
        _record(op1),
        _record(op2),
      ]);
      final api = _FakeSyncPushApi(
        envelope: SyncPushEnvelope(
          pushedAt: DateTime.utc(2026, 3, 17, 10),
          results: const [
            SyncPushResult(
              clientOpId: op1,
              status: SyncPushResultStatus.applied,
            ),
            SyncPushResult(
              clientOpId: op2,
              status: SyncPushResultStatus.duplicate,
            ),
          ],
          rawData: const {},
        ),
      );
      final pullApi = _FakeSyncPullApi(
        envelope: SyncPullEnvelope(
          cursor: 'cursor-1',
          pulledAt: DateTime.utc(2026, 3, 17, 10, 1),
          payloadByScope: const {},
          rawData: const {},
        ),
      );
      final pullOrchestrator = _FakeSyncPullOrchestrator(api: pullApi);
      final coordinator = SyncPushCoordinator(
        queueStore: queueStore,
        api: api,
        pullOrchestrator: pullOrchestrator,
        readBranchWorkspaceScopes: () => const {
          SyncModuleScope.policy,
          SyncModuleScope.cashSession,
          SyncModuleScope.menu,
          SyncModuleScope.attendance,
          SyncModuleScope.shift,
        },
      );

      final result = await coordinator.replayPending(context: context);

      expect(result.outcome, SyncPushReplayOutcome.success);
      expect(result.appliedCount, 1);
      expect(result.duplicateCount, 1);
      expect(
        (await queueStore.read(op1))?.status,
        OfflineCommandQueueStatus.applied,
      );
      expect(
        (await queueStore.read(op2))?.status,
        OfflineCommandQueueStatus.duplicate,
      );
      expect(pullApi.wasCalled, isTrue);
    },
  );

  test(
    'replayPending restores rows to pending on push transport failure',
    () async {
      final queueStore = _MemoryOfflineCommandQueueStore([_record(op1)]);
      final coordinator = SyncPushCoordinator(
        queueStore: queueStore,
        api: _FakeSyncPushApi(
          error: const ApiClientException(
            message: 'Offline',
            code: 'OFFLINE_UNREACHABLE',
          ),
        ),
        pullOrchestrator: _FakeSyncPullOrchestrator(
          api: _FakeSyncPullApi(
            envelope: SyncPullEnvelope(
              cursor: null,
              pulledAt: DateTime.utc(2026, 3, 17, 10),
              payloadByScope: const {},
              rawData: const {},
            ),
          ),
        ),
        readBranchWorkspaceScopes: () => const {SyncModuleScope.policy},
      );

      final result = await coordinator.replayPending(context: context);

      final record = await queueStore.read(op1);
      expect(result.outcome, SyncPushReplayOutcome.pushFailed);
      expect(result.pushErrorCode, 'OFFLINE_UNREACHABLE');
      expect(record?.status, OfflineCommandQueueStatus.pending);
      expect(record?.lastErrorCode, 'OFFLINE_UNREACHABLE');
    },
  );

  test(
    'replayPending repairs legacy non-UUID client op ids before push',
    () async {
      const legacyClientOpId = 'sale-outage-local-1';
      final queueStore = _MemoryOfflineCommandQueueStore([
        OfflineCommandRecord(
          clientOpId: legacyClientOpId,
          operationType: OfflineOperationType.checkoutCashFinalize,
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'account-1',
          occurredAt: DateTime.utc(2026, 3, 17, 9),
          payloadJson: '{"orderId":"order-1","saleId":"sale-1"}',
          status: OfflineCommandQueueStatus.pending,
          retryCount: 0,
          createdAt: DateTime.utc(2026, 3, 17, 9),
          updatedAt: DateTime.utc(2026, 3, 17, 9),
        ),
      ]);
      final api = _FakeSyncPushApi(
        envelopeBuilder: (operations) => SyncPushEnvelope(
          pushedAt: DateTime.utc(2026, 3, 17, 10),
          results: operations
              .map(
                (record) => SyncPushResult(
                  clientOpId: record.clientOpId,
                  status: SyncPushResultStatus.applied,
                ),
              )
              .toList(growable: false),
          rawData: const {},
        ),
      );
      final coordinator = SyncPushCoordinator(
        queueStore: queueStore,
        api: api,
        pullOrchestrator: _FakeSyncPullOrchestrator(
          api: _FakeSyncPullApi(
            envelope: SyncPullEnvelope(
              cursor: null,
              pulledAt: DateTime.utc(2026, 3, 17, 10),
              payloadByScope: const {},
              rawData: const {},
            ),
          ),
        ),
        readBranchWorkspaceScopes: () => const {SyncModuleScope.policy},
      );

      final result = await coordinator.replayPending(context: context);
      final repairedRecords = await queueStore.listForContext(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'account-1',
      );

      expect(result.outcome, SyncPushReplayOutcome.success);
      expect(await queueStore.read(legacyClientOpId), isNull);
      expect(repairedRecords, hasLength(1));
      expect(
        repairedRecords.single.clientOpId,
        matches(
          RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
          ),
        ),
      );
      expect(
        repairedRecords.single.decodePayload()['localIntentId'],
        legacyClientOpId,
      );
      expect(
        api.lastOperations.single.clientOpId,
        repairedRecords.single.clientOpId,
      );
    },
  );

  test(
    'replayPending persists resultRefId into applied operation payloads',
    () async {
      const clientOpId = '33333333-3333-4333-8333-333333333333';
      final queueStore = _MemoryOfflineCommandQueueStore([
        OfflineCommandRecord(
          clientOpId: clientOpId,
          operationType:
              OfflineOperationType.orderManualExternalPaymentClaimCapture,
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'account-1',
          occurredAt: DateTime.utc(2026, 3, 20, 9),
          payloadJson:
              '{"localIntentId":"local-claim-1","orderId":"client-order-1","items":[]}',
          status: OfflineCommandQueueStatus.pending,
          retryCount: 0,
          createdAt: DateTime.utc(2026, 3, 20, 9),
          updatedAt: DateTime.utc(2026, 3, 20, 9),
        ),
      ]);
      final api = _FakeSyncPushApi(
        envelope: SyncPushEnvelope(
          pushedAt: DateTime.utc(2026, 3, 20, 10),
          results: const [
            SyncPushResult(
              clientOpId: clientOpId,
              status: SyncPushResultStatus.applied,
              resultRefId: 'order-materialized-1',
            ),
          ],
          rawData: const {},
        ),
      );
      final coordinator = SyncPushCoordinator(
        queueStore: queueStore,
        api: api,
        pullOrchestrator: _FakeSyncPullOrchestrator(
          api: _FakeSyncPullApi(
            envelope: SyncPullEnvelope(
              cursor: null,
              pulledAt: DateTime.utc(2026, 3, 20, 10),
              payloadByScope: const {},
              rawData: const {},
            ),
          ),
        ),
        readBranchWorkspaceScopes: () => const {SyncModuleScope.policy},
      );

      await coordinator.replayPending(context: context);

      final persisted = await queueStore.read(clientOpId);
      expect(persisted?.status, OfflineCommandQueueStatus.applied);
      expect(persisted?.decodePayload()['resultRefId'], 'order-materialized-1');
    },
  );
}

OfflineCommandRecord _record(String clientOpId) {
  final createdAt = DateTime.utc(2026, 3, 17, 9);
  return OfflineCommandRecord(
    clientOpId: clientOpId,
    operationType: OfflineOperationType.cashSessionOpen,
    tenantId: 'tenant-1',
    branchId: 'branch-1',
    accountId: 'account-1',
    occurredAt: createdAt,
    payloadJson: '{}',
    status: OfflineCommandQueueStatus.pending,
    retryCount: 0,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

class _MemoryOfflineCommandQueueStore implements OfflineCommandQueueStore {
  _MemoryOfflineCommandQueueStore(Iterable<OfflineCommandRecord> seed) {
    for (final record in seed) {
      _records[record.clientOpId] = record;
    }
  }

  final Map<String, OfflineCommandRecord> _records =
      <String, OfflineCommandRecord>{};

  @override
  Future<int> countForContext({
    required String tenantId,
    String? branchId,
    String? accountId,
    Set<OfflineCommandQueueStatus>? statuses,
  }) async {
    return listForContext(
      tenantId: tenantId,
      branchId: branchId,
      accountId: accountId,
      statuses: statuses,
    ).then((records) => records.length);
  }

  @override
  Future<List<OfflineCommandRecord>> listForContext({
    required String tenantId,
    String? branchId,
    String? accountId,
    Set<OfflineCommandQueueStatus>? statuses,
    int limit = 100,
  }) async {
    final normalizedBranchId = (branchId ?? '').trim();
    final normalizedAccountId = (accountId ?? '').trim();
    final filtered = _records.values.where((record) {
      final matchesContext =
          record.tenantId == tenantId &&
          record.branchId == normalizedBranchId &&
          record.accountId == normalizedAccountId;
      final matchesStatus =
          statuses == null || statuses.contains(record.status);
      return matchesContext && matchesStatus;
    }).toList()..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return filtered.take(limit).toList(growable: false);
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
  Future<OfflineCommandRecord?> read(String clientOpId) async {
    return _records[clientOpId];
  }

  @override
  Future<void> delete(String clientOpId) async {
    _records.remove(clientOpId);
  }

  @override
  Future<void> write(OfflineCommandRecord record) async {
    _records[record.clientOpId] = record;
  }
}

class _FakeSyncPushApi extends SyncPushApi {
  _FakeSyncPushApi({this.envelope, this.envelopeBuilder, this.error})
    : super(Dio());

  final SyncPushEnvelope? envelope;
  final SyncPushEnvelope Function(List<OfflineCommandRecord> operations)?
  envelopeBuilder;
  final Object? error;
  List<OfflineCommandRecord> lastOperations = const [];

  @override
  Future<SyncPushEnvelope> push({
    required SyncPullContext context,
    required List<OfflineCommandRecord> operations,
  }) async {
    lastOperations = operations;
    if (error != null) throw error!;
    return envelopeBuilder?.call(operations) ?? envelope!;
  }
}

class _FakeSyncPullApi extends SyncPullApi {
  _FakeSyncPullApi({this.envelope}) : super(Dio());

  final SyncPullEnvelope? envelope;
  var wasCalled = false;

  @override
  Future<SyncPullEnvelope> pull({
    required SyncPullContext context,
    required Set<SyncModuleScope> moduleScopes,
    String? cursor,
  }) async {
    wasCalled = true;
    return envelope!;
  }
}

class _FakeSyncPullOrchestrator extends SyncPullOrchestrator {
  _FakeSyncPullOrchestrator({required _FakeSyncPullApi api})
    : _api = api,
      super(
        api: api,
        checkpointStore: _MemorySyncCheckpointStore(),
        consumers: const [],
        status: _NoopSyncPullRunStateController(),
      );

  final _FakeSyncPullApi _api;

  @override
  Future<SyncPullEnvelope> pull({
    required SyncPullContext context,
    required Set<SyncModuleScope> moduleScopes,
    bool forceBootstrap = false,
  }) {
    return _api.pull(
      context: context,
      moduleScopes: moduleScopes,
      cursor: null,
    );
  }
}

class _MemorySyncCheckpointStore implements SyncCheckpointStore {
  final Map<String, SyncCheckpointRecord> _records =
      <String, SyncCheckpointRecord>{};

  @override
  Future<void> clear({
    required String deviceId,
    required String tenantId,
    String? branchId,
    String? accountId,
    required String moduleScopeSetKey,
  }) async {
    _records.remove(
      '$deviceId|$tenantId|${branchId ?? ''}|${accountId ?? ''}|$moduleScopeSetKey',
    );
  }

  @override
  Future<SyncCheckpointRecord?> read({
    required String deviceId,
    required String tenantId,
    String? branchId,
    String? accountId,
    required String moduleScopeSetKey,
  }) async {
    return _records['$deviceId|$tenantId|${branchId ?? ''}|${accountId ?? ''}|$moduleScopeSetKey'];
  }

  @override
  Future<void> write(SyncCheckpointRecord record) async {
    _records['${record.deviceId}|${record.tenantId}|${record.branchId}|${record.accountId}|${record.moduleScopeSetKey}'] =
        record;
  }
}

class _NoopSyncPullRunStateController extends SyncPullRunStateController {
  @override
  void markFailure(
    SyncPullContext context,
    String moduleScopeSetKey,
    DateTime failedAt, {
    String? errorCode,
  }) {}

  @override
  void markRunning(SyncPullContext context, String moduleScopeSetKey) {}

  @override
  void markSuccess(
    SyncPullContext context,
    String moduleScopeSetKey,
    DateTime pulledAt,
  ) {}
}
