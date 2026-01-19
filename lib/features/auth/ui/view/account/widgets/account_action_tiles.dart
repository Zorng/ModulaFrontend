import 'package:flutter/material.dart';
import 'package:modular_pos/features/policy/ui/widgets/policy_detail_controls.dart';

class AccountActionTiles extends StatelessWidget {
  const AccountActionTiles({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Actions', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        const PolicySettingGroup(
          children: [
            PolicyComingSoonTile(
              title: 'Change password',
              icon: Icons.lock_outline,
            ),
            PolicyComingSoonTile(
              title: 'Change business name',
              icon: Icons.store_outlined,
            ),
          ],
        ),
      ],
    );
  }
}

