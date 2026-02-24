import 'dart:math';

import 'package:modular_pos/features/auth/data/auth_repository.dart';
import 'package:modular_pos/features/auth/data/auth_repository_session_utils.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository();

  final Set<String> _verifiedPhones = <String>{};
  final Map<String, String> _lastOtpByPhone = <String, String>{};

  @override
  Future<AuthRegisterAccountResult> registerAccount({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    String? gender,
    String? dateOfBirth,
  }) async {
    final normalizedPhone = phone.trim();
    final existed = _verifiedPhones.contains(normalizedPhone);
    return AuthRegisterAccountResult(
      accountId: 'mock-account-$normalizedPhone',
      phone: normalizedPhone,
      phoneVerified: existed,
      completedExistingInviteAccount: existed,
    );
  }

  @override
  Future<AuthSendOtpResult> sendRegistrationOtp({required String phone}) async {
    _lastOtpByPhone[phone.trim()] = '123456';
    return const AuthSendOtpResult(expiresInMinutes: 10);
  }

  @override
  Future<AuthVerifyOtpResult> verifyRegistrationOtp({
    required String phone,
    required String otp,
  }) async {
    final normalizedPhone = phone.trim();
    final expected = _lastOtpByPhone[normalizedPhone] ?? '123456';
    final verified = otp.trim() == expected;
    if (verified) _verifiedPhones.add(normalizedPhone);
    return AuthVerifyOtpResult(verified: verified);
  }

  @override
  Future<AuthSession> login(String username, String password) async {
    final isMultiTenant = username.trim().toLowerCase().contains('multi');
    if (isMultiTenant) {
      return AuthSession(
        user: User(
          id: 'mock-user',
          name: 'Mock User',
          role: 'ADMIN',
          tenantId: '',
        ),
        memberships: _mockMemberships(),
        activeTenantId: null,
        accessToken: '',
        refreshToken: '',
        accessTokenExpiresAt: DateTime.now().toUtc().add(
          const Duration(minutes: 15),
        ),
        refreshTokenExpiresAt: DateTime.now().toUtc().add(
          const Duration(hours: 72),
        ),
        tenantSelectionToken: 'mock-selection-token',
      );
    }

    return _mockEstablishedSession(tenantId: 'mock-tenant-1');
  }

  @override
  Future<AuthSession> selectTenant({
    required String selectionToken,
    required String tenantId,
    String? branchId,
  }) async {
    final effectiveBranchId = branchId ?? 'mock-branch-1';
    return _mockEstablishedSession(
      tenantId: tenantId,
      branchId: effectiveBranchId,
    );
  }

  @override
  Future<AuthBranchContextOptions> listBranchContexts({
    required AuthSession currentSession,
  }) async {
    final tenantId =
        currentSession.activeTenantId ?? currentSession.user.tenantId;
    final membership = currentSession.memberships.firstWhere(
      (m) => m.tenantId == tenantId,
      orElse: () => currentSession.memberships.isNotEmpty
          ? currentSession.memberships.first
          : const TenantMembership(
              tenantId: '',
              tenantName: '',
              role: '',
              branches: <UserBranch>[],
            ),
    );
    final branches = membership.branches
        .map(
          (b) => AuthBranchContextOption(
            branchId: b.branchId.isNotEmpty ? b.branchId : b.id,
            branchName: b.name,
          ),
        )
        .where((b) => b.branchId.trim().isNotEmpty)
        .toList(growable: false);

    if (branches.isEmpty) {
      return AuthBranchContextOptions(
        state: 'NO_BRANCH_ASSIGNED',
        tenantId: tenantId,
        selectedBranchId: null,
        branches: const <AuthBranchContextOption>[],
      );
    }

    final selectedBranchId = currentBranchId(currentSession);
    if (selectedBranchId != null && selectedBranchId.isNotEmpty) {
      return AuthBranchContextOptions(
        state: 'BRANCH_SELECTED',
        tenantId: tenantId,
        selectedBranchId: selectedBranchId,
        branches: branches,
      );
    }

    if (branches.length == 1) {
      return AuthBranchContextOptions(
        state: 'BRANCH_AUTO_SELECTED',
        tenantId: tenantId,
        selectedBranchId: branches.first.branchId,
        branches: branches,
      );
    }

    return AuthBranchContextOptions(
      state: 'BRANCH_SELECTION_REQUIRED',
      tenantId: tenantId,
      selectedBranchId: null,
      branches: branches,
    );
  }

  @override
  Future<AuthSession> selectBranch({
    required AuthSession currentSession,
    required String branchId,
  }) async {
    return updateSessionTokensAndContext(
      currentSession,
      accessToken: _mockToken('access'),
      refreshToken: _mockToken('refresh'),
      tenantId: currentSession.activeTenantId ?? currentSession.user.tenantId,
      branchId: branchId,
    );
  }

  @override
  Future<AuthSession> refreshSession({
    required AuthSession currentSession,
  }) async {
    return updateSessionTokensAndContext(
      currentSession,
      accessToken: _mockToken('access'),
      refreshToken: _mockToken('refresh'),
      tenantId: currentSession.activeTenantId ?? currentSession.user.tenantId,
      branchId: currentBranchId(currentSession),
    );
  }

  @override
  Future<void> logout({String? refreshToken}) async {}

  AuthSession _mockEstablishedSession({
    required String tenantId,
    String branchId = 'mock-branch-1',
  }) {
    final memberships = _mockMemberships();
    final tenantMembership = memberships.firstWhere(
      (m) => m.tenantId == tenantId,
      orElse: () => memberships.first,
    );
    final branches = activateBranchForUser(tenantMembership.branches, branchId);
    final role = tenantMembership.role.isEmpty
        ? 'ADMIN'
        : tenantMembership.role;

    return AuthSession(
      user: User(
        id: 'mock-user',
        name: 'Mock User',
        role: role,
        tenantId: tenantId,
        phone: '+10000000001',
        status: 'ACTIVE',
        branches: branches,
      ),
      memberships: memberships,
      activeTenantId: tenantId,
      accessToken: _mockToken('access'),
      refreshToken: _mockToken('refresh'),
      accessTokenExpiresAt: DateTime.now().toUtc().add(
        const Duration(minutes: 15),
      ),
      refreshTokenExpiresAt: DateTime.now().toUtc().add(
        const Duration(hours: 72),
      ),
      tenantSelectionToken: '',
    );
  }

  List<TenantMembership> _mockMemberships() {
    return const [
      TenantMembership(
        tenantId: 'mock-tenant-1',
        tenantName: 'Mock Tenant 1',
        role: 'ADMIN',
        branches: [
          UserBranch(
            id: 'mock-assign-1',
            name: 'Mock Branch 1',
            role: 'ADMIN',
            active: true,
            employeeId: 'mock-user',
            branchId: 'mock-branch-1',
          ),
        ],
      ),
      TenantMembership(
        tenantId: 'mock-tenant-2',
        tenantName: 'Mock Tenant 2',
        role: 'ADMIN',
        branches: [
          UserBranch(
            id: 'mock-assign-2',
            name: 'Mock Branch 2',
            role: 'ADMIN',
            active: true,
            employeeId: 'mock-user',
            branchId: 'mock-branch-2',
          ),
        ],
      ),
    ];
  }

  String _mockToken(String prefix) {
    final random = Random.secure().nextInt(1 << 32);
    return 'mock-$prefix-$random';
  }
}
