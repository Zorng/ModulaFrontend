import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/data/auth_api.dart';
import 'package:modular_pos/features/auth/data/dto/auth_login_response_dto.dart';
import 'package:modular_pos/features/auth/data/dto/tenant_membership_dto.dart';
import 'package:modular_pos/features/auth/data/dto/user_branch_dto.dart';
import 'package:modular_pos/features/auth/data/dto/auth_user_dto.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.read(authApiProvider);
  return RemoteAuthRepository(api);
});

abstract class AuthRepository {
  Future<AuthSession> login(String username, String password);
  Future<AuthSession> selectTenant({
    required String selectionToken,
    required String tenantId,
    String? branchId,
  });
}

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(this._api);

  final AuthApi _api;

  @override
  Future<AuthSession> login(String username, String password) async {
    final response = await _api.login(username: username, password: password);
    if (response.requiresTenantSelection) {
      final selection = response.tenantSelection!;
      return AuthSession(
        user: User(id: '', name: '', role: '', tenantId: ''),
        memberships: selection.memberships.map(_toMembership).toList(growable: false),
        activeTenantId: null,
        accessToken: '',
        refreshToken: '',
        accessTokenExpiresAt: DateTime.now().add(const Duration(minutes: 15)),
        refreshTokenExpiresAt: DateTime.now().add(const Duration(hours: 72)),
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
  }) {
    return _api
        .selectTenant(
          selectionToken: selectionToken,
          tenantId: tenantId,
          branchId: branchId,
        )
        .then(_toAuthSession);
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
