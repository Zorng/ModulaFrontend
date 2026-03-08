import 'package:flutter/material.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';

class BranchSelectionTile extends StatelessWidget {
  const BranchSelectionTile({
    super.key,
    required this.branch,
    required this.enabled,
    required this.onTap,
    this.onManage,
  });

  final BranchListItem branch;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onManage;

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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
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
            if (onManage != null) ...[
              const SizedBox(width: 4),
              PopupMenuButton<_BranchTileAction>(
                enabled: enabled,
                tooltip: 'Branch actions',
                onSelected: (value) {
                  if (value == _BranchTileAction.manage) {
                    onManage?.call();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<_BranchTileAction>(
                    value: _BranchTileAction.manage,
                    child: Text('Manage branch'),
                  ),
                ],
              ),
            ],
          ],
        ),
        selected: branch.shouldHighlight,
      ),
    );
  }
}

enum _BranchTileAction { manage }
