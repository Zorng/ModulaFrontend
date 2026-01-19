import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/hydration/app_hydration_listener.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_tenant_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_token_provider.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';

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
  Future<void> load({String? branchId}) {
    loadCount += 1;
    loadedBranchIds.add(branchId);
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
  Future<void> load({String? registerId, String? branchIdOverride}) {
    loadCount += 1;
    loadedBranchIds.add(branchIdOverride);
    return Future.value();
  }

  @override
  void reset() {
    resetCount += 1;
    super.reset();
  }
}

AuthSession _buildSession({
  required String tenantId,
  required String accessToken,
  required List<UserBranch> branches,
  String? activeTenantId,
}) {
  final user = User(
    id: 'user-1',
    name: 'Test User',
    role: 'admin',
    tenantId: tenantId,
    branches: branches,
  );

  return AuthSession(
    user: user,
    memberships: [
      TenantMembership(
        tenantId: tenantId,
        tenantName: 'Tenant',
        role: user.role,
        branches: branches,
      ),
    ],
    activeTenantId: activeTenantId ?? tenantId,
    accessToken: accessToken,
    refreshToken: 'refresh',
    accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
  );
}

void main() {
  testWidgets('hydrates token/tenant and refreshes policy/cash session per branch', (
    tester,
  ) async {
    final container = createTestContainer(
      overrides: [
        loginControllerProvider.overrideWith(_TestLoginController.new),
        policyNotifierProvider.overrideWith(_TestPolicyNotifier.new),
        cashSessionViewModelProvider.overrideWith(_TestCashSessionViewModel.new),
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

    final policy =
        container.read(policyNotifierProvider.notifier) as _TestPolicyNotifier;
    final cash = container.read(cashSessionViewModelProvider.notifier)
        as _TestCashSessionViewModel;

    expect(container.read(authAccessTokenProvider), isNull);
    expect(container.read(authTenantIdProvider), isNull);
    expect(container.read(authActiveBranchOverrideProvider), isNull);
    expect(policy.resetCount, 1);
    expect(cash.resetCount, 1);

    final login = container.read(loginControllerProvider.notifier) as _TestLoginController;
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

    container.read(authActiveBranchOverrideProvider.notifier).setOverride('branch-b');
    await tester.pump();

    expect(policy.loadCount, 2);
    expect(policy.loadedBranchIds, ['branch-a', 'branch-b']);
    expect(cash.loadCount, 2);
    expect(cash.loadedBranchIds, ['branch-a', 'branch-b']);

    login.setSession(null);
    await tester.pump();

    expect(container.read(authAccessTokenProvider), isNull);
    expect(container.read(authTenantIdProvider), isNull);
    expect(container.read(authActiveBranchOverrideProvider), isNull);
    expect(policy.resetCount, 2);
    expect(cash.resetCount, 2);
  });
}
