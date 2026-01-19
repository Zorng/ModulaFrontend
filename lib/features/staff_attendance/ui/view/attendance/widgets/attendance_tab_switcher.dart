import 'package:flutter/material.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance/attendance_models.dart';

class AttendanceTabSwitcher extends StatelessWidget {
  const AttendanceTabSwitcher({
    super.key,
    required this.tab,
    required this.onSelected,
  });

  final AttendanceTab tab;
  final ValueChanged<AttendanceTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () => onSelected(AttendanceTab.check),
            style: FilledButton.styleFrom(
              backgroundColor: tab == AttendanceTab.check
                  ? scheme.primary
                  : scheme.surfaceContainerHighest,
              foregroundColor: tab == AttendanceTab.check
                  ? scheme.onPrimary
                  : scheme.onSurface,
            ),
            child: const Text('Check'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: () => onSelected(AttendanceTab.history),
            style: FilledButton.styleFrom(
              backgroundColor: tab == AttendanceTab.history
                  ? scheme.primary
                  : scheme.surfaceContainerHighest,
              foregroundColor: tab == AttendanceTab.history
                  ? scheme.onPrimary
                  : scheme.onSurface,
            ),
            child: const Text('History'),
          ),
        ),
      ],
    );
  }
}

