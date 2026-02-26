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
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils/riverpod_test_utils.dart';

class _StubAuthRepository implements AuthRepository {
  _StubAuthRepository({
    this.onLogin,
    this.onSelectTenant,
    this.onListBranchContexts,
    this.onSelectBranch,
    this.onSendRegistrationOtp,
    this.onRefreshSession,
    this.onRegisterAccount,
    this.onVerifyRegistrationOtp,
  });

  final Future<AuthSession> Function(String username, String password)? onLogin;
  final Future<AuthSession> Function({
    required String selectionToken,
    required String tenantId,
    String? branchId,
  })?
  onSelectTenant;
  final Future<AuthBranchContextOptions> Function({
    required AuthSession currentSession,
  })?
  onListBranchContexts;
  final Future<AuthSession> Function({
    required AuthSession currentSession,
    required String branchId,
    bool verifyCurrentBranchProfile,
  })?
  onSelectBranch;
  final Future<AuthSendOtpResult> Function({required String phone})?
  onSendRegistrationOtp;
  final Future<AuthSession> Function({required AuthSession currentSession})?
  onRefreshSession;
  final Future<AuthRegisterAccountResult> Function({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    String? gender,
    String? dateOfBirth,
  })?
  onRegisterAccount;
  final Future<AuthVerifyOtpResult> Function({
    required String phone,
    required String otp,
  })?
  onVerifyRegistrationOtp;

  @override
  Future<AuthSession> login(String username, String password) {
    if (onLogin != null) return onLogin!(username, password);
    throw UnimplementedError('login not configured');
  }

  @override
  Future<AuthBranchContextOptions> listBranchContexts({
    required AuthSession currentSession,
  }) {
    if (onListBranchContexts != null) {
      return onListBranchContexts!(currentSession: currentSession);
    }
    throw UnimplementedError('listBranchContexts not configured');
  }

  @override
  Future<AuthSession> selectBranch({
    required AuthSession currentSession,
    required String branchId,
    bool verifyCurrentBranchProfile = true,
  }) {
    if (onSelectBranch != null) {
      return onSelectBranch!(
        currentSession: currentSession,
        branchId: branchId,
        verifyCurrentBranchProfile: verifyCurrentBranchProfile,
      );
    }
    throw UnimplementedError('selectBranch not configured');
  }

  @override
  Future<AuthSendOtpResult> sendRegistrationOtp({required String phone}) {
    if (onSendRegistrationOtp != null) {
      return onSendRegistrationOtp!(phone: phone);
    }
    throw UnimplementedError('sendRegistrationOtp not configured');
  }

  @override
  Future<AuthRegisterAccountResult> registerAccount({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    String? gender,
    String? dateOfBirth,
  }) {
    if (onRegisterAccount != null) {
      return onRegisterAccount!(
        phone: phone,
        password: password,
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        dateOfBirth: dateOfBirth,
      );
    }
    return Future<AuthRegisterAccountResult>.error(
      UnimplementedError('registerAccount not configured'),
    );
  }

  @override
  Future<AuthVerifyOtpResult> verifyRegistrationOtp({
    required String phone,
    required String otp,
  }) {
    if (onVerifyRegistrationOtp != null) {
      return onVerifyRegistrationOtp!(phone: phone, otp: otp);
    }
    return Future<AuthVerifyOtpResult>.error(
      UnimplementedError('verifyRegistrationOtp not configured'),
    );
  }

  @override
  Future<AuthSession> selectTenant({
    required String selectionToken,
    required String tenantId,
    String? branchId,
  }) {
    if (onSelectTenant != null) {
      return onSelectTenant!(
        selectionToken: selectionToken,
        tenantId: tenantId,
        branchId: branchId,
      );
    }
    return Future<AuthSession>.error(
      UnimplementedError('selectTenant not configured'),
    );
  }

  @override
  Future<AuthSession> refreshSession({required AuthSession currentSession}) {
    if (onRefreshSession != null) {
      return onRefreshSession!(currentSession: currentSession);
    }
    return Future<AuthSession>.error(
      UnimplementedError('refreshSession not configured'),
    );
  }

  @override
  Future<void> logout({String? refreshToken}) async {}
}

class _StubTenantRepository implements TenantRepository {
  _StubTenantRepository({this.onGetCurrentTenantProfile});

  final Future<TenantProfile> Function({String? accessTokenOverride})?
  onGetCurrentTenantProfile;

  @override
  Future<TenantProvisionResult> createTenant({required String tenantName}) {
    return Future<TenantProvisionResult>.error(
      UnimplementedError('createTenant not configured'),
    );
  }

  @override
  Future<TenantProfile> getCurrentTenantProfile({String? accessTokenOverride}) {
    if (onGetCurrentTenantProfile != null) {
      return onGetCurrentTenantProfile!(
        accessTokenOverride: accessTokenOverride,
      );
    }
    return Future<TenantProfile>.error(
      UnimplementedError('getCurrentTenantProfile not configured'),
    );
  }
}

AuthSession _session({
  required String accessToken,
  required List<UserBranch> branches,
}) {
  final user = User(
    id: 'user-1',
    name: 'Tester',
    role: 'admin',
    tenantId: 'tenant-1',
    branches: branches,
  );
  return AuthSession(
    user: user,
    memberships: [
      TenantMembership(
        tenantId: 'tenant-1',
        tenantName: 'Tenant 1',
        role: 'admin',
        branches: branches,
      ),
    ],
    activeTenantId: 'tenant-1',
    accessToken: accessToken,
    refreshToken: 'refresh-1',
    accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
  );
}

AuthSession _tenantSelectionSession() {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Tester',
      role: '',
      tenantId: '',
      phone: '+8551',
      status: 'ACTIVE',
    ),
    memberships: const [
      TenantMembership(
        membershipId: 'm-1',
        tenantId: 'tenant-1',
        tenantName: 'Tenant 1',
        role: 'OWNER',
        branches: [],
      ),
      TenantMembership(
        membershipId: 'm-2',
        tenantId: 'tenant-2',
        tenantName: 'Tenant 2',
        role: 'OWNER',
        branches: [],
      ),
    ],
    activeTenantId: null,
    accessToken: 'access-selection',
    refreshToken: 'refresh-selection',
    accessTokenExpiresAt: DateTime.now().toUtc().add(
      const Duration(minutes: 15),
    ),
    refreshTokenExpiresAt: DateTime.now().toUtc().add(
      const Duration(hours: 72),
    ),
    tenantSelectionToken: 'selection-token-123',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'login marks branch selection required when backend requires it',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AuthSessionStore(prefs);
      final initial = _session(accessToken: 'access-1', branches: const []);
      final repository = _StubAuthRepository(
        onLogin: (_, __) async => initial,
        onListBranchContexts: ({required currentSession}) async =>
            const AuthBranchContextOptions(
              state: 'BRANCH_SELECTION_REQUIRED',
              tenantId: 'tenant-1',
              selectedBranchId: null,
              branches: [
                AuthBranchContextOption(
                  branchId: 'branch-1',
                  branchName: 'Main Branch',
                ),
              ],
            ),
      );

      final container = createTestContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          authSessionStoreProvider.overrideWithValue(store),
          initialAuthSessionProvider.overrideWithValue(null),
        ],
      );

      await container
          .read(loginControllerProvider.notifier)
          .login('+8551', 'pw');
      final state = container.read(loginControllerProvider);

      expect(state.session, isNotNull);
      expect(state.requiresBranchSelection, isTrue);
      expect(state.branchOptions, hasLength(1));
      expect(state.branchOptions.first.branchId, 'branch-1');
    },
  );

  test('selectBranch resolves branch gate and updates session token', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AuthSessionStore(prefs);
    final initial = _session(accessToken: 'access-1', branches: const []);
    final selected = _session(
      accessToken: 'access-2',
      branches: const [
        UserBranch(
          id: 'assign-1',
          name: 'Main Branch',
          role: 'admin',
          active: true,
          branchId: 'branch-1',
        ),
      ],
    );

    final repository = _StubAuthRepository(
      onLogin: (_, __) async => initial,
      onListBranchContexts: ({required currentSession}) async =>
          const AuthBranchContextOptions(
            state: 'BRANCH_SELECTION_REQUIRED',
            tenantId: 'tenant-1',
            selectedBranchId: null,
            branches: [
              AuthBranchContextOption(
                branchId: 'branch-1',
                branchName: 'Main Branch',
              ),
            ],
          ),
      onSelectBranch:
          ({
            required currentSession,
            required branchId,
            bool verifyCurrentBranchProfile = true,
          }) async => selected,
    );

    final container = createTestContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        authSessionStoreProvider.overrideWithValue(store),
        initialAuthSessionProvider.overrideWithValue(null),
      ],
    );

    await container.read(loginControllerProvider.notifier).login('+8551', 'pw');
    await container
        .read(loginControllerProvider.notifier)
        .selectBranch('branch-1');
    final state = container.read(loginControllerProvider);

    expect(state.requiresBranchSelection, isFalse);
    expect(state.branchOptions, isEmpty);
    expect(state.session, isNotNull);
    expect(state.session!.accessToken, 'access-2');
  });

  test(
    'selectTenant returns true and persists only after tenant context verification succeeds',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AuthSessionStore(prefs);

      final initial = _tenantSelectionSession();
      final selectedSession = initial.copyWith(
        user: initial.user.copyWith(id: '', name: 'User', phone: ''),
        activeTenantId: 'tenant-2',
        accessToken: 'access-tenant-2',
        refreshToken: 'refresh-tenant-2',
        tenantSelectionToken: '',
      );

      var capturedTenantProfileToken = '';
      final repository = _StubAuthRepository(
        onSelectTenant:
            ({
              required selectionToken,
              required tenantId,
              String? branchId,
            }) async {
              expect(selectionToken, 'selection-token-123');
              expect(tenantId, 'tenant-2');
              return selectedSession;
            },
        onListBranchContexts: ({required currentSession}) async =>
            const AuthBranchContextOptions(
              state: 'BRANCH_SELECTION_REQUIRED',
              tenantId: 'tenant-2',
              selectedBranchId: null,
              branches: [
                AuthBranchContextOption(
                  branchId: 'branch-2',
                  branchName: 'Branch Two',
                ),
              ],
            ),
      );
      final tenantRepository = _StubTenantRepository(
        onGetCurrentTenantProfile: ({String? accessTokenOverride}) async {
          capturedTenantProfileToken = accessTokenOverride ?? '';
          return const TenantProfile(
            tenantId: 'tenant-2',
            tenantName: 'Tenant 2',
            tenantAddress: null,
            contactNumber: null,
            logoUrl: null,
            status: 'ACTIVE',
          );
        },
      );

      final container = createTestContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          tenantRepositoryProvider.overrideWithValue(tenantRepository),
          authSessionStoreProvider.overrideWithValue(store),
          initialAuthSessionProvider.overrideWithValue(initial),
        ],
      );

      final success = await container
          .read(loginControllerProvider.notifier)
          .selectTenant('tenant-2');
      final state = container.read(loginControllerProvider);
      final persisted = await store.load();

      expect(success, isTrue);
      expect(state.session, isNotNull);
      expect(state.session!.activeTenantId, 'tenant-2');
      expect(state.session!.accessToken, 'access-tenant-2');
      expect(state.session!.user.id, 'user-1');
      expect(state.session!.user.name, 'Tester');
      expect(state.session!.user.phone, '+8551');
      expect(state.requiresBranchSelection, isTrue);
      expect(state.branchOptions, hasLength(1));
      expect(capturedTenantProfileToken, 'access-tenant-2');
      expect(persisted, isNotNull);
      expect(persisted!.activeTenantId, 'tenant-2');
      expect(persisted.accessToken, 'access-tenant-2');
      expect(persisted.user.id, 'user-1');
      expect(persisted.user.name, 'Tester');
      expect(persisted.user.phone, '+8551');
    },
  );

  test(
    'selectTenant returns false and keeps previous session when tenant context verification fails',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AuthSessionStore(prefs);

      final initial = _tenantSelectionSession();
      final selectedSession = initial.copyWith(
        activeTenantId: 'tenant-2',
        accessToken: 'access-tenant-2',
        refreshToken: 'refresh-tenant-2',
        tenantSelectionToken: '',
      );

      final repository = _StubAuthRepository(
        onSelectTenant:
            ({
              required selectionToken,
              required tenantId,
              String? branchId,
            }) async {
              return selectedSession;
            },
      );
      final tenantRepository = _StubTenantRepository(
        onGetCurrentTenantProfile: ({String? accessTokenOverride}) async {
          throw const ApiClientException(
            message: 'TENANT_CONTEXT_REQUIRED',
            code: 'TENANT_CONTEXT_REQUIRED',
            statusCode: 403,
          );
        },
      );

      final container = createTestContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          tenantRepositoryProvider.overrideWithValue(tenantRepository),
          authSessionStoreProvider.overrideWithValue(store),
          initialAuthSessionProvider.overrideWithValue(initial),
        ],
      );

      final success = await container
          .read(loginControllerProvider.notifier)
          .selectTenant('tenant-2');
      final state = container.read(loginControllerProvider);
      final persisted = await store.load();

      expect(success, isFalse);
      expect(state.errorCode, 'TENANT_CONTEXT_REQUIRED');
      expect(state.errorStatusCode, 403);
      expect(state.session, isNotNull);
      expect(state.session!.activeTenantId, isNull);
      expect(state.session!.tenantSelectionToken, 'selection-token-123');
      expect(persisted, isNull);
    },
  );

  test(
    'selectTenant returns false when tenant/current does not match selected tenant',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AuthSessionStore(prefs);

      final initial = _tenantSelectionSession();
      final selectedSession = initial.copyWith(
        memberships: const [
          TenantMembership(
            membershipId: 'm-2',
            tenantId: 'tenant-2',
            tenantName: 'Tenant 2',
            role: 'ADMIN',
            branches: [],
          ),
        ],
        activeTenantId: 'tenant-2',
        accessToken: 'access-tenant-2',
        refreshToken: 'refresh-tenant-2',
        tenantSelectionToken: '',
      );

      final repository = _StubAuthRepository(
        onSelectTenant:
            ({
              required selectionToken,
              required tenantId,
              String? branchId,
            }) async {
              return selectedSession;
            },
      );
      final tenantRepository = _StubTenantRepository(
        onGetCurrentTenantProfile: ({String? accessTokenOverride}) async =>
            const TenantProfile(
              tenantId: 'tenant-1',
              tenantName: 'Tenant 1',
              tenantAddress: null,
              contactNumber: null,
              logoUrl: null,
              status: 'ACTIVE',
            ),
      );

      final container = createTestContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          tenantRepositoryProvider.overrideWithValue(tenantRepository),
          authSessionStoreProvider.overrideWithValue(store),
          initialAuthSessionProvider.overrideWithValue(initial),
        ],
      );

      final success = await container
          .read(loginControllerProvider.notifier)
          .selectTenant('tenant-2');
      final state = container.read(loginControllerProvider);
      final persisted = await store.load();

      expect(success, isFalse);
      expect(state.errorCode, 'TENANT_CONTEXT_MISMATCH');
      expect(state.errorStatusCode, 409);
      expect(state.session, isNotNull);
      expect(state.session!.activeTenantId, isNull);
      expect(state.session!.tenantSelectionToken, 'selection-token-123');
      expect(persisted, isNull);
    },
  );

  test(
    'selectTenant prefers selected memberships and derives role from selected tenant membership',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AuthSessionStore(prefs);

      final initial = _tenantSelectionSession();
      final selectedSession = initial.copyWith(
        memberships: const [
          TenantMembership(
            membershipId: 'm-2-updated',
            tenantId: 'tenant-2',
            tenantName: 'Tenant 2',
            role: 'ADMIN',
            branches: [],
          ),
        ],
        activeTenantId: 'tenant-2',
        accessToken: 'access-tenant-2',
        refreshToken: 'refresh-tenant-2',
        tenantSelectionToken: '',
      );

      final repository = _StubAuthRepository(
        onSelectTenant:
            ({
              required selectionToken,
              required tenantId,
              String? branchId,
            }) async {
              return selectedSession;
            },
        onListBranchContexts: ({required currentSession}) async =>
            const AuthBranchContextOptions(
              state: 'BRANCH_SELECTION_REQUIRED',
              tenantId: 'tenant-2',
              selectedBranchId: null,
              branches: [
                AuthBranchContextOption(
                  branchId: 'branch-2',
                  branchName: 'Branch Two',
                ),
              ],
            ),
      );
      final tenantRepository = _StubTenantRepository(
        onGetCurrentTenantProfile: ({String? accessTokenOverride}) async =>
            const TenantProfile(
              tenantId: 'tenant-2',
              tenantName: 'Tenant 2',
              tenantAddress: null,
              contactNumber: null,
              logoUrl: null,
              status: 'ACTIVE',
            ),
      );

      final container = createTestContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          tenantRepositoryProvider.overrideWithValue(tenantRepository),
          authSessionStoreProvider.overrideWithValue(store),
          initialAuthSessionProvider.overrideWithValue(initial),
        ],
      );

      final success = await container
          .read(loginControllerProvider.notifier)
          .selectTenant('tenant-2');
      final state = container.read(loginControllerProvider);

      expect(success, isTrue);
      expect(state.session, isNotNull);
      expect(state.session!.user.tenantId, 'tenant-2');
      expect(state.session!.user.role, 'ADMIN');
      expect(state.session!.memberships, hasLength(1));
      expect(state.session!.memberships.first.membershipId, 'm-2-updated');
      expect(state.session!.memberships.first.role, 'ADMIN');
    },
  );

  test(
    'selectTenant falls back to branch selection when branch context listing returns recoverable tenant-context error',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AuthSessionStore(prefs);

      final initial = _tenantSelectionSession();
      final selectedSession = initial.copyWith(
        activeTenantId: 'tenant-2',
        accessToken: 'access-tenant-2',
        refreshToken: 'refresh-tenant-2',
        tenantSelectionToken: '',
      );

      final repository = _StubAuthRepository(
        onSelectTenant:
            ({
              required selectionToken,
              required tenantId,
              String? branchId,
            }) async => selectedSession,
        onListBranchContexts: ({required currentSession}) async {
          throw const ApiClientException(
            message: 'TENANT_CONTEXT_REQUIRED',
            code: 'TENANT_CONTEXT_REQUIRED',
            statusCode: 403,
          );
        },
      );
      final tenantRepository = _StubTenantRepository(
        onGetCurrentTenantProfile: ({String? accessTokenOverride}) async =>
            const TenantProfile(
              tenantId: 'tenant-2',
              tenantName: 'Tenant 2',
              tenantAddress: null,
              contactNumber: null,
              logoUrl: null,
              status: 'ACTIVE',
            ),
      );

      final container = createTestContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          tenantRepositoryProvider.overrideWithValue(tenantRepository),
          authSessionStoreProvider.overrideWithValue(store),
          initialAuthSessionProvider.overrideWithValue(initial),
        ],
      );

      final success = await container
          .read(loginControllerProvider.notifier)
          .selectTenant('tenant-2');
      final state = container.read(loginControllerProvider);
      final persisted = await store.load();

      expect(success, isTrue);
      expect(state.error, isNull);
      expect(state.errorCode, isNull);
      expect(state.requiresBranchSelection, isTrue);
      expect(state.branchOptions, isEmpty);
      expect(state.session, isNotNull);
      expect(state.session!.activeTenantId, 'tenant-2');
      expect(state.session!.accessToken, 'access-tenant-2');
      expect(persisted, isNotNull);
      expect(persisted!.activeTenantId, 'tenant-2');
      expect(persisted.accessToken, 'access-tenant-2');
    },
  );

  test(
    'selectTenant does not auto-select branch when backend reports BRANCH_SELECTED without local active branch context',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AuthSessionStore(prefs);

      final initial = _tenantSelectionSession();
      final selectedSession = initial.copyWith(
        activeTenantId: 'tenant-2',
        accessToken: 'access-tenant-2',
        refreshToken: 'refresh-tenant-2',
        tenantSelectionToken: '',
      );
      var autoSelectBranchCalled = false;

      final repository = _StubAuthRepository(
        onSelectTenant:
            ({
              required selectionToken,
              required tenantId,
              String? branchId,
            }) async => selectedSession,
        onListBranchContexts: ({required currentSession}) async =>
            const AuthBranchContextOptions(
              state: 'BRANCH_SELECTED',
              tenantId: 'tenant-2',
              selectedBranchId: 'branch-2',
              branches: [
                AuthBranchContextOption(
                  branchId: 'branch-2',
                  branchName: 'Branch Two',
                ),
              ],
            ),
        onSelectBranch:
            ({
              required currentSession,
              required branchId,
              bool verifyCurrentBranchProfile = true,
            }) async {
              autoSelectBranchCalled = true;
              return selectedSession;
            },
      );
      final tenantRepository = _StubTenantRepository(
        onGetCurrentTenantProfile: ({String? accessTokenOverride}) async =>
            const TenantProfile(
              tenantId: 'tenant-2',
              tenantName: 'Tenant 2',
              tenantAddress: null,
              contactNumber: null,
              logoUrl: null,
              status: 'ACTIVE',
            ),
      );

      final container = createTestContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          tenantRepositoryProvider.overrideWithValue(tenantRepository),
          authSessionStoreProvider.overrideWithValue(store),
          initialAuthSessionProvider.overrideWithValue(initial),
        ],
      );

      final success = await container
          .read(loginControllerProvider.notifier)
          .selectTenant('tenant-2');
      final state = container.read(loginControllerProvider);

      expect(success, isTrue);
      expect(autoSelectBranchCalled, isFalse);
      expect(state.requiresBranchSelection, isTrue);
      expect(state.branchOptions, hasLength(1));
      expect(state.branchOptions.first.branchId, 'branch-2');
    },
  );

  test(
    'sendRegistrationOtp stores backend code and status on rate limit',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AuthSessionStore(prefs);
      final repository = _StubAuthRepository(
        onSendRegistrationOtp: ({required phone}) async {
          throw const ApiClientException(
            message: 'Too many OTP requests',
            code: 'OTP_RATE_LIMIT',
            statusCode: 429,
          );
        },
      );

      final container = createTestContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          authSessionStoreProvider.overrideWithValue(store),
          initialAuthSessionProvider.overrideWithValue(null),
        ],
      );

      await container
          .read(loginControllerProvider.notifier)
          .sendRegistrationOtp(phone: '+8551');
      final state = container.read(loginControllerProvider);

      expect(state.errorCode, 'OTP_RATE_LIMIT');
      expect(state.errorStatusCode, 429);
      expect(state.error, 'Too many OTP requests');
    },
  );

  test(
    'refreshSessionForNetwork rotates token without loading state changes',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AuthSessionStore(prefs);
      final initial = _session(
        accessToken: 'access-1',
        branches: const [
          UserBranch(
            id: 'assign-1',
            name: 'Main Branch',
            role: 'admin',
            active: true,
            branchId: 'branch-1',
          ),
        ],
      );
      final refreshed = _session(
        accessToken: 'access-2',
        branches: const [
          UserBranch(
            id: 'assign-1',
            name: 'Main Branch',
            role: 'admin',
            active: true,
            branchId: 'branch-1',
          ),
        ],
      );
      final repository = _StubAuthRepository(
        onLogin: (_, __) async => initial,
        onListBranchContexts: ({required currentSession}) async =>
            const AuthBranchContextOptions(
              state: 'BRANCH_SELECTED',
              tenantId: 'tenant-1',
              selectedBranchId: 'branch-1',
              branches: [
                AuthBranchContextOption(
                  branchId: 'branch-1',
                  branchName: 'Main Branch',
                ),
              ],
            ),
        onRefreshSession: ({required currentSession}) async => refreshed,
      );

      final container = createTestContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          authSessionStoreProvider.overrideWithValue(store),
          initialAuthSessionProvider.overrideWithValue(null),
        ],
      );

      await container
          .read(loginControllerProvider.notifier)
          .login('+8551', 'pw');
      final before = container.read(loginControllerProvider);
      expect(before.isLoading, isFalse);
      expect(before.session?.accessToken, 'access-1');

      final result = await container
          .read(loginControllerProvider.notifier)
          .refreshSessionForNetwork();

      final after = container.read(loginControllerProvider);
      expect(result, isNotNull);
      expect(after.isLoading, isFalse);
      expect(after.session?.accessToken, 'access-2');
    },
  );

  test('refreshSessionForNetwork clears session when refresh fails', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AuthSessionStore(prefs);
    final initial = _session(
      accessToken: 'access-1',
      branches: const [
        UserBranch(
          id: 'assign-1',
          name: 'Main Branch',
          role: 'admin',
          active: true,
          branchId: 'branch-1',
        ),
      ],
    );
    final repository = _StubAuthRepository(
      onLogin: (_, __) async => initial,
      onListBranchContexts: ({required currentSession}) async =>
          const AuthBranchContextOptions(
            state: 'BRANCH_SELECTED',
            tenantId: 'tenant-1',
            selectedBranchId: 'branch-1',
            branches: [
              AuthBranchContextOption(
                branchId: 'branch-1',
                branchName: 'Main Branch',
              ),
            ],
          ),
      onRefreshSession: ({required currentSession}) async {
        throw const ApiClientException(
          message: 'refresh expired',
          code: 'AUTH_REFRESH_INVALID',
          statusCode: 401,
        );
      },
    );

    final container = createTestContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        authSessionStoreProvider.overrideWithValue(store),
        initialAuthSessionProvider.overrideWithValue(null),
      ],
    );

    await container.read(loginControllerProvider.notifier).login('+8551', 'pw');
    final result = await container
        .read(loginControllerProvider.notifier)
        .refreshSessionForNetwork();

    final after = container.read(loginControllerProvider);
    expect(result, isNull);
    expect(after.session, isNull);
  });

  test('login persists tenant-selection state for reload safety', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AuthSessionStore(prefs);

    final selectionSession = AuthSession(
      user: User(id: 'user-1', name: 'Tester', role: 'admin', tenantId: ''),
      memberships: const [
        TenantMembership(
          tenantId: 'tenant-1',
          tenantName: 'Tenant 1',
          role: 'admin',
          branches: [],
        ),
        TenantMembership(
          tenantId: 'tenant-2',
          tenantName: 'Tenant 2',
          role: 'admin',
          branches: [],
        ),
      ],
      activeTenantId: null,
      accessToken: 'access-selection',
      refreshToken: 'refresh-selection',
      accessTokenExpiresAt: DateTime.now().toUtc().add(
        const Duration(minutes: 15),
      ),
      refreshTokenExpiresAt: DateTime.now().toUtc().add(
        const Duration(hours: 72),
      ),
      tenantSelectionToken: 'selection-token-123',
    );

    final repository = _StubAuthRepository(
      onLogin: (_, __) async => selectionSession,
    );
    final container = createTestContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        authSessionStoreProvider.overrideWithValue(store),
        initialAuthSessionProvider.overrideWithValue(null),
      ],
    );

    await container.read(loginControllerProvider.notifier).login('+8551', 'pw');

    final loaded = await store.load();
    expect(loaded, isNotNull);
    expect(loaded!.requiresTenantSelection, isTrue);
    expect(loaded.tenantSelectionToken, 'selection-token-123');
    expect(loaded.accessToken, 'access-selection');
    expect(loaded.refreshToken, 'refresh-selection');
    expect(loaded.memberships, hasLength(2));
  });

  test(
    'login stores pending phone when backend returns phone-not-verified',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AuthSessionStore(prefs);
      final repository = _StubAuthRepository(
        onLogin: (_, __) async {
          throw const ApiClientException(
            message: 'phone not verified',
            code: 'AUTH_PHONE_NOT_VERIFIED',
            statusCode: 403,
          );
        },
      );
      final container = createTestContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          authSessionStoreProvider.overrideWithValue(store),
          initialAuthSessionProvider.overrideWithValue(null),
        ],
      );

      await container
          .read(loginControllerProvider.notifier)
          .login('+85512345678', 'pw');

      final state = container.read(loginControllerProvider);
      expect(state.pendingVerificationPhone, '+85512345678');
      expect(state.errorCode, 'AUTH_PHONE_NOT_VERIFIED');
      expect(state.errorStatusCode, 403);
    },
  );

  test('registerAccount exposes conflict code for existing account', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AuthSessionStore(prefs);
    final repository = _StubAuthRepository(
      onRegisterAccount:
          ({
            required phone,
            required password,
            required firstName,
            required lastName,
            String? gender,
            String? dateOfBirth,
          }) async {
            throw const ApiClientException(
              message: 'account already exists',
              code: 'ACCOUNT_ALREADY_EXISTS',
              statusCode: 409,
            );
          },
    );
    final container = createTestContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        authSessionStoreProvider.overrideWithValue(store),
        initialAuthSessionProvider.overrideWithValue(null),
      ],
    );

    await container
        .read(loginControllerProvider.notifier)
        .registerAccount(
          phone: '+85512345678',
          password: 'StrongPass123!',
          firstName: 'Test',
          lastName: 'User',
        );

    final state = container.read(loginControllerProvider);
    expect(state.errorCode, 'ACCOUNT_ALREADY_EXISTS');
    expect(state.errorStatusCode, 409);
  });

  test(
    'verifyRegistrationOtp marks invalid otp state when verify=false',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AuthSessionStore(prefs);
      final repository = _StubAuthRepository(
        onVerifyRegistrationOtp: ({required phone, required otp}) async =>
            const AuthVerifyOtpResult(verified: false),
      );
      final container = createTestContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          authSessionStoreProvider.overrideWithValue(store),
          initialAuthSessionProvider.overrideWithValue(null),
        ],
      );

      await container
          .read(loginControllerProvider.notifier)
          .verifyRegistrationOtp(phone: '+85512345678', otp: '000000');

      final state = container.read(loginControllerProvider);
      expect(state.errorCode, 'OTP_INVALID');
      expect(state.errorStatusCode, 400);
      expect(state.error, 'Invalid verification code.');
    },
  );

  test(
    'upsertSessionTenantMembership appends created tenant membership',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AuthSessionStore(prefs);
      final initial = _session(accessToken: 'access-1', branches: const []);
      final repository = _StubAuthRepository();
      final container = createTestContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          authSessionStoreProvider.overrideWithValue(store),
          initialAuthSessionProvider.overrideWithValue(initial),
        ],
      );

      await container
          .read(loginControllerProvider.notifier)
          .upsertSessionTenantMembership(
            tenantId: 'tenant-2',
            tenantName: 'Tenant 2',
            role: 'OWNER',
          );

      final state = container.read(loginControllerProvider);
      expect(state.session, isNotNull);
      expect(state.session!.memberships, hasLength(2));
      expect(
        state.session!.memberships.any(
          (membership) => membership.tenantId == 'tenant-2',
        ),
        isTrue,
      );

      final persisted = await store.load();
      expect(persisted, isNotNull);
      expect(persisted!.memberships, hasLength(2));
    },
  );

  test(
    'upsertSessionTenantMembership updates existing tenant membership',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = AuthSessionStore(prefs);
      final initial = _session(accessToken: 'access-1', branches: const []);
      final repository = _StubAuthRepository();
      final container = createTestContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          authSessionStoreProvider.overrideWithValue(store),
          initialAuthSessionProvider.overrideWithValue(initial),
        ],
      );

      await container
          .read(loginControllerProvider.notifier)
          .upsertSessionTenantMembership(
            tenantId: 'tenant-1',
            tenantName: 'Tenant 1 Updated',
            role: 'OWNER',
          );

      final state = container.read(loginControllerProvider);
      expect(state.session, isNotNull);
      expect(state.session!.memberships, hasLength(1));
      expect(state.session!.memberships.first.tenantName, 'Tenant 1 Updated');
      expect(state.session!.memberships.first.role, 'OWNER');
    },
  );
}
