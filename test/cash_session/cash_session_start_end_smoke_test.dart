import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_repository.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';

import '../test_utils/riverpod_test_utils.dart';

class _TestLoginController extends LoginController {
  @override
  LoginState build() => const LoginState();

  void setSession(AuthSession? session) {
    state = LoginState(session: session);
  }
}

class _SmokeCashSessionRepository implements CashSessionRepository {
  CashSession? _session;
  int _counter = 0;

  @override
  Future<CashSession?> getActiveSession() async {
    final session = _session;
    if (session == null) return null;
    if (session.status != CashSessionStatuses.open) return null;
    return session;
  }

  @override
  Future<CashSession> openSession({
    required double openingFloatUsd,
    required double openingFloatKhr,
    String? note,
  }) async {
    _counter += 1;
    _session = CashSession(
      id: 'session-$_counter',
      tenantId: 'tenant-1',
      branchId: 'branch-1',
      openedByAccountId: 'user-1',
      openedAt: DateTime.utc(2026, 3, 7, 9, 0),
      status: CashSessionStatuses.open,
      openingFloatUsd: openingFloatUsd,
      openingFloatKhr: openingFloatKhr,
      closedAt: null,
      closedByAccountId: null,
      closeNote: note,
      totalPaidInUsd: 0,
      totalPaidOutUsd: 0,
    );
    return _session!;
  }

  @override
  Future<CashSession> closeSession({
    required String sessionId,
    required double countedCashUsd,
    required double countedCashKhr,
    String? note,
  }) async {
    final current = _session!;
    _session = CashSession(
      id: current.id,
      tenantId: current.tenantId,
      branchId: current.branchId,
      openedByAccountId: current.openedByAccountId,
      openedAt: current.openedAt,
      status: CashSessionStatuses.closed,
      openingFloatUsd: current.openingFloatUsd,
      openingFloatKhr: current.openingFloatKhr,
      closedAt: DateTime.utc(2026, 3, 7, 18, 0),
      closedByAccountId: 'manager-1',
      closeNote: note,
      totalPaidInUsd: 0,
      totalPaidOutUsd: 0,
    );
    return _session!;
  }

  @override
  Future<CashSession> forceCloseSession({
    required String sessionId,
    required double countedCashUsd,
    required double countedCashKhr,
    required String reason,
    String? note,
  }) async {
    final current = _session!;
    _session = CashSession(
      id: current.id,
      tenantId: current.tenantId,
      branchId: current.branchId,
      openedByAccountId: current.openedByAccountId,
      openedAt: current.openedAt,
      status: CashSessionStatuses.forceClosed,
      openingFloatUsd: current.openingFloatUsd,
      openingFloatKhr: current.openingFloatKhr,
      closedAt: DateTime.utc(2026, 3, 7, 18, 0),
      closedByAccountId: 'manager-1',
      closeNote: note ?? reason,
      totalPaidInUsd: 0,
      totalPaidOutUsd: 0,
    );
    return _session!;
  }
}

AuthSession _buildSession({required String role}) {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Test User',
      role: role,
      tenantId: 'tenant-1',
    ),
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

void main() {
  test('smoke open, reload, and close session flow', () async {
    final repo = _SmokeCashSessionRepository();
    final container = createTestContainer(
      overrides: [
        cashSessionRepositoryProvider.overrideWithValue(repo),
        loginControllerProvider.overrideWith(_TestLoginController.new),
      ],
    );

    final login =
        container.read(loginControllerProvider.notifier)
            as _TestLoginController;
    login.setSession(_buildSession(role: 'manager'));

    final notifier = container.read(cashSessionViewModelProvider.notifier);

    await notifier.startSession(usdAmount: 20, khrAmount: 50000, note: 'Open');
    expect(
      container.read(cashSessionViewModelProvider).sessionStatus,
      SessionStatus.open,
    );

    await notifier.load();
    expect(
      container.read(cashSessionViewModelProvider).sessionStatus,
      SessionStatus.open,
    );

    await notifier.closeSession(
      countedUsd: 20,
      countedKhr: 50000,
      note: 'Close',
    );
    expect(
      container.read(cashSessionViewModelProvider).sessionStatus,
      SessionStatus.closed,
    );
  });

  test('smoke open, reload, and force close session flow', () async {
    final repo = _SmokeCashSessionRepository();
    final container = createTestContainer(
      overrides: [
        cashSessionRepositoryProvider.overrideWithValue(repo),
        loginControllerProvider.overrideWith(_TestLoginController.new),
      ],
    );

    final login =
        container.read(loginControllerProvider.notifier)
            as _TestLoginController;
    login.setSession(_buildSession(role: 'manager'));

    final notifier = container.read(cashSessionViewModelProvider.notifier);

    await notifier.startSession(usdAmount: 15, khrAmount: 60000, note: 'Open');
    expect(
      container.read(cashSessionViewModelProvider).sessionStatus,
      SessionStatus.open,
    );

    await notifier.load();
    expect(
      container.read(cashSessionViewModelProvider).sessionStatus,
      SessionStatus.open,
    );

    await notifier.forceCloseSession(
      countedUsd: 15,
      countedKhr: 60000,
      reason: 'Supervisor override',
      note: 'Force close',
    );
    expect(
      container.read(cashSessionViewModelProvider).sessionStatus,
      SessionStatus.forceClosed,
    );
  });
}
