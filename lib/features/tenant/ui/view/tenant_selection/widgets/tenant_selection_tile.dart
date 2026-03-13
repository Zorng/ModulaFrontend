import 'package:flutter/material.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';

class TenantSelectionTile extends StatelessWidget {
  const TenantSelectionTile({
    super.key,
    required this.membership,
    this.onTap,
    this.enabled = true,
  });

  final TenantMembership membership;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tenantName = membership.tenantName.trim().isEmpty
        ? membership.tenantId
        : membership.tenantName.trim();
    final role = membership.role.trim().isEmpty ? 'MEMBER' : membership.role;

    return Card(
      child: ListTile(
        enabled: enabled,
        leading: const Icon(Icons.storefront_outlined),
        title: Text(tenantName),
        subtitle: Text(role.toUpperCase()),
        trailing: const Icon(Icons.chevron_right),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
