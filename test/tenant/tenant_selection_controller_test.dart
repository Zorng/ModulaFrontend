import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/data/auth_repository.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/tenant/data/tenant_repository.dart';
import 'package:modular_pos/features/tenant/domain/models/tenant_profile.dart';
import 'package:modular_pos/features/tenant/domain/models/tenant_provision_result.dart';
import 'package:modular_pos/features/tenant/ui/viewmodels/tenant_selection/tenant_selection_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils/riverpod_test_utils.dart';

class _NoopAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> login(String username, String password) =>
      Future<AuthSession>.error(UnimplementedError());

  @override
  Future<AuthBranchContextOptions> listBranchContexts({
    required AuthSession currentSession,
  }) => Future<AuthBranchContextOptions>.error(UnimplementedError());

  @override
  Future<AuthSession> selectBranch({
    required AuthSession currentSession,
    required String branchId,
  }) => Future<AuthSession>.error(UnimplementedError());

  @override
  Future<AuthSendOtpResult> sendRegistrationOtp({required String phone}) =>
      Future<AuthSendOtpResult>.error(UnimplementedError());

  @override
  Future<AuthRegisterAccountResult> registerAccount({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    String? gender,
    String? dateOfBirth,
  }) => Future<AuthRegisterAccountResult>.error(UnimplementedError());

  @override
  Future<AuthVerifyOtpResult> verifyRegistrationOtp({
    required String phone,
    required String otp,
  }) => Future<AuthVerifyOtpResult>.error(UnimplementedError());

  @override
  Future<AuthSession> selectTenant({
    required String selectionToken,
    required String tenantId,
    String? branchId,
  }) => Future<AuthSession>.error(UnimplementedError());

  @override
  Future<AuthSession> refreshSession({required AuthSession currentSession}) =>
      Future<AuthSession>.error(UnimplementedError());

  @override
  Future<void> logout({String? refreshToken}) async {}
}

class _StubTenantRepository implements TenantRepository {
  _StubTenantRepository({this.onCreateTenant});

  final Future<TenantProvisionResult> Function({required String tenantName})?
  onCreateTenant;

  @override
  Future<TenantProvisionResult> createTenant({required String tenantName}) {
    if (onCreateTenant != null) {
      return onCreateTenant!(tenantName: tenantName);
    }
    return Future<TenantProvisionResult>.error(UnimplementedError());
  }

  @override
  Future<TenantProfile> getCurrentTenantProfile() =>
      Future<TenantProfile>.error(UnimplementedError());
}

AuthSession _session() {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Tester',
      role: 'admin',
      tenantId: 'tenant-1',
      branches: const <UserBranch>[],
    ),
    memberships: const [
      TenantMembership(
        tenantId: 'tenant-1',
        tenantName: 'Tenant 1',
        role: 'OWNER',
        branches: <UserBranch>[],
      ),
    ],
    activeTenantId: 'tenant-1',
    accessToken: 'access-1',
    refreshToken: 'refresh-1',
    accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'createTenant in viewmodel calls repository and updates session membership',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AuthSessionStore(prefs);
      final initialSession = _session();

      var capturedTenantName = '';
      final tenantRepository = _StubTenantRepository(
        onCreateTenant: ({required tenantName}) async {
          capturedTenantName = tenantName;
          return const TenantProvisionResult(
            tenantId: 'tenant-2',
            tenantName: 'Tenant 2',
            tenantStatus: 'ACTIVE',
            ownerMembershipId: 'membership-2',
            ownerRoleKey: 'OWNER',
            ownerStatus: 'ACTIVE',
            branch: null,
          );
        },
      );

      final container = createTestContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_NoopAuthRepository()),
          authSessionStoreProvider.overrideWithValue(store),
          initialAuthSessionProvider.overrideWithValue(initialSession),
          tenantRepositoryProvider.overrideWithValue(tenantRepository),
        ],
      );

      final result = await container
          .read(tenantSelectionControllerProvider.notifier)
          .createTenant('  Tenant 2  ');

      expect(result, isNotNull);
      expect(capturedTenantName, 'Tenant 2');

      final session = container.read(loginControllerProvider).session;
      expect(session, isNotNull);
      expect(session!.memberships, hasLength(2));
      expect(
        session.memberships.any(
          (membership) => membership.tenantId == 'tenant-2',
        ),
        isTrue,
      );
    },
  );

  test('createTenant ignores empty tenant name input', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AuthSessionStore(prefs);
    final initialSession = _session();

    var createCalls = 0;
    final tenantRepository = _StubTenantRepository(
      onCreateTenant: ({required tenantName}) async {
        createCalls++;
        throw UnimplementedError();
      },
    );

    final container = createTestContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_NoopAuthRepository()),
        authSessionStoreProvider.overrideWithValue(store),
        initialAuthSessionProvider.overrideWithValue(initialSession),
        tenantRepositoryProvider.overrideWithValue(tenantRepository),
      ],
    );

    final result = await container
        .read(tenantSelectionControllerProvider.notifier)
        .createTenant('   ');

    final state = container.read(tenantSelectionControllerProvider);
    expect(result, isNull);
    expect(createCalls, 0);
    expect(state.isCreatingTenant, isFalse);
    expect(state.createTenantErrorCode, 'INVALID_INPUT');
    expect(state.createTenantErrorStatusCode, 422);
  });

  test('createTenant stores backend error code and status in state', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AuthSessionStore(prefs);
    final initialSession = _session();

    final tenantRepository = _StubTenantRepository(
      onCreateTenant: ({required tenantName}) async {
        throw const ApiClientException(
          message: 'Upgrade plan required.',
          code: 'FAIRUSE_HARD_LIMIT_EXCEEDED',
          statusCode: 409,
        );
      },
    );

    final container = createTestContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_NoopAuthRepository()),
        authSessionStoreProvider.overrideWithValue(store),
        initialAuthSessionProvider.overrideWithValue(initialSession),
        tenantRepositoryProvider.overrideWithValue(tenantRepository),
      ],
    );

    final result = await container
        .read(tenantSelectionControllerProvider.notifier)
        .createTenant('Tenant X');

    final state = container.read(tenantSelectionControllerProvider);
    expect(result, isNull);
    expect(state.isCreatingTenant, isFalse);
    expect(state.createTenantError, 'Upgrade plan required.');
    expect(state.createTenantErrorCode, 'FAIRUSE_HARD_LIMIT_EXCEEDED');
    expect(state.createTenantErrorStatusCode, 409);
  });
}
