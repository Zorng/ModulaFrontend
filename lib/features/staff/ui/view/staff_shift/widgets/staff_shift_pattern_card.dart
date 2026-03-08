import 'package:flutter/material.dart';
import 'package:modular_pos/features/staff/domain/models/staff_shift_models.dart';
import 'package:modular_pos/features/staff/ui/components/staff_status_chip.dart';
import 'package:modular_pos/features/staff/ui/components/staff_ui_formatters.dart';

class StaffShiftPatternCard extends StatelessWidget {
  const StaffShiftPatternCard({
    super.key,
    required this.pattern,
    required this.membershipLabel,
    required this.onEdit,
    required this.onDeactivate,
  });

  final StaffShiftPattern pattern;
  final String membershipLabel;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  static const ButtonStyle _inlineFilledButtonStyle = ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(0, 48)),
  );

  static const ButtonStyle _inlineOutlinedButtonStyle = ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(0, 48)),
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    membershipLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StaffStatusChip.shiftPattern(status: pattern.status),
              ],
            ),
            const SizedBox(height: 12),
            Text('Days: ${formatDayOfWeekList(pattern.daysOfWeek)}'),
            const SizedBox(height: 6),
            Text(
              'Time: ${formatShiftTimeRange(pattern.plannedStartTime, pattern.plannedEndTime)}',
            ),
            const SizedBox(height: 6),
            Text(
              'Effective: ${formatStaffDate(pattern.effectiveFrom)} → ${formatStaffDate(pattern.effectiveTo)}',
            ),
            if ((pattern.note ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Note: ${pattern.note!.trim()}'),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton(
                  style: _inlineOutlinedButtonStyle,
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
                FilledButton.tonal(
                  style: _inlineFilledButtonStyle,
                  onPressed: onDeactivate,
                  child: const Text('Deactivate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
