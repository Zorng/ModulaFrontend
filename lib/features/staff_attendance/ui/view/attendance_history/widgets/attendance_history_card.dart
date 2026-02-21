import 'package:flutter/material.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_history_entry.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_shared/attendance_utils.dart';

class AttendanceHistoryCard extends StatelessWidget {
  const AttendanceHistoryCard({super.key, required this.entry});

  final AttendanceHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final checkInLabel = entry.checkInAt == null
        ? '-'
        : formatTimeAmPm(entry.checkInAt!);
    final checkOutLabel = entry.checkOutAt == null
        ? '-'
        : formatTimeAmPm(entry.checkOutAt!);

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HistoryRow(label: 'Date', value: entry.date),
            const SizedBox(height: 8),
            _HistoryRow(label: 'Check in', value: checkInLabel),
            const SizedBox(height: 8),
            _HistoryRow(label: 'Check out', value: checkOutLabel),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(value ?? '', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
