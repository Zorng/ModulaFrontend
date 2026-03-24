import 'package:flutter/material.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/policy/ui/widgets/policy_detail_controls.dart';

class AccountUserTile extends StatelessWidget {
  const AccountUserTile({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profile', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        PolicySettingGroup(
          children: [
            ListTile(
              leading: CircleAvatar(
                child: Text(
                  user.name.isNotEmpty
                      ? user.name.characters.first.toUpperCase()
                      : '?',
                ),
              ),
              title: Text(
                user.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(user.role),
            ),
            if (user.phone.isNotEmpty)
              ListTile(title: const Text('Phone'), subtitle: Text(user.phone)),
            if (user.tenantId.isNotEmpty)
              ListTile(
                title: const Text('Tenant ID'),
                subtitle: Text(user.tenantId),
              ),
          ],
        ),
      ],
    );
  }
}
