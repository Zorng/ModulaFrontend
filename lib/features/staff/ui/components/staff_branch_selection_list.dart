import 'package:flutter/material.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';

class StaffBranchSelectionList extends StatelessWidget {
  const StaffBranchSelectionList({
    super.key,
    required this.availableBranches,
    required this.selectedBranchIds,
    required this.onChanged,
  });

  final List<BranchListItem> availableBranches;
  final Set<String> selectedBranchIds;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    if (availableBranches.isEmpty) {
      return const Text('No branches available.');
    }

    return Column(
      children: [
        for (final branch in availableBranches)
          CheckboxListTile(
            value: selectedBranchIds.contains(branch.branchId),
            title: Text(branch.branchName),
            subtitle: Text(branch.status),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (selected) {
              final next = {...selectedBranchIds};
              if (selected == true) {
                next.add(branch.branchId);
              } else {
                next.remove(branch.branchId);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}
