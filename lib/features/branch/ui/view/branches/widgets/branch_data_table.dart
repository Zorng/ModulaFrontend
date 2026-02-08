import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/features/branch/domain/models/branch.dart';

class BranchDataTable extends StatelessWidget {
  const BranchDataTable({
    super.key,
    required this.branchList,
    required this.onBranchTap,
  });

  final List<Branch> branchList;
  final void Function(Branch) onBranchTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTableTheme.headerBackground),
              columnSpacing: 8,
              horizontalMargin: 0,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 56,
              columns: [
                DataColumn(
                  label: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: SizedBox(
                      width: 30,
                      child: Text('No.', style: AppTableTheme.headerText),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text('Branch Name', style: AppTableTheme.headerText),
                ),
                DataColumn(
                  label: Text('Address', style: AppTableTheme.headerText),
                ),
                DataColumn(
                  label: Text('Managed By', style: AppTableTheme.headerText),
                ),
                DataColumn(
                  label: Text('Branch Contact', style: AppTableTheme.headerText),
                ),
                DataColumn(
                  label: Text('Status', style: AppTableTheme.headerText),
                ),
                DataColumn(
                  label: Text('Action', style: AppTableTheme.headerText),
                ),
              ],
              rows: List.generate(branchList.length, (index) {
                final branch = branchList[index];
                return _buildDataRow(context, index + 1, branch);
              }),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildDataRow(BuildContext context, int number, Branch branch) {
    final statusLabel = branch.isActive ? 'Active' : 'Inactive';
    final isActive = branch.isActive;

    return DataRow(
      cells: [
        // No.
        DataCell(
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              number.toString(),
              style: AppTableTheme.cellText,
            ),
          ),
        ),

        // Branch Name
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              branch.name,
              overflow: TextOverflow.ellipsis,
              style: AppTableTheme.cellText,
            ),
          ),
        ),

        // Address
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              branch.address ?? '-',
              overflow: TextOverflow.ellipsis,
              style: AppTableTheme.cellText,
            ),
          ),
        ),

        // Managed By
        DataCell(
          Text(
            branch.managedBy ?? 'Not assigned',
            style: AppTableTheme.cellText,
          ),
        ),

        // Branch Contact
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              branch.contactPhone ?? '-',
              overflow: TextOverflow.ellipsis,
              style: AppTableTheme.cellText,
            ),
          ),
        ),

        // Status
        DataCell(
          Container(
            width: 80,
            height: 28,
            alignment: Alignment.center,
            decoration: isActive
                ? AppTableTheme.healthyDecoration
                : AppTableTheme.dangerDecoration,
            child: Text(
              statusLabel,
              style: isActive
                  ? AppTableTheme.healthyText
                  : AppTableTheme.dangerText,
            ),
          ),
        ),

        // Action
        DataCell(
          ElevatedButton(
            onPressed: () => onBranchTap(branch),
            style: AppTableTheme.actionButtonStyle.copyWith(
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              minimumSize: const WidgetStatePropertyAll(Size(60, 32)),
            ),
            child: const Text('View', style: TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }

}
