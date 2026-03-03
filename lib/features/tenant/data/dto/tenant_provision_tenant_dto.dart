class TenantProvisionTenantDto {
  const TenantProvisionTenantDto({
    required this.id,
    required this.name,
    required this.status,
  });

  final String id;
  final String name;
  final String status;

  factory TenantProvisionTenantDto.fromJson(Map<String, dynamic> json) {
    return TenantProvisionTenantDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'status': status};
  }
}
