import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/data/membership_invitation_repository.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/membership_invitation.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/membership_invitation_inbox_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils/riverpod_test_utils.dart';

class _FakeMembershipInvitationRepository
    implements MembershipInvitationRepository {
  _FakeMembershipInvitationRepository({
    List<MembershipInvitation> invitations = const [],
  }) : _invitations = invitations.toList(growable: true);

  final List<MembershipInvitation> _invitations;
  Object? listError;
  int listCalls = 0;
  final List<String> acceptedMembershipIds = <String>[];
  final List<String> rejectedMembershipIds = <String>[];

  @override
  Future<List<MembershipInvitation>> listInvitations({
    String? accessTokenOverride,
  }) async {
    listCalls += 1;
    if (listError != null) {
      throw listError!;
    }
    return List<MembershipInvitation>.unmodifiable(_invitations);
  }

  @override
  Future<MembershipInvitationAcceptResult> acceptInvitation({
    required String membershipId,
    String? intentId,
    String? accessTokenOverride,
  }) async {
    acceptedMembershipIds.add(membershipId);
    _invitations.removeWhere((item) => item.membershipId == membershipId);
    return MembershipInvitationAcceptResult(
      membershipId: membershipId,
      tenantId: 'tenant-2',
      status: MembershipInvitationStatus.active,
      activeBranchIds: const <String>[],
    );
  }

  @override
  Future<MembershipInvitationRejectResult> rejectInvitation({
    required String membershipId,
    String? intentId,
    String? accessTokenOverride,
  }) async {
    rejectedMembershipIds.add(membershipId);
    _invitations.removeWhere((item) => item.membershipId == membershipId);
    return MembershipInvitationRejectResult(
      membershipId: membershipId,
      tenantId: 'tenant-2',
      status: MembershipInvitationStatus.revoked,
    );
  }
}

AuthSession _sessionWithSelectionToken() {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Tester',
      role: '',
      tenantId: '',
      phone: '+85512345678',
      status: 'ACTIVE',
    ),
    memberships: const <TenantMembership>[
      TenantMembership(
        membershipId: 'membership-existing',
        tenantId: 'tenant-1',
        tenantName: 'Existing Tenant',
        role: 'OWNER',
        branches: <UserBranch>[],
      ),
    ],
    activeTenantId: null,
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
    tenantSelectionToken: 'v0-context-selection',
  );
}

MembershipInvitation _invitation({
  String membershipId = 'membership-2',
  String tenantId = 'tenant-2',
  String tenantName = 'Invited Tenant',
  String roleKey = 'CASHIER',
}) {
  return MembershipInvitation(
    membershipId: membershipId,
    tenantId: tenantId,
    tenantName: tenantName,
    roleKey: roleKey,
    invitedAt: DateTime.utc(2026, 3, 8, 1, 2, 3),
    invitedByMembershipId: 'membership-owner',
  );
}

void main() {
  test('build loads invitations from repository', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final store = AuthSessionStore(prefs);
    final repository = _FakeMembershipInvitationRepository(
      invitations: <MembershipInvitation>[_invitation()],
    );
    final container = createTestContainer(
      overrides: [
        authSessionStoreProvider.overrideWithValue(store),
        initialAuthSessionProvider.overrideWithValue(
          _sessionWithSelectionToken(),
        ),
        membershipInvitationRepositoryProvider.overrideWithValue(repository),
      ],
    );

    final state = await container.read(
      membershipInvitationInboxControllerProvider.future,
    );

    expect(repository.listCalls, 1);
    expect(state.invitations, hasLength(1));
    expect(state.invitations.first.tenantName, 'Invited Tenant');
  });

  test('refresh keeps stale data and exposes inlineError on failure', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final store = AuthSessionStore(prefs);
    final repository = _FakeMembershipInvitationRepository(
      invitations: <MembershipInvitation>[_invitation()],
    );
    final container = createTestContainer(
      overrides: [
        authSessionStoreProvider.overrideWithValue(store),
        initialAuthSessionProvider.overrideWithValue(
          _sessionWithSelectionToken(),
        ),
        membershipInvitationRepositoryProvider.overrideWithValue(repository),
      ],
    );

    await container.read(membershipInvitationInboxControllerProvider.future);
    repository.listError = ApiClientException(
      message: 'Failed to load invitations.',
      code: 'INBOX_DOWN',
      statusCode: 503,
    );

    await container
        .read(membershipInvitationInboxControllerProvider.notifier)
        .refresh();

    final state = container
        .read(membershipInvitationInboxControllerProvider)
        .requireValue;
    expect(state.invitations, hasLength(1));
    expect(state.isRefreshing, isFalse);
    expect(state.inlineError, 'Failed to load invitations.');
  });

  test(
    'acceptInvitation removes invite and upserts tenant membership',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final store = AuthSessionStore(prefs);
      final repository = _FakeMembershipInvitationRepository(
        invitations: <MembershipInvitation>[_invitation()],
      );
      final container = createTestContainer(
        overrides: [
          authSessionStoreProvider.overrideWithValue(store),
          initialAuthSessionProvider.overrideWithValue(
            _sessionWithSelectionToken(),
          ),
          membershipInvitationRepositoryProvider.overrideWithValue(repository),
        ],
      );

      final invitation = (await container.read(
        membershipInvitationInboxControllerProvider.future,
      )).invitations.single;

      final result = await container
          .read(membershipInvitationInboxControllerProvider.notifier)
          .acceptInvitation(invitation);

      expect(result.isSuccess, isTrue);
      expect(result.message, 'Invitation accepted.');
      final inboxState = container
          .read(membershipInvitationInboxControllerProvider)
          .requireValue;
      expect(repository.acceptedMembershipIds, <String>['membership-2']);
      expect(inboxState.invitations, isEmpty);
      expect(inboxState.acceptingMembershipIds, isEmpty);

      final loginState = container.read(loginControllerProvider);
      expect(
        loginState.session?.memberships.any(
          (membership) => membership.tenantId == 'tenant-2',
        ),
        isTrue,
      );
      final acceptedMembership = loginState.session!.memberships.firstWhere(
        (membership) => membership.tenantId == 'tenant-2',
      );
      expect(acceptedMembership.tenantName, 'Invited Tenant');
      expect(acceptedMembership.role, 'CASHIER');

      final persisted = await store.load();
      expect(
        persisted?.memberships.any(
          (membership) => membership.tenantId == 'tenant-2',
        ),
        isTrue,
      );
    },
  );

  test(
    'rejectInvitation removes invite without mutating session memberships',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final store = AuthSessionStore(prefs);
      final repository = _FakeMembershipInvitationRepository(
        invitations: <MembershipInvitation>[_invitation()],
      );
      final container = createTestContainer(
        overrides: [
          authSessionStoreProvider.overrideWithValue(store),
          initialAuthSessionProvider.overrideWithValue(
            _sessionWithSelectionToken(),
          ),
          membershipInvitationRepositoryProvider.overrideWithValue(repository),
        ],
      );

      final invitation = (await container.read(
        membershipInvitationInboxControllerProvider.future,
      )).invitations.single;

      final result = await container
          .read(membershipInvitationInboxControllerProvider.notifier)
          .rejectInvitation(invitation);

      expect(result.isSuccess, isTrue);
      expect(result.message, 'Invitation rejected.');
      final inboxState = container
          .read(membershipInvitationInboxControllerProvider)
          .requireValue;
      expect(repository.rejectedMembershipIds, <String>['membership-2']);
      expect(inboxState.invitations, isEmpty);
      expect(inboxState.rejectingMembershipIds, isEmpty);

      final loginState = container.read(loginControllerProvider);
      expect(loginState.session?.memberships, hasLength(1));
      expect(
        loginState.session?.memberships.any(
          (membership) => membership.tenantId == 'tenant-2',
        ),
        isFalse,
      );
    },
  );
}
