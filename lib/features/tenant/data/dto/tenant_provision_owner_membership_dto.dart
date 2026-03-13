class TenantProvisionOwnerMembershipDto {
  const TenantProvisionOwnerMembershipDto({
    required this.id,
    required this.roleKey,
    required this.status,
  });

  final String id;
  final String roleKey;
  final String status;

  factory TenantProvisionOwnerMembershipDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return TenantProvisionOwnerMembershipDto(
      id: json['id']?.toString() ?? '',
      roleKey: json['roleKey']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'roleKey': roleKey, 'status': status};
  }
}
