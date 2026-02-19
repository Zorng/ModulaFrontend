import 'package:flutter/material.dart';
import 'package:modular_pos/features/staff/domain/models/staff_attendance_record.dart';
import 'package:modular_pos/features/staff/ui/view/staff_attendance/staff_attendance_utils.dart';
import 'package:modular_pos/features/staff/ui/view/staff_attendance/widgets/staff_attendance_key_value_row.dart';

class StaffAttendanceRecordCard extends StatelessWidget {
  const StaffAttendanceRecordCard({super.key, required this.record});

  final StaffAttendanceRecord record;

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
            StaffAttendanceKeyValueRow(
              label: 'Status',
              value: titleCaseSnake(record.type),
            ),
            const SizedBox(height: 8),
            StaffAttendanceKeyValueRow(label: 'Branch', value: record.branchId),
            const SizedBox(height: 8),
            StaffAttendanceKeyValueRow(
              label: 'Staff',
              value: record.employeeId,
            ),
            const SizedBox(height: 8),
            StaffAttendanceKeyValueRow(
              label: 'Occurred at',
              value:
                  '${formatDateYyyyMmDd(record.occurredAt)} ${formatTimeHmAmPm(record.occurredAt)}',
            ),
            const SizedBox(height: 8),
            StaffAttendanceKeyValueRow(
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
