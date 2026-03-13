class AuthTenantContextMembershipDto {
  const AuthTenantContextMembershipDto({
    required this.membershipId,
    required this.tenantId,
    required this.tenantName,
    required this.roleKey,
  });

  final String membershipId;
  final String tenantId;
  final String tenantName;
  final String roleKey;

  factory AuthTenantContextMembershipDto.fromJson(Map<String, dynamic> json) {
    return AuthTenantContextMembershipDto(
      membershipId: json['membershipId']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      tenantName: json['tenantName']?.toString() ?? '',
      roleKey: json['roleKey']?.toString() ?? '',
    );
  }
}

class AuthTenantContextOptionsDto {
  const AuthTenantContextOptionsDto({
    required this.state,
    required this.selectedTenantId,
    required this.memberships,
  });

  final String state;
  final String? selectedTenantId;
  final List<AuthTenantContextMembershipDto> memberships;

  bool get requiresSelection =>
      state == 'TENANT_SELECTION_REQUIRED' || state == 'NO_ACTIVE_MEMBERSHIPS';

  factory AuthTenantContextOptionsDto.fromJson(Map<String, dynamic> json) {
    final membershipsRaw = json['memberships'];
    final memberships = membershipsRaw is List
        ? membershipsRaw
              .whereType<Map>()
              .map(
                (item) => AuthTenantContextMembershipDto.fromJson(
                  item.map((k, v) => MapEntry(k.toString(), v)),
                ),
              )
              .toList(growable: false)
        : const <AuthTenantContextMembershipDto>[];

    final selectedTenantId = json['selectedTenantId']?.toString();
    return AuthTenantContextOptionsDto(
      state: json['state']?.toString() ?? '',
      selectedTenantId: (selectedTenantId == null || selectedTenantId.isEmpty)
          ? null
          : selectedTenantId,
      memberships: memberships,
    );
  }
}

class AuthBranchContextOptionDto {
  const AuthBranchContextOptionDto({
    required this.branchId,
    required this.branchName,
  });

  final String branchId;
  final String branchName;

  factory AuthBranchContextOptionDto.fromJson(Map<String, dynamic> json) {
    return AuthBranchContextOptionDto(
      branchId: json['branchId']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
    );
  }
}

class AuthBranchContextOptionsDto {
  const AuthBranchContextOptionsDto({
    required this.state,
    required this.tenantId,
    required this.selectedBranchId,
    required this.branches,
  });

  final String state;
  final String? tenantId;
  final String? selectedBranchId;
  final List<AuthBranchContextOptionDto> branches;

  bool get requiresSelection =>
      state == 'BRANCH_SELECTION_REQUIRED' || state == 'NO_BRANCH_ASSIGNED';

  factory AuthBranchContextOptionsDto.fromJson(Map<String, dynamic> json) {
    final branchesRaw = json['branches'];
    final branches = branchesRaw is List
        ? branchesRaw
              .whereType<Map>()
              .map(
                (item) => AuthBranchContextOptionDto.fromJson(
                  item.map((k, v) => MapEntry(k.toString(), v)),
                ),
              )
              .toList(growable: false)
        : const <AuthBranchContextOptionDto>[];

    final tenantId = json['tenantId']?.toString();
    final selectedBranchId = json['selectedBranchId']?.toString();
    return AuthBranchContextOptionsDto(
      state: json['state']?.toString() ?? '',
      tenantId: (tenantId == null || tenantId.isEmpty) ? null : tenantId,
      selectedBranchId: (selectedBranchId == null || selectedBranchId.isEmpty)
          ? null
          : selectedBranchId,
      branches: branches,
    );
  }
}

class AuthContextTokenResultDto {
  const AuthContextTokenResultDto({
    required this.accessToken,
    required this.refreshToken,
    required this.tenantId,
    required this.branchId,
  });

  final String accessToken;
  final String refreshToken;
  final String? tenantId;
  final String? branchId;

  factory AuthContextTokenResultDto.fromJson(Map<String, dynamic> json) {
    final context = json['context'];
    final contextMap = context is Map
        ? context.map((k, v) => MapEntry(k.toString(), v))
        : const <String, dynamic>{};

    final tenantId = contextMap['tenantId']?.toString();
    final branchId = contextMap['branchId']?.toString();

    return AuthContextTokenResultDto(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      tenantId: (tenantId == null || tenantId.isEmpty) ? null : tenantId,
      branchId: (branchId == null || branchId.isEmpty) ? null : branchId,
    );
  }
}

class AuthCurrentBranchProfileDto {
  const AuthCurrentBranchProfileDto({
    required this.branchId,
    required this.tenantId,
    required this.branchName,
    required this.status,
  });

  final String branchId;
  final String tenantId;
  final String branchName;
  final String status;

  factory AuthCurrentBranchProfileDto.fromJson(Map<String, dynamic> json) {
    return AuthCurrentBranchProfileDto(
      branchId: json['branchId']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}
