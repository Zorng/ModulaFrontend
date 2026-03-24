import 'package:flutter/material.dart';
import 'package:modular_pos/features/policy/ui/widgets/policy_detail_controls.dart';

class AccountActionTiles extends StatelessWidget {
  const AccountActionTiles({
    super.key,
    required this.onSettingsTap,
    required this.onLogoutTap,
    required this.logoutEnabled,
  });

  final VoidCallback onSettingsTap;
  final VoidCallback onLogoutTap;
  final bool logoutEnabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Settings', style: textTheme.bodyMedium),
        const SizedBox(height: 8),
        PolicySettingGroup(
          children: [
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Open settings'),
              subtitle: const Text('Theme, language, and app preferences'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onSettingsTap,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Session', style: textTheme.bodyMedium),
        const SizedBox(height: 8),
        PolicySettingGroup(
          children: [
            ListTile(
              enabled: logoutEnabled,
              leading: Icon(
                Icons.logout,
                color: logoutEnabled ? colorScheme.error : null,
              ),
              title: Text(
                'Log out',
                style: logoutEnabled
                    ? textTheme.bodyLarge?.copyWith(color: colorScheme.error)
                    : null,
              ),
              subtitle: Text(
                logoutEnabled
                    ? 'End this session on this device'
                    : 'Signing out...',
              ),
              onTap: logoutEnabled ? onLogoutTap : null,
            ),
          ],
        ),
      ],
    );
  }
}
