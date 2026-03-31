import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/audit/data/audit_repository.dart';
import 'package:modular_pos/features/audit/domain/models/audit_event.dart';
import 'package:modular_pos/features/audit/ui/viewmodels/audit_log_controller.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

class _StaticLoginController extends LoginController {
  _StaticLoginController(this._session);

  final AuthSession _session;

  @override
  LoginState build() => LoginState(session: _session);
}

class _RecordingAuditRepository implements AuditRepository {
  _RecordingAuditRepository(this._responses);

  final List<AuditEventPage> _responses;
  final List<_AuditCall> calls = <_AuditCall>[];

  @override
  Future<AuditEventPage> listEvents({
    String? branchId,
    String? actionKey,
    AuditOutcome? outcome,
    int limit = 50,
    int offset = 0,
  }) async {
    calls.add(
      _AuditCall(
        branchId: branchId,
        actionKey: actionKey,
        outcome: outcome,
        limit: limit,
        offset: offset,
      ),
    );
    return _responses.removeAt(0);
  }
}

class _AuditCall {
  const _AuditCall({
    required this.branchId,
    required this.actionKey,
    required this.outcome,
    required this.limit,
    required this.offset,
  });

  final String? branchId;
  final String? actionKey;
  final AuditOutcome? outcome;
  final int limit;
  final int offset;
}

AuthSession _session(String role) {
  final branch = UserBranch(
    id: 'assign-1',
    name: 'Main Branch',
    role: 'admin',
    active: true,
    branchId: 'branch-1',
  );

  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Admin User',
      role: role,
      tenantId: 'tenant-1',
      branches: [branch],
    ),
    memberships: [
      TenantMembership(
        membershipId: 'membership-1',
        tenantId: 'tenant-1',
        tenantName: 'Tenant 1',
        role: role,
        branches: [branch],
      ),
    ],
    activeTenantId: 'tenant-1',
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    accessTokenExpiresAt: DateTime(2026, 4, 1),
    refreshTokenExpiresAt: DateTime(2026, 4, 8),
  );
}

AuditEvent _event(String id) {
  return AuditEvent(
    id: id,
    tenantId: 'tenant-1',
    branchId: 'branch-1',
    actorAccountId: 'actor-1',
    actorDisplayName: 'Cashier Dara',
    actionKey: 'attendance.checkIn',
    outcome: AuditOutcome.success,
    reasonCode: null,
    entityType: 'attendance_record',
    entityId: 'record-$id',
    metadata: const {'endpoint': '/v0/attendance/check-in'},
    createdAt: DateTime.utc(2026, 4, 1, 8, 0),
  );
}

void main() {
  test('controller loads initial audit events for admin', () async {
    final repository = _RecordingAuditRepository([
      AuditEventPage(
        items: [_event('event-1')],
        limit: 50,
        offset: 0,
        total: 1,
        hasMore: false,
      ),
    ]);
    final container = ProviderContainer(
      overrides: [
        loginControllerProvider.overrideWith(
          () => _StaticLoginController(_session('ADMIN')),
        ),
        auditRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(auditLogControllerProvider.future);

    expect(state.items, hasLength(1));
    expect(state.items.first.id, 'event-1');
    expect(repository.calls, hasLength(1));
    expect(repository.calls.first.offset, 0);
  });

  test('controller applies filters and paginates', () async {
    final repository = _RecordingAuditRepository([
      AuditEventPage(
        items: [_event('event-1')],
        limit: 50,
        offset: 0,
        total: 2,
        hasMore: true,
      ),
      AuditEventPage(
        items: [_event('event-2')],
        limit: 50,
        offset: 0,
        total: 1,
        hasMore: true,
      ),
      AuditEventPage(
        items: [_event('event-3')],
        limit: 50,
        offset: 1,
        total: 2,
        hasMore: false,
      ),
    ]);
    final container = ProviderContainer(
      overrides: [
        loginControllerProvider.overrideWith(
          () => _StaticLoginController(_session('ADMIN')),
        ),
        auditRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(auditLogControllerProvider.future);
    await container
        .read(auditLogControllerProvider.notifier)
        .applyFilters(
          branchId: 'branch-1',
          actionKey: 'attendance.checkIn',
          outcome: AuditOutcome.success,
        );

    var state = container.read(auditLogControllerProvider).requireValue;
    expect(state.items, hasLength(1));
    expect(state.items.first.id, 'event-2');

    final filterCall = repository.calls[1];
    expect(filterCall.branchId, 'branch-1');
    expect(filterCall.actionKey, 'attendance.checkIn');
    expect(filterCall.outcome, AuditOutcome.success);

    await container.read(auditLogControllerProvider.notifier).loadMore();

    state = container.read(auditLogControllerProvider).requireValue;
    expect(state.items.map((item) => item.id), ['event-2', 'event-3']);
    expect(repository.calls.last.offset, 1);
  });

  test('controller stays empty for non-audit role sessions', () async {
    final repository = _RecordingAuditRepository([]);
    final container = ProviderContainer(
      overrides: [
        loginControllerProvider.overrideWith(
          () => _StaticLoginController(_session('MANAGER')),
        ),
        auditRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(auditLogControllerProvider.future);

    expect(state.items, isEmpty);
    expect(repository.calls, isEmpty);
  });

  test('controller can switch to a specific audit page', () async {
    final repository = _RecordingAuditRepository([
      AuditEventPage(
        items: [_event('event-1')],
        limit: 50,
        offset: 0,
        total: 120,
        hasMore: true,
      ),
      AuditEventPage(
        items: [_event('event-51')],
        limit: 50,
        offset: 50,
        total: 120,
        hasMore: true,
      ),
    ]);
    final container = ProviderContainer(
      overrides: [
        loginControllerProvider.overrideWith(
          () => _StaticLoginController(_session('ADMIN')),
        ),
        auditRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(auditLogControllerProvider.future);
    await container.read(auditLogControllerProvider.notifier).goToPage(2);

    final state = container.read(auditLogControllerProvider).requireValue;
    expect(state.offset, 50);
    expect(state.items.single.id, 'event-51');
    expect(repository.calls.last.offset, 50);
  });
}
