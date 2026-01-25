import 'package:modular_pos/features/auth/data/dto/user_branch_dto.dart';

class TenantMembershipDto {
  const TenantMembershipDto({
    required this.tenantId,
    required this.tenantName,
    required this.role,
    required this.branches,
  });

  final String tenantId;
  final String tenantName;
  final String role;
  final List<UserBranchDto> branches;

  factory TenantMembershipDto.fromJson(Map<String, dynamic> json) {
    final tenantObject = json['tenant'];
    final tenantId = json['tenantId']?.toString() ??
        json['tenant_id']?.toString() ??
        json['tenantUuid']?.toString() ??
        (tenantObject is Map
            ? tenantObject['id']?.toString() ??
                tenantObject['tenantId']?.toString() ??
                tenantObject['tenant_id']?.toString() ??
                tenantObject['uuid']?.toString()
            : null) ??
        '';

    final tenantName = json['tenantName']?.toString() ??
        json['tenant_name']?.toString() ??
        json['name']?.toString() ??
        (tenantObject is Map
            ? tenantObject['name']?.toString() ??
                tenantObject['tenantName']?.toString() ??
                tenantObject['businessName']?.toString()
            : null) ??
        tenantId;

    final branchesValue =
        json['branches'] ?? json['branchAssignments'] ?? json['branch_assignments'];
    final List<dynamic> branchesRaw;
    if (branchesValue is List<dynamic>) {
      branchesRaw = branchesValue;
    } else if (branchesValue is Map) {
      branchesRaw = [branchesValue];
    } else {
      branchesRaw = const <dynamic>[];
    }

    final branches = branchesRaw
        .whereType<Map>()
        .map((b) => UserBranchDto.fromJson(Map<String, dynamic>.from(b)))
        .toList(growable: false);

    return TenantMembershipDto(
      tenantId: tenantId,
      tenantName: tenantName,
      role: json['role']?.toString() ?? json['memberRole']?.toString() ?? '',
      branches: branches,
    );
  }
}

