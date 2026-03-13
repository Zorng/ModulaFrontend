import 'package:flutter/material.dart';

class GlobalManagementEntryTile extends StatelessWidget {
  const GlobalManagementEntryTile({
    super.key,
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        enabled: enabled,
        onTap: onTap,
        leading: const Icon(Icons.admin_panel_settings_outlined),
        title: const Text('Enter Global Management'),
        subtitle: const Text('Manage tenant-level configuration and access'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
