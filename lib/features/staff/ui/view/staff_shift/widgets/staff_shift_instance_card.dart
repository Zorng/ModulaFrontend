import 'package:flutter/material.dart';
import 'package:modular_pos/features/staff/domain/models/staff_shift_models.dart';
import 'package:modular_pos/features/staff/ui/components/staff_status_chip.dart';
import 'package:modular_pos/features/staff/ui/components/staff_ui_formatters.dart';

class StaffShiftInstanceCard extends StatelessWidget {
  const StaffShiftInstanceCard({
    super.key,
    required this.instance,
    required this.membershipLabel,
    required this.onEdit,
    required this.onCancel,
  });

  final StaffShiftInstance instance;
  final String membershipLabel;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

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
                StaffStatusChip.shiftInstance(status: instance.status),
              ],
            ),
            const SizedBox(height: 12),
            Text('Date: ${formatStaffDate(instance.date)}'),
            const SizedBox(height: 6),
            Text(
              'Time: ${formatShiftTimeRange(instance.plannedStartTime, instance.plannedEndTime)}',
            ),
            if ((instance.note ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Note: ${instance.note!.trim()}'),
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
                  onPressed: onCancel,
                  child: const Text('Cancel shift'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
