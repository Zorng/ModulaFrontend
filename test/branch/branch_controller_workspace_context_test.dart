import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/branchV2/data/branch_repository.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_state.dart';

import '../test_utils/riverpod_test_utils.dart';

class _StubBranchRepository implements BranchRepository {
  @override
  Future<List<BranchListItem>> loadAccessibleBranches() {
    return Future.value(const <BranchListItem>[
      BranchListItem(
        branchId: 'branch-a',
        tenantId: 'tenant-1',
        branchName: 'Branch A',
        status: 'ACTIVE',
      ),
      BranchListItem(
        branchId: 'branch-b',
        tenantId: 'tenant-1',
        branchName: 'Branch B',
        status: 'ACTIVE',
      ),
    ]);
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
  _TestLoginController(this._initialSession, {this.branchError});

  final AuthSession _initialSession;
  final String? branchError;

  @override
  LoginState build() => LoginState(session: _initialSession);

  @override
  Future<void> selectBranch(String branchId) async {
    if ((branchError ?? '').trim().isNotEmpty) {
      state = state.copyWith(
        error: branchError,
        errorCode: branchError,
        errorStatusCode: 409,
        isLoading: false,
      );
      return;
    }

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
  const branches = [
    UserBranch(
      id: 'assign-a',
      name: 'Branch A',
      role: 'admin',
      active: false,
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

AuthSession _sessionWithoutMatchingUserBranches({
  required String role,
  required String membershipRole,
}) {
  const membershipBranches = [
    UserBranch(
      id: 'assign-a',
      name: 'Branch A',
      role: 'admin',
      active: false,
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
      branches: const [],
    ),
    memberships: [
      TenantMembership(
        membershipId: 'membership-1',
        tenantId: 'tenant-1',
        tenantName: 'Tenant 1',
        role: membershipRole,
        branches: membershipBranches,
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
    'loadInitial redirects to tenant selection when tenant context is missing',
    () async {
      final session = AuthSession(
        user: User(
          id: 'user-1',
          name: 'Tester',
          role: '',
          tenantId: '',
          branches: [],
        ),
        memberships: const [
          TenantMembership(
            membershipId: 'membership-1',
            tenantId: 'tenant-1',
            tenantName: 'Tenant 1',
            role: 'CASHIER',
            branches: [],
          ),
        ],
        activeTenantId: null,
        tenantSelectionToken: 'selection-token-123',
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      final container = createTestContainer(
        overrides: [
          loginControllerProvider.overrideWith(
            () => _TestLoginController(session),
          ),
          branchRepositoryProvider.overrideWithValue(_StubBranchRepository()),
        ],
      );

      await container.read(branchControllerProvider.notifier).loadInitial();

      expect(
        container.read(branchControllerProvider).navigationIntent,
        BranchNavigationIntent.tenantSelection,
      );
    },
  );

  test(
    'branch tap returns tenantSelectionRequired when login selection reports tenant error',
    () async {
      final container = createTestContainer(
        overrides: [
          loginControllerProvider.overrideWith(
            () => _TestLoginController(
              _session(role: 'cashier', membershipRole: 'CASHIER'),
              branchError: 'TENANT_CONTEXT_REQUIRED',
            ),
          ),
          branchRepositoryProvider.overrideWithValue(_StubBranchRepository()),
        ],
      );

      await container.read(branchControllerProvider.notifier).loadInitial();
      final result = await container
          .read(branchControllerProvider.notifier)
          .onBranchTileTap(branchId: 'branch-a');

      expect(result, BranchSelectionResult.tenantSelectionRequired);
      expect(
        container.read(branchControllerProvider).navigationIntent,
        BranchNavigationIntent.tenantSelection,
      );
    },
  );

  test(
    'branch tap still establishes active branch context when session branch list is empty',
    () async {
      final container = createTestContainer(
        overrides: [
          loginControllerProvider.overrideWith(
            () => _TestLoginController(
              _sessionWithoutMatchingUserBranches(
                role: 'admin',
                membershipRole: 'ADMIN',
              ),
            ),
          ),
          branchRepositoryProvider.overrideWithValue(_StubBranchRepository()),
        ],
      );

      await container.read(branchControllerProvider.notifier).loadInitial();
      final result = await container
          .read(branchControllerProvider.notifier)
          .onBranchTileTap(branchId: 'branch-b');

      expect(result, BranchSelectionResult.success);
      expect(container.read(authActiveBranchOverrideProvider), 'branch-b');
      expect(container.read(authActiveBranchNameOverrideProvider), 'Branch B');
      expect(container.read(authActiveBranchIdProvider), 'branch-b');
      expect(
        container.read(branchControllerProvider).selectedBranchId,
        'branch-b',
      );
    },
  );
}
