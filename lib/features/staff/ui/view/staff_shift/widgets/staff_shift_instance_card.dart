import 'package:flutter/material.dart';
import 'package:modular_pos/features/staff/domain/models/staff_shift_models.dart';
import 'package:modular_pos/features/staff/ui/components/staff_status_chip.dart';
import 'package:modular_pos/features/staff/ui/components/staff_ui_formatters.dart';
import 'package:modular_pos/features/staff/ui/view/staff_shift/widgets/staff_shift_detail_row.dart';
import 'package:modular_pos/core/widgets/display/staff_shift_info_chip.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = membershipLabel
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    
    final buttonStyle = FilledButton.styleFrom(
      minimumSize: const Size(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        membershipLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StaffStatusChip.shiftInstance(status: instance.status),
              ],
            ),

            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 14),

            // ── Info chips ───────────────────────────────────────────
            Row(
              children: [
                InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: formatStaffDate(instance.date),
                ),
                const SizedBox(width: 8),
                InfoChip(
                  icon: Icons.access_time_outlined,
                  label: 'Time',
                  value: formatShiftTimeRange(
                    instance.plannedStartTime,
                    instance.plannedEndTime,
                  ),
                ),
              ],
            ),

            if ((instance.note ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              DetailRow(
                icon: Icons.notes_outlined,
                label: 'Note',
                value: instance.note!.trim(),
              ),
            ],

            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 12),

            // ── Actions ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onEdit,
                    style: buttonStyle,
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: onCancel,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cancel shift'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
