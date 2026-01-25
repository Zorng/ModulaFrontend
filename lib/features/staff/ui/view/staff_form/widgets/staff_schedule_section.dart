import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modular_pos/features/staff/ui/widgets/custom_cupertino_list_tile.dart';
import 'package:modular_pos/features/staff/ui/widgets/time_picker_dropdown.dart';
import 'package:modular_pos/features/staff/ui/widgets/working_days_dropdown.dart';

class StaffScheduleSection extends StatelessWidget {
  const StaffScheduleSection({
    super.key,
    required this.selectedScheduleOption,
    required this.onScheduleOptionChanged,
    required this.allDays,
    required this.selectedWorkingDays,
    required this.onWorkingDaysChanged,
    required this.startTime,
    required this.onStartTimeChanged,
    required this.endTime,
    required this.onEndTimeChanged,
    required this.expandedDay,
    required this.onExpandedDayChanged,
    required this.customHours,
    required this.onCustomHoursChanged,
  });

  final String? selectedScheduleOption;
  final ValueChanged<String> onScheduleOptionChanged;

  final List<String> allDays;
  final Set<String> selectedWorkingDays;
  final ValueChanged<Set<String>> onWorkingDaysChanged;

  final TimeOfDay startTime;
  final ValueChanged<TimeOfDay> onStartTimeChanged;
  final TimeOfDay endTime;
  final ValueChanged<TimeOfDay> onEndTimeChanged;

  final String? expandedDay;
  final ValueChanged<String?> onExpandedDayChanged;

  final Map<String, (TimeOfDay, TimeOfDay)> customHours;
  final void Function(String day, TimeOfDay start, TimeOfDay end)
      onCustomHoursChanged;

  @override
  Widget build(BuildContext context) {
    final option = selectedScheduleOption ?? 'same_hours';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Schedule Type'),
        const SizedBox(height: 8),
        CustomCupertinoListTile(
          title: const Text('Apply same hours to all days'),
          leading: Icon(
            option == 'same_hours'
                ? CupertinoIcons.circle_filled
                : CupertinoIcons.circle,
            color: option == 'same_hours'
                ? Theme.of(context).colorScheme.primary
                : CupertinoColors.inactiveGray,
          ),
          onTap: () => onScheduleOptionChanged('same_hours'),
        ),
        CustomCupertinoListTile(
          title: const Text('Set different hours per day'),
          leading: Icon(
            option == 'different_hours'
                ? CupertinoIcons.circle_filled
                : CupertinoIcons.circle,
            color: option == 'different_hours'
                ? Theme.of(context).colorScheme.primary
                : CupertinoColors.inactiveGray,
          ),
          onTap: () => onScheduleOptionChanged('different_hours'),
        ),
        if (option == 'same_hours') _buildSameHours(context),
        if (option == 'different_hours') _buildDifferentHours(context),
      ],
    );
  }

  Widget _buildSameHours(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('Working Days'),
        const SizedBox(height: 8),
        WorkingDaysDropdown(
          selectedDays: selectedWorkingDays,
          onChanged: onWorkingDaysChanged,
        ),
        const SizedBox(height: 12),
        const Text('Working Hours'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('from', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  TimePickerDropdown(
                    initialTime: startTime,
                    onTimeChanged: onStartTimeChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('to', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  TimePickerDropdown(
                    initialTime: endTime,
                    onTimeChanged: onEndTimeChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDifferentHours(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Working Days',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'Select day',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final day in allDays) _buildDayRow(context, day),
      ],
    );
  }

  Widget _buildDayRow(BuildContext context, String day) {
    final isExpanded = expandedDay == day;
    final times = customHours[day] ??
        (const TimeOfDay(hour: 9, minute: 0), const TimeOfDay(hour: 17, minute: 0));

    return Column(
      children: [
        GestureDetector(
          onTap: () => onExpandedDayChanged(isExpanded ? null : day),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(day),
                Icon(
                  isExpanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('from',
                          style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 4),
                      TimePickerDropdown(
                        initialTime: times.$1,
                        onTimeChanged: (newTime) =>
                            onCustomHoursChanged(day, newTime, times.$2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('to',
                          style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 4),
                      TimePickerDropdown(
                        initialTime: times.$2,
                        onTimeChanged: (newTime) =>
                            onCustomHoursChanged(day, times.$1, newTime),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

