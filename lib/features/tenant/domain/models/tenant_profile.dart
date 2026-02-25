class TenantProfile {
  const TenantProfile({
    required this.tenantId,
    required this.tenantName,
    required this.tenantAddress,
    required this.contactNumber,
    required this.logoUrl,
    required this.status,
  });

  final String tenantId;
  final String tenantName;
  final String? tenantAddress;
  final String? contactNumber;
  final String? logoUrl;
  final String status;
}
