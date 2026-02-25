import 'package:modular_pos/features/auth/data/auth_api.dart';
import 'package:modular_pos/features/auth/data/auth_repository.dart';
import 'package:modular_pos/features/auth/data/auth_repository_session_utils.dart';
import 'package:modular_pos/features/auth/data/dto/auth_context_dto.dart';
import 'package:modular_pos/features/auth/data/dto/auth_login_response_dto.dart';
import 'package:modular_pos/features/auth/data/dto/auth_user_dto.dart';
import 'package:modular_pos/features/auth/data/dto/tenant_membership_dto.dart';
import 'package:modular_pos/features/auth/data/dto/user_branch_dto.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(this._api);

  final AuthApi _api;

  @override
  Future<AuthRegisterAccountResult> registerAccount({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    String? gender,
    String? dateOfBirth,
  }) async {
    final result = await _api.registerAccount(
      phone: phone,
      password: password,
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      dateOfBirth: dateOfBirth,
    );
    return AuthRegisterAccountResult(
      accountId: result.accountId,
      phone: result.phone,
      phoneVerified: result.phoneVerified,
      completedExistingInviteAccount: result.completedExistingInviteAccount,
    );
  }

  @override
  Future<AuthSendOtpResult> sendRegistrationOtp({required String phone}) async {
    final result = await _api.sendRegistrationOtp(phone: phone);
    return AuthSendOtpResult(expiresInMinutes: result.expiresInMinutes);
  }

  @override
  Future<AuthVerifyOtpResult> verifyRegistrationOtp({
    required String phone,
    required String otp,
  }) async {
    final result = await _api.verifyRegistrationOtp(phone: phone, otp: otp);
    return AuthVerifyOtpResult(verified: result.verified);
  }

  @override
  Future<AuthSession> login(String username, String password) async {
    final response = await _api.login(username: username, password: password);
    if (response.requiresTenantSelection) {
      final selection = response.tenantSelection!;
      final fallbackName = username.trim().isEmpty ? 'User' : username.trim();
      return AuthSession(
        user: selection.user != null
            ? _toUser(selection.user!)
            : User(
                id: '',
                name: fallbackName,
                role: '',
                tenantId: '',
                phone: username.trim(),
                status: 'ACTIVE',
              ),
        memberships: selection.memberships
            .map(_toMembership)
            .toList(growable: false),
        activeTenantId: null,
        accessToken: selection.accessToken ?? '',
        refreshToken: selection.refreshToken ?? '',
        accessTokenExpiresAt:
            selection.accessTokenExpiresAt ??
            DateTime.now().toUtc().add(const Duration(minutes: 15)),
        refreshTokenExpiresAt:
            selection.refreshTokenExpiresAt ??
            DateTime.now().toUtc().add(const Duration(hours: 72)),
        tenantSelectionToken: selection.selectionToken,
      );
    }
    final established = response.established!;
    return _toAuthSession(established);
  }

  @override
  Future<AuthSession> selectTenant({
    required String selectionToken,
    required String tenantId,
    String? branchId,
  }) async {
    final selected = await _api.selectTenant(
      selectionToken: selectionToken,
      tenantId: tenantId,
      branchId: branchId,
    );
    return _toAuthSession(selected);
  }

  @override
  Future<AuthBranchContextOptions> listBranchContexts({
    required AuthSession currentSession,
  }) async {
    final options = await _api.listBranchContexts(
      accessTokenOverride: currentSession.accessToken,
    );
    return _toBranchContextOptions(options);
  }

  @override
  Future<AuthSession> selectBranch({
    required AuthSession currentSession,
    required String branchId,
  }) async {
    final selected = await _api.selectBranchContext(branchId: branchId);
    final currentBranch = await _api.getCurrentBranchProfile(
      accessTokenOverride: selected.accessToken,
    );

    final tenantId = currentBranch.tenantId.trim().isNotEmpty
        ? currentBranch.tenantId.trim()
        : (selected.tenantId?.trim().isNotEmpty == true
              ? selected.tenantId!.trim()
              : (currentSession.activeTenantId ?? currentSession.user.tenantId));
    final resolvedBranchId = currentBranch.branchId.trim().isNotEmpty
        ? currentBranch.branchId.trim()
        : (selected.branchId?.trim().isNotEmpty == true
              ? selected.branchId!.trim()
              : branchId);

    return updateSessionTokensAndContext(
      currentSession,
      accessToken: selected.accessToken,
      refreshToken: selected.refreshToken,
      tenantId: tenantId,
      branchId: resolvedBranchId,
    );
  }

  @override
  Future<AuthSession> refreshSession({
    required AuthSession currentSession,
  }) async {
    final selected = await _api.refreshSession(
      refreshToken: currentSession.refreshToken,
    );
    final tenantId = selected.tenantId?.trim().isNotEmpty == true
        ? selected.tenantId!.trim()
        : (currentSession.activeTenantId ?? currentSession.user.tenantId);
    final branchId = selected.branchId?.trim().isNotEmpty == true
        ? selected.branchId!.trim()
        : currentBranchId(currentSession);

    return updateSessionTokensAndContext(
      currentSession,
      accessToken: selected.accessToken,
      refreshToken: selected.refreshToken,
      tenantId: tenantId,
      branchId: branchId,
    );
  }

  @override
  Future<void> logout({String? refreshToken}) async {
    final token = (refreshToken ?? '').trim();
    if (token.isEmpty) return;
    await _api.logout(refreshToken: token);
  }
}

AuthSession _toAuthSession(EstablishedAuthSessionDto dto) {
  return AuthSession(
    user: _toUser(dto.user),
    memberships: dto.memberships.map(_toMembership).toList(growable: false),
    activeTenantId: dto.activeTenantId,
    accessToken: dto.accessToken,
    refreshToken: dto.refreshToken,
    accessTokenExpiresAt: dto.accessTokenExpiresAt.toUtc(),
    refreshTokenExpiresAt: dto.refreshTokenExpiresAt.toUtc(),
    tenantSelectionToken: '',
  );
}

User _toUser(AuthUserDto dto) {
  return User(
    id: dto.id,
    name: dto.name,
    role: dto.role,
    tenantId: dto.tenantId,
    phone: dto.phone,
    status: dto.status,
    branches: dto.branches.map(_toBranch).toList(growable: false),
  );
}

TenantMembership _toMembership(TenantMembershipDto dto) {
  return TenantMembership(
    membershipId: dto.membershipId,
    tenantId: dto.tenantId,
    tenantName: dto.tenantName,
    role: dto.role,
    branches: dto.branches.map(_toBranch).toList(growable: false),
  );
}

UserBranch _toBranch(UserBranchDto dto) {
  return UserBranch(
    id: dto.id,
    name: dto.name,
    role: dto.role,
    active: dto.active,
    employeeId: dto.employeeId,
    branchId: dto.branchId,
  );
}

AuthBranchContextOptions _toBranchContextOptions(
  AuthBranchContextOptionsDto dto,
) {
  return AuthBranchContextOptions(
    state: dto.state,
    tenantId: dto.tenantId,
    selectedBranchId: dto.selectedBranchId,
    branches: dto.branches
        .map(
          (branch) => AuthBranchContextOption(
            branchId: branch.branchId,
            branchName: branch.branchName,
          ),
        )
        .where((branch) => branch.branchId.trim().isNotEmpty)
        .toList(growable: false),
  );
}
