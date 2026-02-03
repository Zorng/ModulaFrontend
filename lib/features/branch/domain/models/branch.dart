/// Branch domain model
class Branch {
  final String id;
  final String tenantId;
  final String name;
  final String status; // 'ACTIVE' or 'FROZEN'
  final String? address;
  final String? contactPhone;
  final String? contactEmail;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Branch({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.status,
    this.address,
    this.contactPhone,
    this.contactEmail,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == 'ACTIVE';
  bool get isFrozen => status == 'FROZEN';

  Branch copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? status,
    String? address,
    String? contactPhone,
    String? contactEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Branch(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      status: status ?? this.status,
      address: address ?? this.address,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
