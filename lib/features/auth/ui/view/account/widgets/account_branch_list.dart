import 'package:flutter/material.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/policy/ui/widgets/policy_detail_controls.dart';

class AccountBranchList extends StatelessWidget {
  const AccountBranchList({
    super.key,
    required this.branches,
    this.title = 'Branch access',
  });

  final List<UserBranch> branches;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        PolicySettingGroup(
          children: branches
              .map(
                (branch) => ListTile(
                  title: Text(branch.name),
                  subtitle: Text(branch.role),
                  trailing: branch.active ? const Icon(Icons.check) : null,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
