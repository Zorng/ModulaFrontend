/// Branch DTO matching backend payload
class BranchDto {
  final String id;
  final String tenantId;
  final String name;
  final String status;
  final String? address;
  final String? contactPhone;
  final String? contactEmail;
  final String? managedBy;
  final String createdAt;
  final String? updatedAt;

  const BranchDto({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.status,
    this.address,
    this.contactPhone,
    this.contactEmail,
    this.managedBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory BranchDto.fromJson(Map<String, dynamic> json) {
    return BranchDto(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      address: json['address'] as String?,
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      managedBy: json['managed_by'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'status': status,
      'address': address,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'managed_by': managedBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
