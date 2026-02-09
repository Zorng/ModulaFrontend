import 'package:flutter/material.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/inventory/ui/components/branch_assignment.dart';
import 'package:modular_pos/features/inventory/ui/components/branch_assignment_card.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_section_card.dart';

class AddStockItemBranchAssignmentSection extends StatelessWidget {
  const AddStockItemBranchAssignmentSection({
    super.key,
    required this.userBranches,
    required this.branchAssignments,
    required this.usedBranchIds,
    required this.onAssignmentChanged,
    required this.onRemoveAssignment,
    required this.onAddAssignment,
    required this.isEditing,
  });

  final List<UserBranch> userBranches;
  final List<BranchAssignment> branchAssignments;
  final Set<String> Function(BranchAssignment assignment) usedBranchIds;
  final VoidCallback onAssignmentChanged;
  final void Function(BranchAssignment assignment) onRemoveAssignment;
  final VoidCallback onAddAssignment;
  final bool isEditing;


  @override
  Widget build(BuildContext context) {
    return InventorySectionCard(
      title: 'Branch assignment',
      children: [
        if (userBranches.isEmpty)
          const Text('No branches available. Add branches to assign this item.')
        else ...[
          ...branchAssignments.map(
            (assignment) => BranchAssignmentCard(
              isEditing: isEditing,
              assignment: assignment,
              branches: userBranches,
              usedBranchIds: usedBranchIds(assignment),
              onChanged: onAssignmentChanged,
              onRemove: () => onRemoveAssignment(assignment),
            ),
          ),
          if (branchAssignments.length < userBranches.length)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddAssignment,
                icon: const Icon(Icons.add),
                label: const Text('Assign to branch'),
              ),
            ),
        ],
      ],
    );
  }
}
