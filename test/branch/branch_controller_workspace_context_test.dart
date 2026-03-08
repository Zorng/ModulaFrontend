import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/api_contract.dart';
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
  _StubBranchRepository({
    this.currentBranchError,
    this.updateKhqrError,
  });

  final ApiClientException? currentBranchError;
  final ApiClientException? updateKhqrError;

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
  Future<BranchListItem> getCurrentBranchProfile() {
    if (currentBranchError != null) return Future<BranchListItem>.error(currentBranchError!);
    return Future.value(
      const BranchListItem(
        branchId: 'branch-a',
        tenantId: 'tenant-1',
        branchName: 'Branch A',
        status: 'ACTIVE',
      ),
    );
  }

  @override
  Future<BranchListItem> updateCurrentBranchKhqrReceiver({
    required String khqrReceiverAccountId,
    required String khqrReceiverName,
  }) {
    if (updateKhqrError != null) return Future<BranchListItem>.error(updateKhqrError!);
    return Future.value(
      BranchListItem(
        branchId: 'branch-a',
        tenantId: 'tenant-1',
        branchName: 'Branch A',
        status: 'ACTIVE',
        khqrReceiverAccountId: khqrReceiverAccountId,
        khqrReceiverName: khqrReceiverName,
      ),
    );
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

  test('loadCurrentBranchProfile stores current branch profile', () async {
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
        .loadCurrentBranchProfile();

    final state = container.read(branchControllerProvider);
    expect(state.currentBranchProfile, isNotNull);
    expect(state.currentBranchProfile!.branchId, 'branch-a');
    expect(state.currentBranchProfile!.branchName, 'Branch A');
  });

  test('updateCurrentBranchKhqrReceiver stores updated profile data', () async {
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

    await container.read(branchControllerProvider.notifier).loadInitial();
    await container.read(branchControllerProvider.notifier).updateCurrentBranchKhqrReceiver(
      khqrReceiverAccountId: 'bakong-001',
      khqrReceiverName: 'Main Branch Receiver',
    );

    final state = container.read(branchControllerProvider);
    expect(state.currentBranchProfile, isNotNull);
    expect(state.currentBranchProfile!.khqrReceiverAccountId, 'bakong-001');
    expect(state.currentBranchProfile!.khqrReceiverName, 'Main Branch Receiver');
    expect(
      state.branches.firstWhere((item) => item.branchId == 'branch-a').khqrReceiverAccountId,
      'bakong-001',
    );
  });

  test('loadCurrentBranchProfile normalizes branch access error code', () async {
    final container = createTestContainer(
      overrides: [
        loginControllerProvider.overrideWith(
          () => _TestLoginController(
            _session(role: 'admin', membershipRole: 'ADMIN'),
          ),
        ),
        branchRepositoryProvider.overrideWithValue(
          _StubBranchRepository(
            currentBranchError: const ApiClientException(
              message: 'No branch access.',
              code: 'no-branch-access',
              statusCode: 403,
            ),
          ),
        ),
      ],
    );

    await container
        .read(branchControllerProvider.notifier)
        .loadCurrentBranchProfile();

    final state = container.read(branchControllerProvider);
    expect(state.errorCode, 'NO_BRANCH_ACCESS');
    expect(state.errorStatusCode, 403);
  });

  test('updateCurrentBranchKhqrReceiver normalizes KHQR receiver error code', () async {
    final container = createTestContainer(
      overrides: [
        loginControllerProvider.overrideWith(
          () => _TestLoginController(
            _session(role: 'admin', membershipRole: 'ADMIN'),
          ),
        ),
        branchRepositoryProvider.overrideWithValue(
          _StubBranchRepository(
            updateKhqrError: const ApiClientException(
              message: 'Invalid KHQR receiver.',
              code: 'org-branch-khqr-receiver-invalid',
              statusCode: 422,
            ),
          ),
        ),
      ],
    );

    await container.read(branchControllerProvider.notifier).updateCurrentBranchKhqrReceiver(
      khqrReceiverAccountId: 'bad',
      khqrReceiverName: 'Receiver',
    );

    final state = container.read(branchControllerProvider);
    expect(state.errorCode, 'ORG_BRANCH_KHQR_RECEIVER_INVALID');
    expect(state.errorStatusCode, 422);
  });
}
