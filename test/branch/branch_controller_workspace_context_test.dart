import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/domain/workspace_context.dart';
import 'package:modular_pos/features/auth/domain/workspace_context_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/branchV2/data/branch_repository.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_state.dart';

import '../test_utils/riverpod_test_utils.dart';

class _StubBranchRepository implements BranchRepository {
  @override
  Future<List<BranchListItem>> loadAccessibleBranches() {
    return Future.value(const <BranchListItem>[]);
  }

  @override
  Future<BranchActivationDraft> initiateBranchActivation({
    required String branchName,
    String? intentId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BranchActivationResult> confirmBranchActivation({
    required String draftId,
    required String paymentToken,
    String? intentId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BranchContextTokens> selectBranchContext({required String branchId}) {
    throw UnimplementedError();
  }
}

class _TestLoginController extends LoginController {
  _TestLoginController(this._initialSession);

  final AuthSession _initialSession;

  @override
  LoginState build() => LoginState(session: _initialSession);

  @override
  Future<void> selectBranch(String branchId) async {
    final current = state.session;
    if (current == null) return;
    final resolved = branchId.trim();
    final nextBranches = current.user.branches
        .map(
          (branch) => UserBranch(
            id: branch.id,
            name: branch.name,
            role: branch.role,
            active: branch.branchId == resolved || branch.id == resolved,
            employeeId: branch.employeeId,
            branchId: branch.branchId,
          ),
        )
        .toList(growable: false);

    state = state.copyWith(
      session: current.copyWith(
        user: current.user.copyWith(branches: nextBranches),
      ),
      requiresBranchSelection: false,
      branchOptions: const [],
      error: null,
      errorCode: null,
      errorStatusCode: null,
      isLoading: false,
    );
  }
}

AuthSession _session({required String role, required String membershipRole}) {
  final branches = const [
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
  ];

  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Tester',
      role: role,
      tenantId: 'tenant-1',
      branches: branches,
    ),
    memberships: [
      TenantMembership(
        membershipId: 'membership-1',
        tenantId: 'tenant-1',
        tenantName: 'Tenant 1',
        role: membershipRole,
        branches: branches,
      ),
    ],
    activeTenantId: 'tenant-1',
    accessToken: 'access-1',
    refreshToken: 'refresh-1',
    accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
  );
}

void main() {
  test(
    'global management tap sets global workspace context for admin',
    () async {
      final container = createTestContainer(
        overrides: [
          loginControllerProvider.overrideWith(
            () => _TestLoginController(
              _session(role: 'admin', membershipRole: 'ADMIN'),
            ),
          ),
          branchRepositoryProvider.overrideWithValue(_StubBranchRepository()),
        ],
      );

      await container
          .read(branchControllerProvider.notifier)
          .onGlobalManagementTap();

      expect(
        container.read(workspaceContextProvider),
        WorkspaceContext.globalManagement,
      );
      expect(
        container.read(branchControllerProvider).navigationIntent,
        BranchNavigationIntent.globalManagement,
      );
    },
  );

  test(
    'global management tap sets global workspace context for store role',
    () async {
      final container = createTestContainer(
        overrides: [
          loginControllerProvider.overrideWith(
            () => _TestLoginController(
              _session(role: '', membershipRole: 'store'),
            ),
          ),
          branchRepositoryProvider.overrideWithValue(_StubBranchRepository()),
        ],
      );

      final stateBeforeTap = container.read(branchControllerProvider);
      expect(stateBeforeTap.canManageTenant, isTrue);

      await container
          .read(branchControllerProvider.notifier)
          .onGlobalManagementTap();

      expect(
        container.read(workspaceContextProvider),
        WorkspaceContext.globalManagement,
      );
      expect(
        container.read(branchControllerProvider).navigationIntent,
        BranchNavigationIntent.globalManagement,
      );
    },
  );

  test('branch tap sets branch management workspace for admin', () async {
    final container = createTestContainer(
      overrides: [
        loginControllerProvider.overrideWith(
          () => _TestLoginController(
            _session(role: 'admin', membershipRole: 'ADMIN'),
          ),
        ),
        branchRepositoryProvider.overrideWithValue(_StubBranchRepository()),
      ],
    );

    await container
        .read(branchControllerProvider.notifier)
        .onBranchTileTap(branchId: 'branch-b');

    final context = container.read(workspaceContextProvider);
    expect(context?.scope, WorkspaceScope.branch);
    expect(context?.mode, WorkspaceMode.management);
    expect(context?.activeBranchId, 'branch-b');
    expect(container.read(authActiveBranchOverrideProvider), 'branch-b');
    expect(
      container.read(branchControllerProvider).navigationIntent,
      BranchNavigationIntent.branchWorkspace,
    );
  });

  test('branch tap sets branch POS workspace for cashier', () async {
    final container = createTestContainer(
      overrides: [
        loginControllerProvider.overrideWith(
          () => _TestLoginController(
            _session(role: 'cashier', membershipRole: 'CASHIER'),
          ),
        ),
        branchRepositoryProvider.overrideWithValue(_StubBranchRepository()),
      ],
    );

    await container
        .read(branchControllerProvider.notifier)
        .onBranchTileTap(branchId: 'branch-a');

    final context = container.read(workspaceContextProvider);
    expect(context?.scope, WorkspaceScope.branch);
    expect(context?.mode, WorkspaceMode.pos);
    expect(context?.activeBranchId, 'branch-a');
    expect(container.read(authActiveBranchOverrideProvider), 'branch-a');
    expect(
      container.read(branchControllerProvider).navigationIntent,
      BranchNavigationIntent.branchWorkspace,
    );
  });
}
