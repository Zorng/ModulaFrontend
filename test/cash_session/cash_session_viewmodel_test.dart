import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/app_connectivity.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/core/sync/offline_command_queue_store.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_cache_store.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_error_codes.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_movement_repository.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_repository.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_sales_repository.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_movement.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_sale.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';

import '../test_utils/riverpod_test_utils.dart';

class _MockCashSessionRepository extends Mock
    implements CashSessionRepository {}

class _MockCashSessionMovementRepository extends Mock
    implements CashSessionMovementRepository {}

class _MockCashSessionSalesRepository extends Mock
    implements CashSessionSalesRepository {}

class _TestLoginController extends LoginController {
  @override
  LoginState build() => const LoginState();

  void setSession(AuthSession? session) {
    state = LoginState(session: session);
  }
}

class _StaticConnectivityStatusController
    extends AppConnectivityStatusController {
  _StaticConnectivityStatusController(this._status);

  final AppConnectivityStatus _status;

  @override
  AppConnectivityStatus build() => _status;
}

AuthSession _buildSession({required String userId, required String role}) {
  return AuthSession(
    user: User(id: userId, name: 'Test User', role: role, tenantId: 'tenant-1'),
    memberships: [
      TenantMembership(
        tenantId: 'tenant-1',
        tenantName: 'Tenant 1',
        role: role,
        branches: const [],
      ),
    ],
    activeTenantId: 'tenant-1',
    accessToken: 'token-1',
    refreshToken: 'refresh-1',
    accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 1)),
  );
}

String _jwtWithSub(String sub) {
  final header = base64Url.encode(utf8.encode('{"alg":"none","typ":"JWT"}'));
  final payload = base64Url.encode(utf8.encode('{"sub":"$sub"}'));
  return '$header.$payload.signature';
}

CashSession _buildCashSession({
  String id = 'session-1',
  String openedByAccountId = 'user-1',
  String openedByName = 'John Smith',
  String status = CashSessionStatuses.open,
}) {
  return CashSession(
    id: id,
    tenantId: 'tenant-1',
    branchId: 'branch-1',
    openedByAccountId: openedByAccountId,
    openedByName: openedByName,
    openedAt: DateTime.utc(2026, 3, 7, 9),
    status: status,
    openingFloatUsd: 25,
    openingFloatKhr: 100000,
    closedAt: status == CashSessionStatuses.open
        ? null
        : DateTime.utc(2026, 3, 7, 17),
    closedByAccountId: status == CashSessionStatuses.open ? null : 'closer-1',
    closedByName: status == CashSessionStatuses.open ? null : 'Closer Name',
    closeNote: status == CashSessionStatuses.open ? null : 'Closed',
    totalPaidInUsd: 5,
    totalPaidOutUsd: 2,
  );
}

List<CashSessionSale> _buildSalesPage(int count, {int startAt = 0}) {
  return List.generate(
    count,
    (index) => CashSessionSale(
      saleId: 'sale-${startAt + index + 1}',
      status: CashSessionSaleStatuses.finalized,
      paymentMethod: 'CASH',
      saleType: 'TAKEAWAY',
      finalizedAt: DateTime.utc(2026, 3, 9, 9, index),
      totalItems: 1,
      grandTotalUsd: 5.0 + index,
      grandTotalKhr: 20000.0 + index,
      cashierAccountId: 'cashier-1',
      cashierName: 'John Smith',
      voidedAt: null,
    ),
  );
}

void _stubEmptySales(_MockCashSessionSalesRepository repo) {
  when(
    () => repo.listSales(
      sessionId: any(named: 'sessionId'),
      limit: any(named: 'limit'),
      offset: any(named: 'offset'),
    ),
  ).thenAnswer((_) async => const <CashSessionSale>[]);
}

void main() {
  test(
    'load shows cached active session while remote refresh is still in flight',
    () async {
      final repo = _MockCashSessionRepository();
      final movementRepo = _MockCashSessionMovementRepository();
      final salesRepo = _MockCashSessionSalesRepository();
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final cacheStore = DriftCashSessionCacheStore(database);
      await cacheStore.write(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        session: _buildCashSession(),
        movements: const [],
        sales: const [],
      );

      final completer = Completer<CashSession?>();
      when(() => repo.getActiveSession()).thenAnswer((_) => completer.future);
      when(
        () => movementRepo.listMovements(sessionId: any(named: 'sessionId')),
      ).thenAnswer((_) async => const []);
      _stubEmptySales(salesRepo);

      final container = createTestContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          cashSessionRepositoryProvider.overrideWithValue(repo),
          cashSessionMovementRepositoryProvider.overrideWithValue(movementRepo),
          cashSessionSalesRepositoryProvider.overrideWithValue(salesRepo),
          cashSessionBranchContextProvider.overrideWithValue(
            const CashSessionBranchContext(
              tenantId: 'tenant-1',
              branchId: 'branch-1',
            ),
          ),
          loginControllerProvider.overrideWith(_TestLoginController.new),
        ],
      );

      final notifier = container.read(cashSessionViewModelProvider.notifier);
      final loadFuture = notifier.load();
      await Future<void>.delayed(Duration.zero);

      final loadingState = container.read(cashSessionViewModelProvider);
      expect(loadingState.isLoading, isTrue);
      expect(loadingState.sessionId, 'session-1');

      completer.complete(_buildCashSession(status: CashSessionStatuses.open));
      await loadFuture;

      final state = container.read(cashSessionViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.sessionId, 'session-1');
    },
  );

  test(
    'load clears cached branch session when server reports no active session',
    () async {
      final repo = _MockCashSessionRepository();
      final movementRepo = _MockCashSessionMovementRepository();
      final salesRepo = _MockCashSessionSalesRepository();
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final cacheStore = DriftCashSessionCacheStore(database);
      await cacheStore.write(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        session: _buildCashSession(),
        movements: const [],
        sales: const [],
      );

      when(() => repo.getActiveSession()).thenAnswer((_) async => null);
      when(
        () => movementRepo.listMovements(sessionId: any(named: 'sessionId')),
      ).thenAnswer((_) async => const []);
      _stubEmptySales(salesRepo);

      final container = createTestContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          cashSessionRepositoryProvider.overrideWithValue(repo),
          cashSessionMovementRepositoryProvider.overrideWithValue(movementRepo),
          cashSessionSalesRepositoryProvider.overrideWithValue(salesRepo),
          cashSessionBranchContextProvider.overrideWithValue(
            const CashSessionBranchContext(
              tenantId: 'tenant-1',
              branchId: 'branch-1',
            ),
          ),
          loginControllerProvider.overrideWith(_TestLoginController.new),
        ],
      );

      final notifier = container.read(cashSessionViewModelProvider.notifier);
      await notifier.load();

      final state = container.read(cashSessionViewModelProvider);
      expect(state.session, isNull);

      final cached = await cacheStore.read(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      );
      expect(cached.session, isNull);
    },
  );

  test(
    'load stops loading and keeps cached branch session when refresh times out',
    () async {
      final repo = _MockCashSessionRepository();
      final movementRepo = _MockCashSessionMovementRepository();
      final salesRepo = _MockCashSessionSalesRepository();
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final cacheStore = DriftCashSessionCacheStore(database);
      await cacheStore.write(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        session: _buildCashSession(),
        movements: const [],
        sales: const [],
      );

      final completer = Completer<CashSession?>();
      when(() => repo.getActiveSession()).thenAnswer((_) => completer.future);
      when(
        () => movementRepo.listMovements(sessionId: any(named: 'sessionId')),
      ).thenAnswer((_) async => const []);
      _stubEmptySales(salesRepo);

      final container = createTestContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          cashSessionRepositoryProvider.overrideWithValue(repo),
          cashSessionMovementRepositoryProvider.overrideWithValue(movementRepo),
          cashSessionSalesRepositoryProvider.overrideWithValue(salesRepo),
          cashSessionBranchContextProvider.overrideWithValue(
            const CashSessionBranchContext(
              tenantId: 'tenant-1',
              branchId: 'branch-1',
            ),
          ),
          cashSessionRequestTimeoutProvider.overrideWithValue(
            const Duration(milliseconds: 10),
          ),
          loginControllerProvider.overrideWith(_TestLoginController.new),
        ],
      );

      final notifier = container.read(cashSessionViewModelProvider.notifier);
      await notifier.load();

      final state = container.read(cashSessionViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.sessionId, 'session-1');
      expect(state.errorCode, CashSessionErrorCodes.offlineUnreachable);
    },
  );

  test('load clears state when there is no active session', () async {
    final repo = _MockCashSessionRepository();
    final movementRepo = _MockCashSessionMovementRepository();
    final salesRepo = _MockCashSessionSalesRepository();
    when(() => repo.getActiveSession()).thenAnswer((_) async => null);
    when(
      () => movementRepo.listMovements(sessionId: any(named: 'sessionId')),
    ).thenAnswer((_) async => const []);
    _stubEmptySales(salesRepo);

    final container = createTestContainer(
      overrides: [
        cashSessionRepositoryProvider.overrideWithValue(repo),
        cashSessionMovementRepositoryProvider.overrideWithValue(movementRepo),
        cashSessionSalesRepositoryProvider.overrideWithValue(salesRepo),
        loginControllerProvider.overrideWith(_TestLoginController.new),
      ],
    );

    final notifier = container.read(cashSessionViewModelProvider.notifier);
    await notifier.load();

    final state = container.read(cashSessionViewModelProvider);
    expect(state.sessionStatus, SessionStatus.notStarted);
    expect(state.session, isNull);
    expect(state.error, isNull);
  });

  test('load keeps branch session even when opened by another user', () async {
    final repo = _MockCashSessionRepository();
    final movementRepo = _MockCashSessionMovementRepository();
    final salesRepo = _MockCashSessionSalesRepository();
    when(() => repo.getActiveSession()).thenAnswer(
      (_) async => _buildCashSession(openedByAccountId: 'another-user'),
    );
    when(
      () => movementRepo.listMovements(sessionId: any(named: 'sessionId')),
    ).thenAnswer((_) async => const []);
    _stubEmptySales(salesRepo);

    final container = createTestContainer(
      overrides: [
        cashSessionRepositoryProvider.overrideWithValue(repo),
        cashSessionMovementRepositoryProvider.overrideWithValue(movementRepo),
        cashSessionSalesRepositoryProvider.overrideWithValue(salesRepo),
        loginControllerProvider.overrideWith(_TestLoginController.new),
      ],
    );

    final login =
        container.read(loginControllerProvider.notifier)
            as _TestLoginController;
    login.setSession(_buildSession(userId: 'current-user', role: 'cashier'));

    final notifier = container.read(cashSessionViewModelProvider.notifier);
    await notifier.load();

    final state = container.read(cashSessionViewModelProvider);
    expect(state.sessionId, 'session-1');
    expect(state.sessionStatus, SessionStatus.open);
    expect(state.isOwnedByCurrentUser, isFalse);
    expect(state.isOccupiedByAnotherUser, isTrue);
    expect(state.sessionOwnerLabel, 'John Smith');
    expect(state.error, isNull);
  });

  test('load refreshes session sales for the live dashboard', () async {
    final repo = _MockCashSessionRepository();
    final movementRepo = _MockCashSessionMovementRepository();
    final salesRepo = _MockCashSessionSalesRepository();
    when(() => repo.getActiveSession()).thenAnswer(
      (_) async => _buildCashSession(openedByAccountId: 'another-user'),
    );
    when(
      () => movementRepo.listMovements(sessionId: any(named: 'sessionId')),
    ).thenAnswer((_) async => const []);
    when(
      () => salesRepo.listSales(
        sessionId: any(named: 'sessionId'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer(
      (_) async => [
        CashSessionSale(
          saleId: 'sale-1',
          status: CashSessionSaleStatuses.finalized,
          paymentMethod: 'CASH',
          saleType: 'TAKEAWAY',
          finalizedAt: DateTime.utc(2026, 3, 9, 9, 10),
          totalItems: 3,
          grandTotalUsd: 7.5,
          grandTotalKhr: 30750,
          cashierAccountId: 'cashier-1',
          cashierName: 'John Smith',
          voidedAt: null,
        ),
      ],
    );

    final container = createTestContainer(
      overrides: [
        cashSessionRepositoryProvider.overrideWithValue(repo),
        cashSessionMovementRepositoryProvider.overrideWithValue(movementRepo),
        cashSessionSalesRepositoryProvider.overrideWithValue(salesRepo),
        loginControllerProvider.overrideWith(_TestLoginController.new),
      ],
    );

    final notifier = container.read(cashSessionViewModelProvider.notifier);
    await notifier.load();

    final state = container.read(cashSessionViewModelProvider);
    expect(state.sales, hasLength(1));
    expect(state.sales.first.saleId, 'sale-1');
    expect(state.sales.first.cashierName, 'John Smith');
  });

  test('loadMoreSales appends the next sales page', () async {
    final repo = _MockCashSessionRepository();
    final movementRepo = _MockCashSessionMovementRepository();
    final salesRepo = _MockCashSessionSalesRepository();

    when(
      () => repo.getActiveSession(),
    ).thenAnswer((_) async => _buildCashSession());
    when(
      () => movementRepo.listMovements(sessionId: any(named: 'sessionId')),
    ).thenAnswer((_) async => const []);
    when(
      () => salesRepo.listSales(
        sessionId: 'session-1',
        limit: any(named: 'limit'),
        offset: 0,
      ),
    ).thenAnswer((_) async => _buildSalesPage(20));
    when(
      () => salesRepo.listSales(
        sessionId: 'session-1',
        limit: any(named: 'limit'),
        offset: 20,
      ),
    ).thenAnswer((_) async => _buildSalesPage(1, startAt: 20));

    final container = createTestContainer(
      overrides: [
        cashSessionRepositoryProvider.overrideWithValue(repo),
        cashSessionMovementRepositoryProvider.overrideWithValue(movementRepo),
        cashSessionSalesRepositoryProvider.overrideWithValue(salesRepo),
        loginControllerProvider.overrideWith(_TestLoginController.new),
      ],
    );

    final notifier = container.read(cashSessionViewModelProvider.notifier);
    await notifier.load();
    expect(container.read(cashSessionViewModelProvider).hasMoreSales, isTrue);

    await notifier.loadMoreSales();

    final state = container.read(cashSessionViewModelProvider);
    expect(state.sales, hasLength(21));
    expect(state.sales.last.saleId, 'sale-21');
    expect(state.hasMoreSales, isFalse);
  });

  test(
    'load marks current user as the session owner when opener matches',
    () async {
      final repo = _MockCashSessionRepository();
      final movementRepo = _MockCashSessionMovementRepository();
      final salesRepo = _MockCashSessionSalesRepository();
      when(
        () => repo.getActiveSession(),
      ).thenAnswer((_) async => _buildCashSession(openedByAccountId: 'user-1'));
      when(
        () => movementRepo.listMovements(sessionId: any(named: 'sessionId')),
      ).thenAnswer((_) async => const []);
      _stubEmptySales(salesRepo);

      final container = createTestContainer(
        overrides: [
          cashSessionRepositoryProvider.overrideWithValue(repo),
          cashSessionMovementRepositoryProvider.overrideWithValue(movementRepo),
          cashSessionSalesRepositoryProvider.overrideWithValue(salesRepo),
          loginControllerProvider.overrideWith(_TestLoginController.new),
        ],
      );

      final login =
          container.read(loginControllerProvider.notifier)
              as _TestLoginController;
      login.setSession(_buildSession(userId: 'user-1', role: 'cashier'));

      final notifier = container.read(cashSessionViewModelProvider.notifier);
      await notifier.load();

      final state = container.read(cashSessionViewModelProvider);
      expect(state.isOwnedByCurrentUser, isTrue);
      expect(state.isOccupiedByAnotherUser, isFalse);
      expect(state.sessionOwnerLabel, 'You');
    },
  );

  test(
    'load falls back to JWT account id when session user id is empty',
    () async {
      final repo = _MockCashSessionRepository();
      final movementRepo = _MockCashSessionMovementRepository();
      final salesRepo = _MockCashSessionSalesRepository();
      when(
        () => repo.getActiveSession(),
      ).thenAnswer((_) async => _buildCashSession(openedByAccountId: 'user-a'));
      when(
        () => movementRepo.listMovements(sessionId: any(named: 'sessionId')),
      ).thenAnswer((_) async => const []);
      _stubEmptySales(salesRepo);

      final container = createTestContainer(
        overrides: [
          cashSessionRepositoryProvider.overrideWithValue(repo),
          cashSessionMovementRepositoryProvider.overrideWithValue(movementRepo),
          cashSessionSalesRepositoryProvider.overrideWithValue(salesRepo),
          loginControllerProvider.overrideWith(_TestLoginController.new),
        ],
      );

      final login =
          container.read(loginControllerProvider.notifier)
              as _TestLoginController;
      login.setSession(
        _buildSession(
          userId: '',
          role: 'cashier',
        ).copyWith(accessToken: _jwtWithSub('user-b')),
      );

      final notifier = container.read(cashSessionViewModelProvider.notifier);
      await notifier.load();

      final state = container.read(cashSessionViewModelProvider);
      expect(state.currentUserAccountId, 'user-b');
      expect(state.isOwnedByCurrentUser, isFalse);
      expect(state.isOccupiedByAnotherUser, isTrue);
      expect(state.sessionOwnerLabel, 'John Smith');
    },
  );

  test('load sets canForceClose for manager on open session', () async {
    final repo = _MockCashSessionRepository();
    final movementRepo = _MockCashSessionMovementRepository();
    final salesRepo = _MockCashSessionSalesRepository();
    when(
      () => repo.getActiveSession(),
    ).thenAnswer((_) async => _buildCashSession());
    when(
      () => movementRepo.listMovements(sessionId: any(named: 'sessionId')),
    ).thenAnswer((_) async => const []);
    _stubEmptySales(salesRepo);

    final container = createTestContainer(
      overrides: [
        cashSessionRepositoryProvider.overrideWithValue(repo),
        cashSessionMovementRepositoryProvider.overrideWithValue(movementRepo),
        cashSessionSalesRepositoryProvider.overrideWithValue(salesRepo),
        loginControllerProvider.overrideWith(_TestLoginController.new),
      ],
    );

    final login =
        container.read(loginControllerProvider.notifier)
            as _TestLoginController;
    login.setSession(_buildSession(userId: 'manager-1', role: 'manager'));

    final notifier = container.read(cashSessionViewModelProvider.notifier);
    await notifier.load();

    final state = container.read(cashSessionViewModelProvider);
    expect(state.canForceClose, isTrue);
    expect(state.session?.openedByAccountId, 'user-1');
  });

  test(
    'closeSession preserves session and stores backend error code',
    () async {
      final repo = _MockCashSessionRepository();
      final movementRepo = _MockCashSessionMovementRepository();
      final salesRepo = _MockCashSessionSalesRepository();
      when(
        () => repo.getActiveSession(),
      ).thenAnswer((_) async => _buildCashSession());
      when(
        () => movementRepo.listMovements(sessionId: any(named: 'sessionId')),
      ).thenAnswer((_) async => const []);
      _stubEmptySales(salesRepo);
      when(
        () => repo.closeSession(
          sessionId: 'session-1',
          countedCashUsd: 25,
          countedCashKhr: 100000,
          note: null,
        ),
      ).thenThrow(
        const ApiClientException(
          message: 'Unpaid tickets must be settled first.',
          code: CashSessionErrorCodes.cashSessionUnpaidTicketsExist,
        ),
      );

      final container = createTestContainer(
        overrides: [
          cashSessionRepositoryProvider.overrideWithValue(repo),
          cashSessionMovementRepositoryProvider.overrideWithValue(movementRepo),
          cashSessionSalesRepositoryProvider.overrideWithValue(salesRepo),
          loginControllerProvider.overrideWith(_TestLoginController.new),
        ],
      );

      final login =
          container.read(loginControllerProvider.notifier)
              as _TestLoginController;
      login.setSession(_buildSession(userId: 'manager-1', role: 'manager'));

      final notifier = container.read(cashSessionViewModelProvider.notifier);
      await notifier.load();
      await notifier.closeSession(countedUsd: 25, countedKhr: 100000);

      final state = container.read(cashSessionViewModelProvider);
      expect(state.sessionId, 'session-1');
      expect(
        state.errorCode,
        CashSessionErrorCodes.cashSessionUnpaidTicketsExist,
      );
      expect(state.isLoading, isFalse);
    },
  );

  test('startSession stores the opened branch session', () async {
    final repo = _MockCashSessionRepository();
    final movementRepo = _MockCashSessionMovementRepository();
    final salesRepo = _MockCashSessionSalesRepository();
    when(
      () => repo.openSession(
        openingFloatUsd: 25,
        openingFloatKhr: 100000,
        note: 'Shift start',
      ),
    ).thenAnswer((_) async => _buildCashSession());
    when(
      () => movementRepo.listMovements(sessionId: any(named: 'sessionId')),
    ).thenAnswer((_) async => const []);
    _stubEmptySales(salesRepo);

    final container = createTestContainer(
      overrides: [
        cashSessionRepositoryProvider.overrideWithValue(repo),
        cashSessionMovementRepositoryProvider.overrideWithValue(movementRepo),
        cashSessionSalesRepositoryProvider.overrideWithValue(salesRepo),
        loginControllerProvider.overrideWith(_TestLoginController.new),
      ],
    );

    final notifier = container.read(cashSessionViewModelProvider.notifier);
    await notifier.startSession(
      usdAmount: 25,
      khrAmount: 100000,
      note: 'Shift start',
    );

    final state = container.read(cashSessionViewModelProvider);
    expect(state.sessionStatus, SessionStatus.open);
    expect(state.sessionId, 'session-1');
    expect(state.error, isNull);
  });

  test(
    'startSession queues offline-safe open without calling backend',
    () async {
      final repo = _MockCashSessionRepository();
      final movementRepo = _MockCashSessionMovementRepository();
      final salesRepo = _MockCashSessionSalesRepository();
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      _stubEmptySales(salesRepo);

      final container = createTestContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          appConnectivityStatusProvider.overrideWith(
            () => _StaticConnectivityStatusController(
              AppConnectivityStatus.offline,
            ),
          ),
          cashSessionRepositoryProvider.overrideWithValue(repo),
          cashSessionMovementRepositoryProvider.overrideWithValue(movementRepo),
          cashSessionSalesRepositoryProvider.overrideWithValue(salesRepo),
          cashSessionBranchContextProvider.overrideWithValue(
            const CashSessionBranchContext(
              tenantId: 'tenant-1',
              branchId: 'branch-1',
            ),
          ),
          loginControllerProvider.overrideWith(_TestLoginController.new),
        ],
      );

      final login =
          container.read(loginControllerProvider.notifier)
              as _TestLoginController;
      login.setSession(_buildSession(userId: 'cashier-1', role: 'cashier'));

      final notifier = container.read(cashSessionViewModelProvider.notifier);
      final result = await notifier.startSession(
        usdAmount: 25,
        khrAmount: 100000,
        note: 'Shift start',
      );

      final queue = await container
          .read(offlineCommandQueueStoreProvider)
          .listReplayReadyForContext(
            tenantId: 'tenant-1',
            branchId: 'branch-1',
            accountId: 'cashier-1',
          );

      expect(result.outcome, CashSessionActionOutcome.queued);
      expect(queue, hasLength(1));
      expect(queue.single.operationType, OfflineOperationType.cashSessionOpen);
      expect(
        queue.single.decodePayload(),
        containsPair('openingFloatUsd', 25.0),
      );
      verifyNever(
        () => repo.openSession(
          openingFloatUsd: any(named: 'openingFloatUsd'),
          openingFloatKhr: any(named: 'openingFloatKhr'),
          note: any(named: 'note'),
        ),
      );
    },
  );

  test('startSession stores already-open conflict reason code', () async {
    final repo = _MockCashSessionRepository();
    final movementRepo = _MockCashSessionMovementRepository();
    final salesRepo = _MockCashSessionSalesRepository();
    when(
      () => repo.openSession(
        openingFloatUsd: 25,
        openingFloatKhr: 100000,
        note: 'Shift start',
      ),
    ).thenThrow(
      const ApiClientException(
        message: 'A session is already open.',
        code: CashSessionErrorCodes.cashSessionAlreadyOpen,
      ),
    );
    when(
      () => movementRepo.listMovements(sessionId: any(named: 'sessionId')),
    ).thenAnswer((_) async => const []);
    _stubEmptySales(salesRepo);

    final container = createTestContainer(
      overrides: [
        cashSessionRepositoryProvider.overrideWithValue(repo),
        cashSessionMovementRepositoryProvider.overrideWithValue(movementRepo),
        cashSessionSalesRepositoryProvider.overrideWithValue(salesRepo),
        loginControllerProvider.overrideWith(_TestLoginController.new),
      ],
    );

    final notifier = container.read(cashSessionViewModelProvider.notifier);
    await notifier.startSession(
      usdAmount: 25,
      khrAmount: 100000,
      note: 'Shift start',
    );

    final state = container.read(cashSessionViewModelProvider);
    expect(state.sessionStatus, SessionStatus.notStarted);
    expect(state.errorCode, CashSessionErrorCodes.cashSessionAlreadyOpen);
    expect(state.isLoading, isFalse);
  });

  test('closeSession clears active session after successful close', () async {
    final repo = _MockCashSessionRepository();
    final movementRepo = _MockCashSessionMovementRepository();
    final salesRepo = _MockCashSessionSalesRepository();
    when(
      () => repo.getActiveSession(),
    ).thenAnswer((_) async => _buildCashSession());
    when(
      () => movementRepo.listMovements(sessionId: any(named: 'sessionId')),
    ).thenAnswer((_) async => const []);
    _stubEmptySales(salesRepo);
    when(
      () => repo.closeSession(
        sessionId: 'session-1',
        countedCashUsd: 25,
        countedCashKhr: 100000,
        note: 'End of shift',
      ),
    ).thenAnswer(
      (_) async => _buildCashSession(status: CashSessionStatuses.closed),
    );
    when(() => repo.getActiveSession()).thenAnswer((_) async => null);

    final container = createTestContainer(
      overrides: [
        cashSessionRepositoryProvider.overrideWithValue(repo),
        cashSessionMovementRepositoryProvider.overrideWithValue(movementRepo),
        cashSessionSalesRepositoryProvider.overrideWithValue(salesRepo),
        loginControllerProvider.overrideWith(_TestLoginController.new),
      ],
    );

    final login =
        container.read(loginControllerProvider.notifier)
            as _TestLoginController;
    login.setSession(_buildSession(userId: 'manager-1', role: 'manager'));

    final notifier = container.read(cashSessionViewModelProvider.notifier);
    await notifier.load();
    await notifier.closeSession(
      countedUsd: 25,
      countedKhr: 100000,
      note: 'End of shift',
    );

    final state = container.read(cashSessionViewModelProvider);
    expect(state.sessionStatus, SessionStatus.notStarted);
    expect(state.session, isNull);
    expect(state.error, isNull);
  });

  test(
    'closeSession queues offline-safe close and keeps active session visible',
    () async {
      final repo = _MockCashSessionRepository();
      final movementRepo = _MockCashSessionMovementRepository();
      final salesRepo = _MockCashSessionSalesRepository();
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      when(
        () => repo.getActiveSession(),
      ).thenAnswer((_) async => _buildCashSession());
      when(
        () => movementRepo.listMovements(sessionId: any(named: 'sessionId')),
      ).thenAnswer((_) async => const []);
      _stubEmptySales(salesRepo);

      final container = createTestContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          appConnectivityStatusProvider.overrideWith(
            () => _StaticConnectivityStatusController(
              AppConnectivityStatus.offline,
            ),
          ),
          cashSessionRepositoryProvider.overrideWithValue(repo),
          cashSessionMovementRepositoryProvider.overrideWithValue(movementRepo),
          cashSessionSalesRepositoryProvider.overrideWithValue(salesRepo),
          loginControllerProvider.overrideWith(_TestLoginController.new),
        ],
      );

      final login =
          container.read(loginControllerProvider.notifier)
              as _TestLoginController;
      login.setSession(_buildSession(userId: 'manager-1', role: 'manager'));

      final notifier = container.read(cashSessionViewModelProvider.notifier);
      await notifier.load();
      final result = await notifier.closeSession(
        countedUsd: 25,
        countedKhr: 100000,
        note: 'End shift',
      );

      final state = container.read(cashSessionViewModelProvider);
      final queue = await container
          .read(offlineCommandQueueStoreProvider)
          .listReplayReadyForContext(
            tenantId: 'tenant-1',
            branchId: 'branch-1',
            accountId: 'manager-1',
          );

      expect(result.outcome, CashSessionActionOutcome.queued);
      expect(state.sessionId, 'session-1');
      expect(queue, hasLength(1));
      expect(queue.single.operationType, OfflineOperationType.cashSessionClose);
      verifyNever(
        () => repo.closeSession(
          sessionId: any(named: 'sessionId'),
          countedCashUsd: any(named: 'countedCashUsd'),
          countedCashKhr: any(named: 'countedCashKhr'),
          note: any(named: 'note'),
        ),
      );
    },
  );

  test('forceCloseSession clears active session after force close', () async {
    final repo = _MockCashSessionRepository();
    final movementRepo = _MockCashSessionMovementRepository();
    final salesRepo = _MockCashSessionSalesRepository();
    when(
      () => repo.getActiveSession(),
    ).thenAnswer((_) async => _buildCashSession());
    when(
      () => movementRepo.listMovements(sessionId: any(named: 'sessionId')),
    ).thenAnswer((_) async => const []);
    _stubEmptySales(salesRepo);
    when(
      () => repo.forceCloseSession(
        sessionId: 'session-1',
        countedCashUsd: 25,
        countedCashKhr: 100000,
        reason: 'Supervisor override',
        note: null,
      ),
    ).thenAnswer(
      (_) async => _buildCashSession(status: CashSessionStatuses.forceClosed),
    );
    when(() => repo.getActiveSession()).thenAnswer((_) async => null);

    final container = createTestContainer(
      overrides: [
        cashSessionRepositoryProvider.overrideWithValue(repo),
        cashSessionMovementRepositoryProvider.overrideWithValue(movementRepo),
        cashSessionSalesRepositoryProvider.overrideWithValue(salesRepo),
        loginControllerProvider.overrideWith(_TestLoginController.new),
      ],
    );

    final login =
        container.read(loginControllerProvider.notifier)
            as _TestLoginController;
    login.setSession(_buildSession(userId: 'manager-1', role: 'manager'));

    final notifier = container.read(cashSessionViewModelProvider.notifier);
    await notifier.load();
    await notifier.forceCloseSession(
      countedUsd: 25,
      countedKhr: 100000,
      reason: 'Supervisor override',
    );

    final state = container.read(cashSessionViewModelProvider);
    expect(state.sessionStatus, SessionStatus.notStarted);
    expect(state.session, isNull);
    expect(state.canForceClose, isFalse);
    expect(state.error, isNull);
  });

  test(
    'recordPaidIn refreshes movement totals from backend movements',
    () async {
      final repo = _MockCashSessionRepository();
      final movementRepo = _MockCashSessionMovementRepository();
      final salesRepo = _MockCashSessionSalesRepository();
      when(
        () => repo.getActiveSession(),
      ).thenAnswer((_) async => _buildCashSession());
      when(
        () => movementRepo.listMovements(sessionId: any(named: 'sessionId')),
      ).thenAnswer(
        (_) async => [
          CashMovement(
            id: 'move-1',
            sessionId: 'session-1',
            tenantId: 'tenant-1',
            branchId: 'branch-1',
            movementType: CashMovementTypes.manualIn,
            amountUsd: 8,
            amountKhr: 0,
            reason: 'Top-up',
            sourceRefType: 'MANUAL',
            sourceRefId: null,
            recordedByAccountId: 'user-1',
            occurredAt: null,
          ),
        ],
      );
      _stubEmptySales(salesRepo);
      when(
        () => movementRepo.recordPaidIn(
          sessionId: 'session-1',
          amountUsd: 8,
          amountKhr: 0,
          reason: 'Top-up',
        ),
      ).thenAnswer((_) async {});

      final container = createTestContainer(
        overrides: [
          cashSessionRepositoryProvider.overrideWithValue(repo),
          cashSessionMovementRepositoryProvider.overrideWithValue(movementRepo),
          cashSessionSalesRepositoryProvider.overrideWithValue(salesRepo),
          loginControllerProvider.overrideWith(_TestLoginController.new),
        ],
      );

      final notifier = container.read(cashSessionViewModelProvider.notifier);
      await notifier.load();
      await notifier.recordPaidIn(amountUsd: 8, amountKhr: 0, reason: 'Top-up');

      final state = container.read(cashSessionViewModelProvider);
      expect(state.movements, hasLength(1));
      expect(state.totalPaidIn, 8);
      verify(
        () => movementRepo.recordPaidIn(
          sessionId: 'session-1',
          amountUsd: 8,
          amountKhr: 0,
          reason: 'Top-up',
        ),
      ).called(1);
    },
  );

  test(
    'recordPaidIn queues offline-safe movement without calling backend',
    () async {
      final repo = _MockCashSessionRepository();
      final movementRepo = _MockCashSessionMovementRepository();
      final salesRepo = _MockCashSessionSalesRepository();
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      when(
        () => repo.getActiveSession(),
      ).thenAnswer((_) async => _buildCashSession());
      when(
        () => movementRepo.listMovements(sessionId: any(named: 'sessionId')),
      ).thenAnswer((_) async => const []);
      _stubEmptySales(salesRepo);

      final container = createTestContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          appConnectivityStatusProvider.overrideWith(
            () => _StaticConnectivityStatusController(
              AppConnectivityStatus.offline,
            ),
          ),
          cashSessionRepositoryProvider.overrideWithValue(repo),
          cashSessionMovementRepositoryProvider.overrideWithValue(movementRepo),
          cashSessionSalesRepositoryProvider.overrideWithValue(salesRepo),
          loginControllerProvider.overrideWith(_TestLoginController.new),
        ],
      );

      final login =
          container.read(loginControllerProvider.notifier)
              as _TestLoginController;
      login.setSession(_buildSession(userId: 'cashier-1', role: 'cashier'));

      final notifier = container.read(cashSessionViewModelProvider.notifier);
      await notifier.load();
      final result = await notifier.recordPaidIn(
        amountUsd: 8,
        amountKhr: 0,
        reason: 'Top-up',
      );

      final queue = await container
          .read(offlineCommandQueueStoreProvider)
          .listReplayReadyForContext(
            tenantId: 'tenant-1',
            branchId: 'branch-1',
            accountId: 'cashier-1',
          );

      expect(result.outcome, CashSessionActionOutcome.queued);
      expect(queue, hasLength(1));
      expect(
        queue.single.operationType,
        OfflineOperationType.cashSessionMovement,
      );
      expect(
        queue.single.decodePayload(),
        containsPair('movementType', 'PAID_IN'),
      );
      verifyNever(
        () => movementRepo.recordPaidIn(
          sessionId: any(named: 'sessionId'),
          amountUsd: any(named: 'amountUsd'),
          amountKhr: any(named: 'amountKhr'),
          reason: any(named: 'reason'),
        ),
      );
    },
  );

  test('forceCloseSession stays online-only while offline', () async {
    final repo = _MockCashSessionRepository();
    final movementRepo = _MockCashSessionMovementRepository();
    final salesRepo = _MockCashSessionSalesRepository();
    when(
      () => repo.getActiveSession(),
    ).thenAnswer((_) async => _buildCashSession());
    when(
      () => movementRepo.listMovements(sessionId: any(named: 'sessionId')),
    ).thenAnswer((_) async => const []);
    _stubEmptySales(salesRepo);

    final container = createTestContainer(
      overrides: [
        appConnectivityStatusProvider.overrideWith(
          () => _StaticConnectivityStatusController(
            AppConnectivityStatus.offline,
          ),
        ),
        cashSessionRepositoryProvider.overrideWithValue(repo),
        cashSessionMovementRepositoryProvider.overrideWithValue(movementRepo),
        cashSessionSalesRepositoryProvider.overrideWithValue(salesRepo),
        loginControllerProvider.overrideWith(_TestLoginController.new),
      ],
    );

    final login =
        container.read(loginControllerProvider.notifier)
            as _TestLoginController;
    login.setSession(_buildSession(userId: 'manager-1', role: 'manager'));

    final notifier = container.read(cashSessionViewModelProvider.notifier);
    await notifier.load();
    await notifier.forceCloseSession(
      countedUsd: 25,
      countedKhr: 100000,
      reason: 'Supervisor override',
    );

    final state = container.read(cashSessionViewModelProvider);
    expect(state.sessionId, 'session-1');
    expect(state.error, 'Force-closing a cash session requires connectivity.');
    verifyNever(
      () => repo.forceCloseSession(
        sessionId: any(named: 'sessionId'),
        countedCashUsd: any(named: 'countedCashUsd'),
        countedCashKhr: any(named: 'countedCashKhr'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
      ),
    );
  });
}
