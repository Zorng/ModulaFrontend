import 'package:flutter/material.dart';
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
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
              columnSpacing: 8,
              horizontalMargin: 0,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 56,
              columns: [
                DataColumn(
                  label: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: const SizedBox(width: 30, child: Text('No.')),
                  ),
                ),
                const DataColumn(label: Text('Branch Name')),
                const DataColumn(label: Text('Address')),
                const DataColumn(label: Text('Branch Contact')),
                const DataColumn(label: Text('Status')),
                const DataColumn(label: Text('Action')),
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
    final statusLabel = branch.isActive ? 'Active' : 'Frozen';
    final statusTextColor = _statusTextColor(statusLabel);

    return DataRow(
      cells: [
        // No.
        DataCell(
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(number.toString()),
          ),
        ),

        // Branch Name
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              branch.name,
              overflow: TextOverflow.ellipsis,
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
            ),
          ),
        ),

        // Branch Contact
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              branch.contactPhone ?? '-',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Status
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: statusTextColor, width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // Action
        DataCell(
          OutlinedButton(
            onPressed: () => onBranchTap(branch),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(60, 32),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: const Text('View'),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'frozen':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _statusTextColor(String status) {
    final base = _statusColor(status);
    if (base == Colors.grey) return Colors.grey.shade700;
    if (base == Colors.green) return Colors.green.shade700;
    if (base == Colors.red) return Colors.red.shade700;
    return base;
  }
}
