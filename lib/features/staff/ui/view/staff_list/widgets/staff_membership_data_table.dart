import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/features/staff/domain/models/staff_membership_models.dart';
import 'package:modular_pos/features/staff/ui/components/staff_role_chip.dart';
import 'package:modular_pos/features/staff/ui/components/staff_status_chip.dart';
import 'package:modular_pos/features/staff/ui/components/staff_ui_formatters.dart';

class StaffMembershipDataTable extends StatelessWidget {
  const StaffMembershipDataTable({
    super.key,
    required this.memberships,
    required this.branchNameById,
    required this.onView,
  });

  final List<StaffMembershipSummary> memberships;
  final Map<String, String> branchNameById;
  final ValueChanged<StaffMembershipSummary> onView;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: AppTableTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTableTheme.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: DataTable(
                    columnSpacing: 20,
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 72,
                    headingRowColor: WidgetStateProperty.all(
                      AppTableTheme.headerBackground,
                    ),
                    dataRowColor: const WidgetStatePropertyAll(
                      AppTableTheme.background,
                    ),
                    dividerThickness: 1,
                    border: const TableBorder(),
                    columns: const [
                      DataColumn(
                        label: Text('Staff', style: AppTableTheme.headerText),
                      ),
                      DataColumn(
                        label: Text('Role', style: AppTableTheme.headerText),
                      ),
                      DataColumn(
                        label: Text('Status', style: AppTableTheme.headerText),
                      ),
                      DataColumn(
                        label: Text(
                          'Branches',
                          style: AppTableTheme.headerText,
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Lifecycle',
                          style: AppTableTheme.headerText,
                        ),
                      ),
                      DataColumn(
                        label: Text('Action', style: AppTableTheme.headerText),
                      ),
                    ],
                    rows: memberships
                        .map(
                          (membership) => DataRow(
                            cells: [
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      membership.displayName,
                                      style: AppTableTheme.cellText,
                                    ),
                                    Text(
                                      membership.phone,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                StaffRoleChip(roleKey: membership.roleKey),
                              ),
                              DataCell(
                                StaffStatusChip.membership(
                                  status: membership.membershipStatus,
                                ),
                              ),
                              DataCell(
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 260,
                                  ),
                                  child: Text(
                                    formatBranchAssignmentSummary(
                                      membership.branchIds,
                                      branchNameById,
                                    ),
                                    style: AppTableTheme.cellText,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${membership.primaryLifecycleLabel}: ${formatStaffDateTime(membership.primaryLifecycleTimestamp)}',
                                  style: AppTableTheme.cellText,
                                ),
                              ),
                              DataCell(
                                FilledButton(
                                  style: AppTableTheme.actionButtonStyle,
                                  onPressed: () => onView(membership),
                                  child: const Text('View'),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
