import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/data/auth_repository_session_utils.dart';
import 'package:modular_pos/features/auth/data/membership_invitation_repository.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/membership_invitation.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/view/invitation_inbox/invitation_inbox_page.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/tenant/ui/view/tenant_selection/tenant_selection_page.dart';

class _StaticLoginController extends LoginController {
  _StaticLoginController(this._session);

  final AuthSession _session;

  @override
  LoginState build() => LoginState(session: _session);

  @override
  Future<void> upsertSessionTenantMembership({
    required String tenantId,
    required String tenantName,
    required String role,
    List<UserBranch> branches = const <UserBranch>[],
  }) async {
    final current = state.session;
    if (current == null) return;
    state = state.copyWith(
      session: upsertTenantMembership(
        current,
        tenantId: tenantId,
        tenantName: tenantName,
        role: role,
        branches: branches,
      ),
    );
  }
}

class _FakeMembershipInvitationRepository
    implements MembershipInvitationRepository {
  _FakeMembershipInvitationRepository({
    List<MembershipInvitation> invitations = const <MembershipInvitation>[],
    this.listCompleter,
    this.listError,
    this.acceptError,
    this.rejectError,
  }) : _invitations = invitations.toList(growable: true);

  final List<MembershipInvitation> _invitations;
  final Completer<List<MembershipInvitation>>? listCompleter;
  final Object? listError;
  final Object? acceptError;
  final Object? rejectError;

  @override
  Future<List<MembershipInvitation>> listInvitations({
    String? accessTokenOverride,
  }) async {
    if (listCompleter != null) {
      return listCompleter!.future;
    }
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
    if (acceptError != null) throw acceptError!;
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
    if (rejectError != null) throw rejectError!;
    _invitations.removeWhere((item) => item.membershipId == membershipId);
    return MembershipInvitationRejectResult(
      membershipId: membershipId,
      tenantId: 'tenant-2',
      status: MembershipInvitationStatus.revoked,
    );
  }
}

AuthSession _selectionSession() {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Invited User',
      role: '',
      tenantId: '',
      phone: '+85512345678',
      status: 'ACTIVE',
    ),
    memberships: const <TenantMembership>[
      TenantMembership(
        membershipId: 'membership-1',
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

MembershipInvitation _invitation() {
  return MembershipInvitation(
    membershipId: 'membership-2',
    tenantId: 'tenant-2',
    tenantName: 'Nodepresso',
    roleKey: 'CASHIER',
    invitedAt: DateTime.utc(2026, 3, 8, 9, 30),
    invitedByMembershipId: 'membership-owner',
  );
}

Widget _pageHarness(MembershipInvitationRepository repository) {
  return ProviderScope(
    overrides: [
      loginControllerProvider.overrideWith(
        () => _StaticLoginController(_selectionSession()),
      ),
      membershipInvitationRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(home: InvitationInboxPage()),
  );
}

Widget _routerHarness(MembershipInvitationRepository repository) {
  final router = GoRouter(
    initialLocation: AppRoute.tenantSelection.path,
    routes: [
      GoRoute(
        path: AppRoute.tenantSelection.path,
        builder: (context, state) => const TenantSelectionPage(),
      ),
      GoRoute(
        path: AppRoute.invitationInbox.path,
        builder: (context, state) => const InvitationInboxPage(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      loginControllerProvider.overrideWith(
        () => _StaticLoginController(_selectionSession()),
      ),
      membershipInvitationRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('InvitationInboxPage shows loading state while fetching', (
    tester,
  ) async {
    final completer = Completer<List<MembershipInvitation>>();

    await tester.pumpWidget(
      _pageHarness(
        _FakeMembershipInvitationRepository(listCompleter: completer),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(<MembershipInvitation>[_invitation()]);
    await tester.pumpAndSettle();
  });

  testWidgets('InvitationInboxPage shows invitation card and actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _pageHarness(
        _FakeMembershipInvitationRepository(
          invitations: <MembershipInvitation>[_invitation()],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nodepresso'), findsOneWidget);
    expect(find.text('Cashier'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
  });

  testWidgets('InvitationInboxPage shows retry state on fatal error', (
    tester,
  ) async {
    await tester.pumpWidget(
      _pageHarness(
        _FakeMembershipInvitationRepository(
          listError: Exception('load failed'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Failed to load invitations'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
  });

  testWidgets('InvitationInboxPage accepts invite and stays on inbox page', (
    tester,
  ) async {
    await tester.pumpWidget(
      _pageHarness(
        _FakeMembershipInvitationRepository(
          invitations: <MembershipInvitation>[_invitation()],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Accept'));
    await tester.pumpAndSettle();

    expect(find.text('Invitation Inbox'), findsOneWidget);
    expect(find.text('Invitation accepted.'), findsOneWidget);
    expect(find.text('No invitations right now.'), findsOneWidget);
  });

  testWidgets('InvitationInboxPage rejects invite and stays on inbox page', (
    tester,
  ) async {
    await tester.pumpWidget(
      _pageHarness(
        _FakeMembershipInvitationRepository(
          invitations: <MembershipInvitation>[_invitation()],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Reject'));
    await tester.pumpAndSettle();

    expect(find.text('Invitation Inbox'), findsOneWidget);
    expect(find.text('Invitation rejected.'), findsOneWidget);
    expect(find.text('No invitations right now.'), findsOneWidget);
  });

  testWidgets(
    'InvitationInboxPage shows deterministic mutation error feedback',
    (tester) async {
      await tester.pumpWidget(
        _pageHarness(
          _FakeMembershipInvitationRepository(
            invitations: <MembershipInvitation>[_invitation()],
            acceptError: Exception('boom'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Accept'));
      await tester.pumpAndSettle();

      expect(find.text('Invitation Inbox'), findsOneWidget);
      expect(find.text('Failed to accept invitation.'), findsWidgets);
      expect(find.text('Nodepresso'), findsOneWidget);
    },
  );

  testWidgets(
    'InvitationInboxPage shows deterministic reject mutation error feedback',
    (tester) async {
      await tester.pumpWidget(
        _pageHarness(
          _FakeMembershipInvitationRepository(
            invitations: <MembershipInvitation>[_invitation()],
            rejectError: Exception('boom'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Reject'));
      await tester.pumpAndSettle();

      expect(find.text('Invitation Inbox'), findsOneWidget);
      expect(find.text('Failed to reject invitation.'), findsWidgets);
      expect(find.text('Nodepresso'), findsOneWidget);
    },
  );

  testWidgets('Tenant selection inbox action opens invitation inbox page', (
    tester,
  ) async {
    await tester.pumpWidget(
      _routerHarness(
        _FakeMembershipInvitationRepository(
          invitations: <MembershipInvitation>[_invitation()],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Inbox'));
    await tester.pumpAndSettle();

    expect(find.text('Invitation Inbox'), findsOneWidget);
    expect(find.text('Nodepresso'), findsOneWidget);
  });

  testWidgets(
    'Accepted invitation appears in tenant selection after leaving inbox',
    (tester) async {
      await tester.pumpWidget(
        _routerHarness(
          _FakeMembershipInvitationRepository(
            invitations: <MembershipInvitation>[_invitation()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Existing Tenant'), findsOneWidget);
      expect(find.text('Nodepresso'), findsNothing);

      await tester.tap(find.byTooltip('Inbox'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Accept'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Existing Tenant'), findsOneWidget);
      expect(find.text('Nodepresso'), findsOneWidget);
    },
  );
}
