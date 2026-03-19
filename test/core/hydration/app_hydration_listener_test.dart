import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/app_connectivity.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/core/hydration/app_hydration_listener.dart';
import 'package:modular_pos/core/hydration/context_scoped_runtime_resource.dart';
import 'package:modular_pos/core/sync/offline_command_queue_store.dart';
import 'package:modular_pos/core/sync/sync_checkpoint_store.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_pull_api.dart';
import 'package:modular_pos/core/sync/sync_pull_orchestrator.dart';
import 'package:modular_pos/core/sync/sync_pull_trigger_controller.dart';
import 'package:modular_pos/core/sync/sync_push_api.dart';
import 'package:modular_pos/core/sync/sync_push_coordinator.dart';
import 'package:modular_pos/core/sync/sync_push_trigger_controller.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_tenant_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_token_provider.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/data/sale_offline_cash_queue.dart';
import 'package:modular_pos/features/sale/data/sale_outage_store.dart';
import 'package:modular_pos/features/sale/domain/models/sale_outage_order.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_outage_recovery_controller.dart';

import '../../test_utils/riverpod_test_utils.dart';

class _TestHarness extends StatelessWidget {
  const _TestHarness({required this.container, required this.child});

  final ProviderContainer container;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: child),
    );
  }
}

class _TestLoginController extends LoginController {
  @override
  LoginState build() => const LoginState();

  void setSession(AuthSession? session) {
    state = LoginState(session: session);
  }
}

class _TestPolicyNotifier extends PolicyNotifier {
  int resetCount = 0;
  int loadCount = 0;
  final loadedBranchIds = <String?>[];

  @override
  PolicyState build() => const PolicyState();

  @override
  Future<void> load() {
    loadCount += 1;
    loadedBranchIds.add(ref.read(authActiveBranchIdProvider));
    return Future.value();
  }

  @override
  void reset() {
    resetCount += 1;
    super.reset();
  }
}

class _TestCashSessionViewModel extends CashSessionViewModel {
  int resetCount = 0;
  int loadCount = 0;
  final loadedBranchIds = <String?>[];

  @override
  CashSessionState build() => const CashSessionState();

  @override
  Future<void> load() {
    loadCount += 1;
    loadedBranchIds.add(ref.read(authActiveBranchIdProvider));
    return Future.value();
  }

  @override
  void reset() {
    resetCount += 1;
    super.reset();
  }
}

class _TestContextScopedResource implements ContextScopedRuntimeResource {
  int clearedCount = 0;
  int reboundCount = 0;
  final List<(String token, String tenantId, String branchId)> rebinds = [];

  @override
  Future<void> onContextCleared() async {
    clearedCount += 1;
  }

  @override
  Future<void> onContextChanged({
    required String accessToken,
    required String tenantId,
    required String branchId,
  }) async {
    reboundCount += 1;
    rebinds.add((accessToken, tenantId, branchId));
  }
}

class _TestSyncPullTriggerController extends SyncPullTriggerController {
  _TestSyncPullTriggerController()
    : super(
        orchestrator: SyncPullOrchestrator(
          api: _NoopSyncPullApi(),
          checkpointStore: _NoopSyncCheckpointStore(),
          consumers: const <SyncPullConsumer>[],
          status: _NoopSyncPullRunStateController(),
        ),
        readContext: () => null,
        readBranchWorkspaceScopes: () => const <SyncModuleScope>{},
        now: DateTime.now,
        cooldown: Duration.zero,
      );

  final calls = <(SyncPullTrigger trigger, SyncPullContext? context)>[];

  @override
  Future<SyncPullTriggerResult> triggerBranchWorkspace({
    required SyncPullTrigger trigger,
    SyncPullContext? contextOverride,
    bool forceBootstrap = false,
  }) async {
    calls.add((trigger, contextOverride));
    return SyncPullTriggerResult(
      trigger: trigger,
      outcome: SyncPullTriggerOutcome.success,
      context: contextOverride,
    );
  }
}

class _TestSyncPushTriggerController extends SyncPushTriggerController {
  _TestSyncPushTriggerController()
    : super(
        coordinator: _NoopSyncPushCoordinator(),
        readContext: () => null,
        now: DateTime.now,
        cooldown: Duration.zero,
      );

  final calls = <(SyncPushTrigger trigger, SyncPullContext? context)>[];
  SyncPushTriggerResult nextResult = const SyncPushTriggerResult(
    trigger: SyncPushTrigger.reconnect,
    outcome: SyncPushTriggerOutcome.noPending,
  );

  @override
  Future<SyncPushTriggerResult> triggerBranchWorkspace({
    required SyncPushTrigger trigger,
    SyncPullContext? contextOverride,
    bool bypassCooldown = false,
    int limit = 50,
  }) async {
    calls.add((trigger, contextOverride));
    return SyncPushTriggerResult(
      trigger: trigger,
      outcome: nextResult.outcome,
      context: contextOverride,
      replayResult: nextResult.replayResult,
      errorCode: nextResult.errorCode,
    );
  }
}

class _TestSaleOutageRecoveryController extends SaleOutageRecoveryController {
  _TestSaleOutageRecoveryController()
    : super(
        readScope: () => null,
        readConnectivity: () => AppConnectivityStatus.online,
        loadOrders: ({DateTime? date}) async {},
        readOrders: () => const <Order>[],
        submitManualClaim: (_) async {},
        now: DateTime.now,
        cooldown: Duration.zero,
      );

  final calls = <(SaleOutageRecoveryTrigger trigger, SaleOutageScope? scope)>[];

  @override
  Future<SaleOutageRecoveryResult> recoverBranchWorkspace({
    required SaleOutageRecoveryTrigger trigger,
    SaleOutageScope? scopeOverride,
    bool bypassCooldown = false,
  }) async {
    calls.add((trigger, scopeOverride));
    return SaleOutageRecoveryResult(
      trigger: trigger,
      outcome: SaleOutageRecoveryOutcome.noPending,
      scope: scopeOverride,
    );
  }
}

class _NoopSyncPullApi extends SyncPullApi {
  _NoopSyncPullApi() : super(Dio());

  @override
  Future<SyncPullEnvelope> pull({
    required SyncPullContext context,
    required Set<SyncModuleScope> moduleScopes,
    String? cursor,
  }) {
    throw UnimplementedError();
  }
}

class _NoopSyncCheckpointStore implements SyncCheckpointStore {
  @override
  Future<void> clear({
    required String deviceId,
    required String tenantId,
    String? branchId,
    String? accountId,
    required String moduleScopeSetKey,
  }) async {}

  @override
  Future<SyncCheckpointRecord?> read({
    required String deviceId,
    required String tenantId,
    String? branchId,
    String? accountId,
    required String moduleScopeSetKey,
  }) async {
    return null;
  }

  @override
  Future<void> write(SyncCheckpointRecord record) async {}
}

class _NoopSyncPullRunStateController extends SyncPullRunStateController {
  @override
  SyncPullRunState build() => const SyncPullRunState();
}

class _NoopSyncPushCoordinator extends SyncPushCoordinator {
  _NoopSyncPushCoordinator()
    : super(
        queueStore: _NoopOfflineCommandQueueStore(),
        api: _NoopSyncPushApi(),
        pullOrchestrator: _NoopSyncPullOrchestrator(),
        readBranchWorkspaceScopes: () => const <SyncModuleScope>{},
      );
}

class _NoopOfflineCommandQueueStore implements OfflineCommandQueueStore {
  @override
  Future<int> countForContext({
    required String tenantId,
    String? branchId,
    String? accountId,
    Set<OfflineCommandQueueStatus>? statuses,
  }) async {
    return 0;
  }

  @override
  Future<List<OfflineCommandRecord>> listForContext({
    required String tenantId,
    String? branchId,
    String? accountId,
    Set<OfflineCommandQueueStatus>? statuses,
    int limit = 100,
  }) async {
    return const <OfflineCommandRecord>[];
  }

  @override
  Future<List<OfflineCommandRecord>> listReplayReadyForContext({
    required String tenantId,
    String? branchId,
    String? accountId,
    int limit = 100,
  }) async {
    return const <OfflineCommandRecord>[];
  }

  @override
  Future<OfflineCommandRecord?> read(String clientOpId) async {
    return null;
  }

  @override
  Future<void> delete(String clientOpId) async {}

  @override
  Future<void> write(OfflineCommandRecord record) async {}
}

class _NoopSaleOutageStore implements SaleOutageStore {
  @override
  Future<void> clearScope(SaleOutageScope scope) async {}

  @override
  Future<void> deleteByLocalIntentId({
    required SaleOutageScope scope,
    required String localIntentId,
  }) async {}

  @override
  Future<List<SaleOutageOrderRecord>> list(SaleOutageScope scope) async {
    return const <SaleOutageOrderRecord>[];
  }

  @override
  Future<SaleOutageOrderRecord?> readByLocalIntentId({
    required SaleOutageScope scope,
    required String localIntentId,
  }) async {
    return null;
  }

  @override
  Future<void> write(SaleOutageOrderRecord record) async {}
}

class _NoopSyncPushApi extends SyncPushApi {
  _NoopSyncPushApi() : super(Dio());

  @override
  Future<SyncPushEnvelope> push({
    required SyncPullContext context,
    required List<OfflineCommandRecord> operations,
  }) {
    throw UnimplementedError();
  }
}

class _NoopSyncPullOrchestrator extends SyncPullOrchestrator {
  _NoopSyncPullOrchestrator()
    : super(
        api: _NoopSyncPullApi(),
        checkpointStore: _NoopSyncCheckpointStore(),
        consumers: const <SyncPullConsumer>[],
        status: _NoopSyncPullRunStateController(),
      );
}

class _TestConnectivityStatusNotifier extends AppConnectivityStatusController {
  @override
  AppConnectivityStatus build() => AppConnectivityStatus.online;

  void setStatus(AppConnectivityStatus status) {
    state = status;
  }
}

AuthSession _buildSession({
  required String tenantId,
  required String accessToken,
  required List<UserBranch> branches,
  String role = 'admin',
}) {
  final user = User(
    id: 'user-1',
    name: 'Test User',
    role: role,
    tenantId: tenantId,
    branches: branches,
  );

  return AuthSession(
    user: user,
    memberships: [
      TenantMembership(
        tenantId: tenantId,
        tenantName: 'Tenant',
        role: role,
        branches: branches,
      ),
    ],
    activeTenantId: tenantId,
    accessToken: accessToken,
    refreshToken: 'refresh',
    accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
  );
}

void main() {
  testWidgets(
    'hydrates token/tenant and refreshes policy/cash session per branch',
    (tester) async {
      final runtimeResource = _TestContextScopedResource();
      final triggerController = _TestSyncPullTriggerController();
      final saleOutageRecoveryController = _TestSaleOutageRecoveryController();
      final container = createTestContainer(
        overrides: [
          loginControllerProvider.overrideWith(_TestLoginController.new),
          policyNotifierProvider.overrideWith(_TestPolicyNotifier.new),
          cashSessionViewModelProvider.overrideWith(
            _TestCashSessionViewModel.new,
          ),
          contextScopedRuntimeResourcesProvider.overrideWithValue([
            runtimeResource,
          ]),
          syncResolvedDeviceIdProvider.overrideWith((ref) async => 'device-1'),
          syncPullTriggerControllerProvider.overrideWithValue(
            triggerController,
          ),
          saleOutageRecoveryControllerProvider.overrideWithValue(
            saleOutageRecoveryController,
          ),
        ],
      );

      await tester.pumpWidget(
        _TestHarness(
          container: container,
          child: const AppHydrationListener(child: SizedBox.shrink()),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      final policy =
          container.read(policyNotifierProvider.notifier)
              as _TestPolicyNotifier;
      final cash =
          container.read(cashSessionViewModelProvider.notifier)
              as _TestCashSessionViewModel;

      expect(container.read(authAccessTokenProvider), isNull);
      expect(container.read(authTenantIdProvider), isNull);
      expect(container.read(authActiveBranchOverrideProvider), isNull);
      expect(policy.resetCount, 1);
      expect(cash.resetCount, 1);
      expect(runtimeResource.clearedCount, 1);

      final login =
          container.read(loginControllerProvider.notifier)
              as _TestLoginController;
      login.setSession(
        _buildSession(
          tenantId: 'tenant-1',
          accessToken: 'token-1',
          branches: const [
            UserBranch(
              id: 'assign-a',
              name: 'Branch A',
              role: 'admin',
              active: true,
              branchId: 'branch-a',
            ),
            UserBranch(
              id: 'assign-b',
              name: 'Branch B',
              role: 'admin',
              active: false,
              branchId: 'branch-b',
            ),
          ],
        ),
      );
      await tester.pump();

      expect(container.read(authAccessTokenProvider), 'token-1');
      expect(container.read(authTenantIdProvider), 'tenant-1');
      expect(policy.loadCount, 1);
      expect(policy.loadedBranchIds, ['branch-a']);
      expect(cash.loadCount, 1);
      expect(cash.loadedBranchIds, ['branch-a']);
      expect(runtimeResource.reboundCount, 1);
      expect(runtimeResource.rebinds, [('token-1', 'tenant-1', 'branch-a')]);
      expect(triggerController.calls, hasLength(1));
      expect(triggerController.calls.first.$2?.deviceId, 'device-1');
      expect(triggerController.calls.first.$2?.tenantId, 'tenant-1');
      expect(triggerController.calls.first.$2?.branchId, 'branch-a');
      expect(triggerController.calls.first.$2?.accountId, 'user-1');
      expect(saleOutageRecoveryController.calls, hasLength(1));
      expect(
        saleOutageRecoveryController.calls.first.$1,
        SaleOutageRecoveryTrigger.contextChange,
      );
      expect(saleOutageRecoveryController.calls.first.$2?.tenantId, 'tenant-1');
      expect(saleOutageRecoveryController.calls.first.$2?.branchId, 'branch-a');
      expect(saleOutageRecoveryController.calls.first.$2?.accountId, 'user-1');

      container
          .read(authActiveBranchOverrideProvider.notifier)
          .setOverride('branch-b');
      container
          .read(authActiveBranchNameOverrideProvider.notifier)
          .setName('Branch B');
      await tester.pump();
      await tester.pump();

      expect(policy.loadCount, 2);
      expect(policy.loadedBranchIds, ['branch-a', 'branch-b']);
      expect(cash.loadCount, 2);
      expect(cash.loadedBranchIds, ['branch-a', 'branch-b']);
      expect(runtimeResource.reboundCount, 2);
      expect(runtimeResource.rebinds, [
        ('token-1', 'tenant-1', 'branch-a'),
        ('token-1', 'tenant-1', 'branch-b'),
      ]);
      expect(triggerController.calls, hasLength(2));
      expect(triggerController.calls.last.$1, SyncPullTrigger.branchSwitch);
      expect(triggerController.calls.last.$2?.deviceId, 'device-1');
      expect(triggerController.calls.last.$2?.tenantId, 'tenant-1');
      expect(triggerController.calls.last.$2?.branchId, 'branch-b');
      expect(triggerController.calls.last.$2?.accountId, 'user-1');
      expect(saleOutageRecoveryController.calls, hasLength(2));
      expect(
        saleOutageRecoveryController.calls.last.$1,
        SaleOutageRecoveryTrigger.contextChange,
      );
      expect(saleOutageRecoveryController.calls.last.$2?.tenantId, 'tenant-1');
      expect(saleOutageRecoveryController.calls.last.$2?.branchId, 'branch-b');
      expect(saleOutageRecoveryController.calls.last.$2?.accountId, 'user-1');

      login.setSession(null);
      await tester.pump();

      expect(container.read(authAccessTokenProvider), isNull);
      expect(container.read(authTenantIdProvider), isNull);
      expect(container.read(authActiveBranchOverrideProvider), isNull);
      expect(policy.resetCount, greaterThanOrEqualTo(2));
      expect(cash.resetCount, greaterThanOrEqualTo(2));
      expect(runtimeResource.clearedCount, greaterThanOrEqualTo(2));
    },
  );

  testWidgets('resets branch-scoped state when session has no active branch', (
    tester,
  ) async {
    final container = createTestContainer(
      overrides: [
        loginControllerProvider.overrideWith(_TestLoginController.new),
        policyNotifierProvider.overrideWith(_TestPolicyNotifier.new),
        cashSessionViewModelProvider.overrideWith(
          _TestCashSessionViewModel.new,
        ),
      ],
    );

    await tester.pumpWidget(
      _TestHarness(
        container: container,
        child: const AppHydrationListener(child: SizedBox.shrink()),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    final policy =
        container.read(policyNotifierProvider.notifier) as _TestPolicyNotifier;
    final cash =
        container.read(cashSessionViewModelProvider.notifier)
            as _TestCashSessionViewModel;
    final login =
        container.read(loginControllerProvider.notifier)
            as _TestLoginController;

    login.setSession(
      _buildSession(
        tenantId: 'tenant-1',
        accessToken: 'token-1',
        branches: const [
          UserBranch(
            id: 'assign-a',
            name: 'Branch A',
            role: 'cashier',
            active: true,
            branchId: 'branch-a',
          ),
        ],
        role: 'cashier',
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(policy.loadCount, 1);
    expect(cash.loadCount, 1);

    container.read(authActiveBranchOverrideProvider.notifier).clear();
    login.setSession(
      _buildSession(
        tenantId: 'tenant-1',
        accessToken: 'token-1',
        branches: const [],
        role: 'cashier',
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(policy.resetCount, greaterThanOrEqualTo(2));
    expect(cash.resetCount, greaterThanOrEqualTo(2));
  });

  testWidgets('treats tenant change as tenantSwitch trigger', (tester) async {
    final triggerController = _TestSyncPullTriggerController();
    final container = createTestContainer(
      overrides: [
        loginControllerProvider.overrideWith(_TestLoginController.new),
        policyNotifierProvider.overrideWith(_TestPolicyNotifier.new),
        cashSessionViewModelProvider.overrideWith(
          _TestCashSessionViewModel.new,
        ),
        syncResolvedDeviceIdProvider.overrideWith((ref) async => 'device-1'),
        syncPullTriggerControllerProvider.overrideWithValue(triggerController),
      ],
    );

    await tester.pumpWidget(
      _TestHarness(
        container: container,
        child: const AppHydrationListener(child: SizedBox.shrink()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    final login =
        container.read(loginControllerProvider.notifier)
            as _TestLoginController;

    login.setSession(
      _buildSession(
        tenantId: 'tenant-1',
        accessToken: 'token-1',
        branches: const [
          UserBranch(
            id: 'assign-a',
            name: 'Branch A',
            role: 'admin',
            active: true,
            branchId: 'branch-a',
          ),
        ],
      ),
    );
    await tester.pump();

    login.setSession(
      _buildSession(
        tenantId: 'tenant-2',
        accessToken: 'token-1',
        branches: const [
          UserBranch(
            id: 'assign-c',
            name: 'Branch C',
            role: 'admin',
            active: true,
            branchId: 'branch-c',
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(triggerController.calls, hasLength(2));
    expect(triggerController.calls.first.$2?.tenantId, 'tenant-1');
    expect(triggerController.calls.first.$2?.branchId, 'branch-a');
    expect(triggerController.calls.last.$2?.tenantId, 'tenant-2');
    expect(triggerController.calls.last.$2?.branchId, 'branch-c');
    expect(triggerController.calls.last.$2?.accountId, 'user-1');
  });

  testWidgets('triggers reconnect sync when connectivity returns online', (
    tester,
  ) async {
    final triggerController = _TestSyncPullTriggerController();
    final pushTriggerController = _TestSyncPushTriggerController();
    final saleOutageRecoveryController = _TestSaleOutageRecoveryController();
    final container = createTestContainer(
      overrides: [
        loginControllerProvider.overrideWith(_TestLoginController.new),
        policyNotifierProvider.overrideWith(_TestPolicyNotifier.new),
        cashSessionViewModelProvider.overrideWith(
          _TestCashSessionViewModel.new,
        ),
        syncResolvedDeviceIdProvider.overrideWith((ref) async => 'device-1'),
        syncPullTriggerControllerProvider.overrideWithValue(triggerController),
        syncPushTriggerControllerProvider.overrideWithValue(
          pushTriggerController,
        ),
        saleOfflineCashQueueProvider.overrideWithValue(
          SaleOfflineCashQueue(
            queueStore: _NoopOfflineCommandQueueStore(),
            outageStore: _NoopSaleOutageStore(),
          ),
        ),
        saleOutageRecoveryControllerProvider.overrideWithValue(
          saleOutageRecoveryController,
        ),
        appConnectivityStatusProvider.overrideWith(
          _TestConnectivityStatusNotifier.new,
        ),
      ],
    );

    await tester.pumpWidget(
      _TestHarness(
        container: container,
        child: const AppHydrationListener(child: SizedBox.shrink()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    final login =
        container.read(loginControllerProvider.notifier)
            as _TestLoginController;
    login.setSession(
      _buildSession(
        tenantId: 'tenant-1',
        accessToken: 'token-1',
        branches: const [
          UserBranch(
            id: 'assign-a',
            name: 'Branch A',
            role: 'admin',
            active: true,
            branchId: 'branch-a',
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();

    final connectivity =
        container.read(appConnectivityStatusProvider.notifier)
            as _TestConnectivityStatusNotifier;
    connectivity.setStatus(AppConnectivityStatus.offline);
    await tester.pump();
    connectivity.setStatus(AppConnectivityStatus.online);
    await tester.pump();
    await tester.pump();

    expect(pushTriggerController.calls, hasLength(1));
    expect(pushTriggerController.calls.last.$1, SyncPushTrigger.reconnect);
    expect(pushTriggerController.calls.last.$2?.tenantId, 'tenant-1');
    expect(pushTriggerController.calls.last.$2?.branchId, 'branch-a');
    expect(pushTriggerController.calls.last.$2?.accountId, 'user-1');
    expect(triggerController.calls, hasLength(2));
    expect(triggerController.calls.last.$1, SyncPullTrigger.reconnect);
    expect(triggerController.calls.last.$2?.tenantId, 'tenant-1');
    expect(triggerController.calls.last.$2?.branchId, 'branch-a');
    expect(triggerController.calls.last.$2?.accountId, 'user-1');
    expect(saleOutageRecoveryController.calls, hasLength(2));
    expect(
      saleOutageRecoveryController.calls.last.$1,
      SaleOutageRecoveryTrigger.reconnect,
    );
    expect(saleOutageRecoveryController.calls.last.$2?.tenantId, 'tenant-1');
    expect(saleOutageRecoveryController.calls.last.$2?.branchId, 'branch-a');
    expect(saleOutageRecoveryController.calls.last.$2?.accountId, 'user-1');
  });

  testWidgets(
    'does not trigger reconnect pull when replay already handled reconnect work',
    (tester) async {
      final pullTriggerController = _TestSyncPullTriggerController();
      final pushTriggerController = _TestSyncPushTriggerController()
        ..nextResult = const SyncPushTriggerResult(
          trigger: SyncPushTrigger.reconnect,
          outcome: SyncPushTriggerOutcome.success,
          replayResult: SyncPushReplayResult(
            outcome: SyncPushReplayOutcome.success,
            totalCount: 1,
            appliedCount: 1,
          ),
        );
      final saleOutageRecoveryController = _TestSaleOutageRecoveryController();
      final container = createTestContainer(
        overrides: [
          loginControllerProvider.overrideWith(_TestLoginController.new),
          policyNotifierProvider.overrideWith(_TestPolicyNotifier.new),
          cashSessionViewModelProvider.overrideWith(
            _TestCashSessionViewModel.new,
          ),
          syncResolvedDeviceIdProvider.overrideWith((ref) async => 'device-1'),
          syncPullTriggerControllerProvider.overrideWithValue(
            pullTriggerController,
          ),
          syncPushTriggerControllerProvider.overrideWithValue(
            pushTriggerController,
          ),
          saleOfflineCashQueueProvider.overrideWithValue(
            SaleOfflineCashQueue(
              queueStore: _NoopOfflineCommandQueueStore(),
              outageStore: _NoopSaleOutageStore(),
            ),
          ),
          saleOutageRecoveryControllerProvider.overrideWithValue(
            saleOutageRecoveryController,
          ),
          appConnectivityStatusProvider.overrideWith(
            _TestConnectivityStatusNotifier.new,
          ),
        ],
      );

      await tester.pumpWidget(
        _TestHarness(
          container: container,
          child: const AppHydrationListener(child: SizedBox.shrink()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      final login =
          container.read(loginControllerProvider.notifier)
              as _TestLoginController;
      login.setSession(
        _buildSession(
          tenantId: 'tenant-1',
          accessToken: 'token-1',
          branches: const [
            UserBranch(
              id: 'assign-a',
              name: 'Branch A',
              role: 'admin',
              active: true,
              branchId: 'branch-a',
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      final connectivity =
          container.read(appConnectivityStatusProvider.notifier)
              as _TestConnectivityStatusNotifier;
      connectivity.setStatus(AppConnectivityStatus.offline);
      await tester.pump();
      connectivity.setStatus(AppConnectivityStatus.online);
      await tester.pump();
      await tester.pump();

      expect(pushTriggerController.calls, hasLength(1));
      expect(pullTriggerController.calls, hasLength(1));
      expect(
        pullTriggerController.calls.any(
          (call) => call.$1 == SyncPullTrigger.reconnect,
        ),
        isFalse,
      );
      expect(saleOutageRecoveryController.calls, hasLength(2));
      expect(
        saleOutageRecoveryController.calls.last.$1,
        SaleOutageRecoveryTrigger.reconnect,
      );
    },
  );
}
