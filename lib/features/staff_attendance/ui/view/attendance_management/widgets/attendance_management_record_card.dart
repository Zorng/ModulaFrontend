import 'package:flutter/material.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_record.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_management/attendance_management_utils.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_management/widgets/attendance_management_key_value_row.dart';

class AttendanceManagementRecordCard extends StatelessWidget {
  const AttendanceManagementRecordCard({
    super.key,
    required this.record,
  });

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AttendanceManagementKeyValueRow(
              label: 'Status',
              value: titleCaseSnake(record.type),
            ),
            const SizedBox(height: 8),
            AttendanceManagementKeyValueRow(
              label: 'Staff',
              value: record.employeeId,
            ),
            const SizedBox(height: 8),
            AttendanceManagementKeyValueRow(
              label: 'Occurred at',
              value:
                  '${formatDateYyyyMmDd(record.occurredAt)} ${formatTimeHmAmPm(record.occurredAt)}',
            ),
            const SizedBox(height: 8),
            AttendanceManagementKeyValueRow(
              label: 'Created at',
              value:
                  '${formatDateYyyyMmDd(record.createdAt)} ${formatTimeHmAmPm(record.createdAt)}',
            ),
          ],
        ),
      ),
    );
  }
}

