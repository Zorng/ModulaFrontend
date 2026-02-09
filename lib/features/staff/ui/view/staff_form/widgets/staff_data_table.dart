import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';

class StaffDataTable extends StatelessWidget {
  const StaffDataTable({
    super.key,
    required this.staffList,
    required this.onStaffTap,
  });

  final List<Staff> staffList;
  final void Function(Staff) onStaffTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                AppTableTheme.headerBackground,
              ),
              columnSpacing: 8,
              horizontalMargin: 0,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 56,
              headingTextStyle: AppTableTheme.headerText,
              dataTextStyle: AppTableTheme.cellText,
              columns: [
                DataColumn(
                  label: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: const SizedBox(width: 30, child: Text('No.')),
                  ),
                ),
                const DataColumn(label: Text('Staff Name')),
                const DataColumn(label: Text('Roles')),
                DataColumn(
                  label: const Text('Assigned Branch(es)'),
                  numeric: false,
                ),
                const DataColumn(label: Text('Contact')),
                DataColumn(label: const Text('Last Login'), numeric: false),
                const DataColumn(label: Text('Status')),
                const DataColumn(label: Text('Action')),
              ],
              rows: List.generate(staffList.length, (index) {
                final staff = staffList[index];
                return _buildDataRow(context, index + 1, staff);
              }),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildDataRow(BuildContext context, int number, Staff staff) {
    final String name = staff.userName;
    final String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final statusLabel =
        staff.status ?? (staff.isActive ? 'Active' : 'Inactive');
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

        // Staff Name with Avatar
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  firstLetter,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),

        // Roles
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: _getRoleColor(staff.role), width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              staff.role ?? 'No Role',
              style: TextStyle(
                color: _getRoleColor(staff.role),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // Assigned Branch(es)
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              staff.branch ?? 'No Branch',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),

        // Contact
        DataCell(Text(staff.phoneNumber, overflow: TextOverflow.ellipsis)),

        // Last Login - placeholder for now as the model doesn't have this field
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: const Text(
              '-',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
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
            onPressed: () => onStaffTap(staff),
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

  Color _getRoleColor(String? role) {
    if (role == null) return Colors.grey;
    switch (role.toLowerCase()) {
      case 'manager':
        return Colors.blue;
      case 'cashier':
        return Colors.orange;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'invited':
        return Colors.blue;
      case 'disabled':
        return Colors.orange;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _statusTextColor(String status) {
    final base = _statusColor(status);
    if (base == Colors.grey) return Colors.grey.shade700;
    if (base == Colors.orange) return Colors.orange.shade700;
    if (base == Colors.blue) return Colors.blue.shade700;
    if (base == Colors.green) return Colors.green.shade700;
    if (base == Colors.purple) return Colors.purple.shade700;
    return base;
  }
}
