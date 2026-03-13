import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/staff/data/api/membership_command_api.dart';
import 'package:modular_pos/features/staff/domain/models/staff_membership_models.dart';

abstract class MembershipCommandRepository {
  Future<MembershipInviteResult> inviteMember({
    required String tenantId,
    required String phone,
    required String roleKey,
    String? intentId,
  });

  Future<MembershipRoleUpdateResult> changeRole({
    required String membershipId,
    required String roleKey,
    String? intentId,
  });

  Future<MembershipRevokeResult> revokeMembership({
    required String membershipId,
    String? intentId,
  });
}

final membershipCommandRepositoryProvider =
    Provider<MembershipCommandRepository>((ref) {
      final api = ref.read(membershipCommandApiProvider);
      return RemoteMembershipCommandRepository(api);
    });

class RemoteMembershipCommandRepository implements MembershipCommandRepository {
  const RemoteMembershipCommandRepository(this._api);

  final MembershipCommandApi _api;

  @override
  Future<MembershipInviteResult> inviteMember({
    required String tenantId,
    required String phone,
    required String roleKey,
    String? intentId,
  }) async {
    final dto = await _api.inviteMember(
      tenantId: tenantId,
      phone: phone,
      roleKey: roleKey,
      intentId: intentId,
    );
    return MembershipInviteResult(
      membershipId: dto.membershipId,
      tenantId: dto.tenantId,
      accountId: dto.accountId,
      phone: dto.phone,
      roleKey: dto.roleKey,
      status: parseMembershipLifecycleStatus(dto.status),
    );
  }

  @override
  Future<MembershipRoleUpdateResult> changeRole({
    required String membershipId,
    required String roleKey,
    String? intentId,
  }) async {
    final dto = await _api.changeRole(
      membershipId: membershipId,
      roleKey: roleKey,
      intentId: intentId,
    );
    return MembershipRoleUpdateResult(
      membershipId: dto.membershipId,
      tenantId: dto.tenantId,
      roleKey: dto.roleKey,
    );
  }

  @override
  Future<MembershipRevokeResult> revokeMembership({
    required String membershipId,
    String? intentId,
  }) async {
    final dto = await _api.revokeMembership(
      membershipId: membershipId,
      intentId: intentId,
    );
    return MembershipRevokeResult(
      membershipId: dto.membershipId,
      tenantId: dto.tenantId,
      status: parseMembershipLifecycleStatus(dto.status),
    );
  }
}
