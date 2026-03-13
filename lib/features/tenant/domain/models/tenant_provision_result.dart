class TenantProvisionResult {
  const TenantProvisionResult({
    required this.tenantId,
    required this.tenantName,
    required this.tenantStatus,
    required this.ownerMembershipId,
    required this.ownerRoleKey,
    required this.ownerStatus,
    required this.branch,
  });

  final String tenantId;
  final String tenantName;
  final String tenantStatus;
  final String ownerMembershipId;
  final String ownerRoleKey;
  final String ownerStatus;
  final Object? branch;
}
