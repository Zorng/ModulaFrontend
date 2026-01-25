import 'package:flutter/material.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/inventory/ui/components/branch_assignment.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';

class BranchAssignmentCard extends StatelessWidget {
  const BranchAssignmentCard({
    super.key,
    required this.assignment,
    required this.branches,
    required this.usedBranchIds,
    required this.onChanged,
    required this.onRemove,
  });

  final BranchAssignment assignment;
  final List<UserBranch> branches;
  final Set<String> usedBranchIds;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final availableBranches = branches.where((b) {
      final id = b.branchId.isNotEmpty ? b.branchId : b.id;
      return !usedBranchIds.contains(id) || assignment.branchId == id;
    }).toList();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InventoryDropdown<String>(
                    initialValue: assignment.branchId,
                    label: const Text('Branch'),
                    entries: availableBranches
                        .map(
                          (b) => DropdownMenuEntry(
                            value: b.branchId.isNotEmpty ? b.branchId : b.id,
                            label: b.name,
                          ),
                        )
                        .toList(),
                    onSelected: (value) {
                      assignment.branchId = value;
                      onChanged();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Remove',
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: assignment.thresholdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minimum threshold',
                helperText: 'Alert when stock falls below this amount',
              ),
              onChanged: (_) => onChanged(),
            ),
          ],
        ),
      ),
    );
  }
}

