import 'package:flutter/material.dart';
import 'package:modular_pos/features/policy/ui/widgets/policy_detail_controls.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _SettingEntry('Dark mode', 'Coming soon', Icons.dark_mode_outlined),
      _SettingEntry('Language', 'Coming soon', Icons.language_outlined),
    ];

    return PolicyDetailScaffold(
      title: 'Settings',
      isEditing: false,
      onEditToggle: () {},
      child: PolicySettingGroup(
        children: items
            .map(
              (item) => PolicyComingSoonTile(
                title: item.title,
                subtitle: item.subtitle,
                icon: item.icon,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SettingEntry {
  const _SettingEntry(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}
