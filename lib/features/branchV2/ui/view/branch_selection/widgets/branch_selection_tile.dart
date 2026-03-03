import 'package:flutter/material.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';

class BranchSelectionTile extends StatelessWidget {
  const BranchSelectionTile({
    super.key,
    required this.branch,
    required this.enabled,
    required this.onTap,
  });

  final BranchListItem branch;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = branch.isFrozen
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Card(
      child: ListTile(
        enabled: enabled,
        onTap: onTap,
        title: Row(
          children: [
            Expanded(child: Text(branch.branchName)),
            if (branch.isNew)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'New',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            branch.branchAddress?.trim().isNotEmpty == true
                ? branch.branchAddress!
                : branch.branchId,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              branch.status,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: statusColor),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
        selected: branch.shouldHighlight,
      ),
    );
  }
}
