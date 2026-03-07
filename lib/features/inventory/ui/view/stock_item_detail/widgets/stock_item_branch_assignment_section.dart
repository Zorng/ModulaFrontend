import 'package:flutter/material.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/inventory/ui/components/branch_assignment.dart';
import 'package:modular_pos/features/inventory/ui/components/branch_assignment_card.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_section_card.dart';

class StockItemBranchAssignmentSection extends StatelessWidget {
  const StockItemBranchAssignmentSection({
    super.key,
    required this.isEditing,
    required this.userBranches,
    required this.branchAssignments,
    required this.branchNameResolver,
    required this.usedBranchIds,
    required this.onAddAssignment,
    required this.onAssignmentChanged,
    required this.onRemoveAssignment,
    this.showCard = true,
  });

  final bool isEditing;
  final List<UserBranch> userBranches;
  final List<BranchAssignment> branchAssignments;
  final String Function(String? branchId) branchNameResolver;
  final Set<String> Function(BranchAssignment assignment) usedBranchIds;
  final VoidCallback onAddAssignment;
  final VoidCallback onAssignmentChanged;
  final void Function(BranchAssignment assignment) onRemoveAssignment;
  final bool showCard;

  @override
  Widget build(BuildContext context) {
    final content = <Widget>[
      if (userBranches.isEmpty)
        const Text('No branches available.')
      else if (branchAssignments.isEmpty)
        Text(
          isEditing
              ? 'Select at least one branch for this item.'
              : 'Not assigned to any branch.',
        )
      else
        ...branchAssignments.map(
          (assignment) => BranchAssignmentCard(
            isEditing: isEditing,
            assignment: assignment,
            branches: userBranches,
            usedBranchIds: usedBranchIds(assignment),
            onChanged: onAssignmentChanged,
            onRemove: () => onRemoveAssignment(assignment),
            enabled: isEditing,
          ),
        ),
      if (isEditing && branchAssignments.length < userBranches.length)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAddAssignment,
            icon: const Icon(Icons.add),
            label: Text(
              branchAssignments.isEmpty ? 'Assign to branch' : 'Add branch',
            ),
          ),
        ),
    ];

    if (!showCard) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content,
      );
    }

    return InventorySectionCard(
      title: 'Branch assignment',
      backgroundColor: Colors.white,
      children: content,
    );
  }
}
