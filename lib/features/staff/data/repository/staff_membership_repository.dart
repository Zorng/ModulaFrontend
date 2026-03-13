import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/staff/data/api/staff_membership_api.dart';
import 'package:modular_pos/features/staff/domain/models/staff_membership_models.dart';

abstract class StaffMembershipRepository {
  Future<List<StaffMembershipSummary>> fetchMemberships({
    String status = 'ALL',
    String? search,
    int limit = 50,
    int offset = 0,
  });

  Future<StaffMembershipDetail> fetchMembershipDetail(String membershipId);
}

final staffMembershipRepositoryProvider = Provider<StaffMembershipRepository>((
  ref,
) {
  final api = ref.read(staffMembershipApiProvider);
  return RemoteStaffMembershipRepository(api);
});

class RemoteStaffMembershipRepository implements StaffMembershipRepository {
  const RemoteStaffMembershipRepository(this._api);

  final StaffMembershipApi _api;

  @override
  Future<List<StaffMembershipSummary>> fetchMemberships({
    String status = 'ALL',
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    final dtos = await _api.fetchMemberships(
      status: status,
      search: search,
      limit: limit,
      offset: offset,
    );
    return dtos.map(_toSummary).toList(growable: false);
  }

  @override
  Future<StaffMembershipDetail> fetchMembershipDetail(String membershipId) async {
    final dto = await _api.fetchMembershipDetail(membershipId);
    return _toDetail(dto);
  }

  StaffMembershipSummary _toSummary(dynamic dto) {
    return StaffMembershipSummary(
      membershipId: dto.membershipId,
      tenantId: dto.tenantId,
      accountId: dto.accountId,
      roleKey: dto.roleKey,
      membershipStatus: parseMembershipLifecycleStatus(dto.membershipStatus),
      phone: dto.phone,
      firstName: dto.firstName,
      lastName: dto.lastName,
      staffProfileStatus: dto.staffProfileStatus,
      invitedAt: dto.invitedAt,
      acceptedAt: dto.acceptedAt,
      rejectedAt: dto.rejectedAt,
      revokedAt: dto.revokedAt,
      pendingBranchIds: dto.pendingBranchIds,
      activeBranchIds: dto.activeBranchIds,
    );
  }

  StaffMembershipDetail _toDetail(dynamic dto) {
    return StaffMembershipDetail(
      membershipId: dto.membershipId,
      tenantId: dto.tenantId,
      accountId: dto.accountId,
      roleKey: dto.roleKey,
      membershipStatus: parseMembershipLifecycleStatus(dto.membershipStatus),
      phone: dto.phone,
      firstName: dto.firstName,
      lastName: dto.lastName,
      staffProfileStatus: dto.staffProfileStatus,
      invitedAt: dto.invitedAt,
      acceptedAt: dto.acceptedAt,
      rejectedAt: dto.rejectedAt,
      revokedAt: dto.revokedAt,
      pendingBranchIds: dto.pendingBranchIds,
      activeBranchIds: dto.activeBranchIds,
    );
  }
}
