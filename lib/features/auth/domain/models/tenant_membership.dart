import 'package:modular_pos/features/auth/domain/models/user.dart';

class TenantMembership {
  const TenantMembership({
    required this.tenantId,
    required this.tenantName,
    required this.role,
    required this.branches,
  });

  final String tenantId;
  final String tenantName;
  final String role;
  final List<UserBranch> branches;

  factory TenantMembership.fromJson(Map<String, dynamic> json) {
    final tenantObject = json['tenant'];
    final tenantId = json['tenantId']?.toString() ??
        json['tenant_id']?.toString() ??
        json['tenantUuid']?.toString() ??
        (tenantObject is Map<String, dynamic>
            ? tenantObject['id']?.toString() ??
                tenantObject['tenantId']?.toString() ??
                tenantObject['tenant_id']?.toString() ??
                tenantObject['uuid']?.toString()
            : null) ??
        '';

    final tenantName = json['tenantName']?.toString() ??
        json['tenant_name']?.toString() ??
        json['name']?.toString() ??
        (tenantObject is Map<String, dynamic>
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
    } else if (branchesValue is Map<String, dynamic>) {
      branchesRaw = [branchesValue];
    } else {
      branchesRaw = const <dynamic>[];
    }

    final branches = branchesRaw
        .whereType<Map<String, dynamic>>()
        .map(UserBranch.fromJson)
        .toList(growable: false);

    return TenantMembership(
      tenantId: tenantId,
      tenantName: tenantName,
      role: json['role']?.toString() ?? json['memberRole']?.toString() ?? '',
      branches: branches,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenantId': tenantId,
      'tenantName': tenantName,
      'role': role,
      'branches': branches.map((b) => b.toJson()).toList(growable: false),
    };
  }
}
