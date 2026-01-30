import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';

/// A reusable widget that displays a staff member's shift schedule in a table format.
class StaffScheduleTable extends StatelessWidget {
  const StaffScheduleTable({
    super.key,
    required this.schedule,
    this.showCard = true,
  });

  final List<ShiftScheduleEntry> schedule;
  final bool showCard;

  @override
  Widget build(BuildContext context) {
    if (schedule.isEmpty) {
      return Text(
        'No schedule available',
        style: TextStyle(color: Colors.grey.shade600),
      );
    }

    final days = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    final table = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shift Schedule',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(0.6),
            1: FlexColumnWidth(1.4),
          },
          children: [
            const TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Day',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Shift',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            ...List.generate(7, (index) {
              final entry = schedule.firstWhere(
                (item) => item.dayOfWeek == index,
                orElse: () => const ShiftScheduleEntry(
                  dayOfWeek: -1,
                  isOff: true,
                ),
              );
              final shiftLabel = entry.dayOfWeek == -1
                  ? '-'
                  : entry.isOff
                      ? 'Off'
                      : '${entry.startTime ?? '--'} - ${entry.endTime ?? '--'}';
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(days[index]),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(shiftLabel),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );

    if (!showCard) {
      return table;
    }

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: table,
      ),
    );
  }
}
