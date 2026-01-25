import 'package:flutter/material.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_management/attendance_management_utils.dart';

class AttendanceManagementDatePickerRow extends StatelessWidget {
  const AttendanceManagementDatePickerRow({
    super.key,
    required this.selectedDate,
    required this.onPickDate,
    required this.enabled,
  });

  final DateTime selectedDate;
  final VoidCallback onPickDate;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: enabled ? onPickDate : null,
          icon: const Icon(Icons.calendar_today_outlined, size: 16),
          label: Text(formatDateYyyyMmDd(selectedDate)),
        ),
      ],
    );
  }
}

