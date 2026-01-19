import 'package:flutter/material.dart';

class TenantSelectionTile extends StatelessWidget {
  const TenantSelectionTile({
    super.key,
    required this.tenantName,
    required this.tenantId,
    required this.role,
    required this.enabled,
    required this.onTap,
  });

  final String tenantName;
  final String tenantId;
  final String role;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tenantLabel = (tenantName.isNotEmpty ? tenantName : tenantId).trim();
    final roleText = role.trim();

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        tileColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        title: Text(
          tenantLabel.isEmpty ? 'Tenant' : tenantLabel,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: roleText.isEmpty
            ? null
            : Text('Role: ${roleText.toUpperCase()}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}

