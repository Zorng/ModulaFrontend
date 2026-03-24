import 'package:flutter/material.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/policy/ui/widgets/policy_detail_controls.dart';

class AccountMembershipList extends StatelessWidget {
  const AccountMembershipList({
    super.key,
    required this.memberships,
    required this.activeTenantId,
  });

  final List<TenantMembership> memberships;
  final String? activeTenantId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Access', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        PolicySettingGroup(
          children: memberships
              .map(
                (membership) => ListTile(
                  title: Text(membership.tenantName),
                  subtitle: Text(_subtitleFor(membership)),
                  isThreeLine: true,
                  trailing: _CurrentTenantBadge(
                    visible:
                        membership.tenantId.trim() == activeTenantId?.trim(),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  String _subtitleFor(TenantMembership membership) {
    final role = membership.role.trim().isEmpty
        ? 'Member'
        : membership.role.trim();
    final branchNames = membership.branches
        .map((branch) => branch.name.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    final branchSummary = branchNames.isEmpty
        ? 'No assigned branches'
        : branchNames.length <= 3
        ? branchNames.join(', ')
        : '${branchNames.take(3).join(', ')} +${branchNames.length - 3} more';
    final branchLabel = membership.branches.length == 1
        ? '1 branch'
        : '${membership.branches.length} branches';
    return '$role · $branchLabel\n$branchSummary';
  }
}

class _CurrentTenantBadge extends StatelessWidget {
  const _CurrentTenantBadge({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          'Current',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
