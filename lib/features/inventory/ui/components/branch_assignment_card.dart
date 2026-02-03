import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/responsive.dart';
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
    this.enabled = true,
  });

  final BranchAssignment assignment;
  final List<UserBranch> branches;
  final Set<String> usedBranchIds;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final availableBranches = branches.where((b) {
      final id = b.branchId.isNotEmpty ? b.branchId : b.id;
      return !usedBranchIds.contains(id) || assignment.branchId == id;
    }).toList();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = !AppBreakpoints.isSmall(constraints.maxWidth);
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: InventoryDropdown<String>(
                      initialValue: assignment.branchId,
                      label: const Text('Branch'),
                      enabled: enabled,
                      entries: availableBranches
                          .map(
                            (b) => DropdownMenuEntry(
                              value: b.branchId.isNotEmpty ? b.branchId : b.id,
                              label: b.name,
                            ),
                          )
                          .toList(),
                      onSelected: enabled
                          ? (value) {
                              assignment.branchId = value;
                              onChanged();
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: assignment.thresholdCtrl,
                      keyboardType: TextInputType.number,
                      readOnly: !enabled,
                      enabled: enabled,
                      decoration: const InputDecoration(
                        labelText: 'Minimum threshold',
                        helperText: 'Alert when stock falls below this amount',
                      ),
                      onChanged: enabled ? (_) => onChanged() : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (enabled)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outlined,
                        color: Color(0xFFED533C),
                      ),
                      tooltip: 'Remove',
                      onPressed: onRemove,
                    ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InventoryDropdown<String>(
                        initialValue: assignment.branchId,
                        label: const Text('Branch'),
                        enabled: enabled,
                        entries: availableBranches
                            .map(
                              (b) => DropdownMenuEntry(
                                value: b.branchId.isNotEmpty ? b.branchId : b.id,
                                label: b.name,
                              ),
                            )
                            .toList(),
                        onSelected: enabled
                            ? (value) {
                                assignment.branchId = value;
                                onChanged();
                              }
                            : null,
                      ),
                    ),
                    if (enabled)
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
                  readOnly: !enabled,
                  enabled: enabled,
                  decoration: const InputDecoration(
                    labelText: 'Minimum threshold',
                    helperText: 'Alert when stock falls below this amount',
                  ),
                  onChanged: enabled ? (_) => onChanged() : null,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
