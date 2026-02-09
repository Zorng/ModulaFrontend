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
    this.isMobile = false,
    this.isReadOnly = false,
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
  final bool isMobile;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final option = selectedScheduleOption ?? 'same_hours';

    if (isMobile) {
      return _buildMobileLayout(context, option);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Schedule Type Toggle Buttons (hide in read-only mode)
        if (!isReadOnly)
          Row(
            children: [
              Expanded(
                child: _buildScheduleTypeButton(
                  context,
                  label: 'Apply same hours to selected days',
                  isSelected: option == 'same_hours',
                  onTap: () => onScheduleOptionChanged('same_hours'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScheduleTypeButton(
                  context,
                  label: 'Set different hours per day',
                  isSelected: option == 'different_hours',
                  onTap: () => onScheduleOptionChanged('different_hours'),
                ),
              ),
            ],
          ),
        if (!isReadOnly) const SizedBox(height: 24),
        if (option == 'same_hours') _buildSameHours(context),
        if (option == 'different_hours') _buildDifferentHours(context),
      ],
    );
  }

  Widget _buildScheduleTypeButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSameHours(BuildContext context) {
    // Map full names to abbreviations
    final dayMap = {
      'Monday': 'Mon',
      'Tuesday': 'Tue',
      'Wednesday': 'Wed',
      'Thursday': 'Thu',
      'Friday': 'Fri',
      'Saturday': 'Sat',
      'Sunday': 'Sun',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apply to Days',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        // Day buttons in a row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allDays.map((day) {
            final isSelected = selectedWorkingDays.contains(day);
            return GestureDetector(
              onTap: isReadOnly
                  ? null
                  : () {
                      final newSelection = Set<String>.from(
                        selectedWorkingDays,
                      );
                      if (isSelected) {
                        newSelection.remove(day);
                      } else {
                        newSelection.add(day);
                      }
                      onWorkingDaysChanged(newSelection);
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isReadOnly
                            ? Colors.grey.shade300
                            : Theme.of(context).primaryColor)
                      : (isReadOnly ? const Color(0xFFF5F7FA) : Colors.white),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? (isReadOnly
                              ? Colors.grey.shade300
                              : Theme.of(context).primaryColor)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  dayMap[day] ?? day.substring(0, 3),
                  style: TextStyle(
                    color: isSelected
                        ? (isReadOnly ? Colors.grey.shade700 : Colors.white)
                        : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.w500
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start Time',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TimePickerDropdown(
                    initialTime: startTime,
                    onTimeChanged: onStartTimeChanged,
                    isReadOnly: isReadOnly,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'End Time',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TimePickerDropdown(
                    initialTime: endTime,
                    onTimeChanged: onEndTimeChanged,
                    isReadOnly: isReadOnly,
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
      children: [for (final day in allDays) _buildDayCheckboxRow(context, day)],
    );
  }

  Widget _buildDayCheckboxRow(BuildContext context, String day) {
    final isSelected = selectedWorkingDays.contains(day);
    final times =
        customHours[day] ??
        (
          const TimeOfDay(hour: 9, minute: 0),
          const TimeOfDay(hour: 17, minute: 0),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Checkbox and day name
          SizedBox(
            width: 140,
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: isReadOnly
                      ? null
                      : (value) {
                          final newSelection = Set<String>.from(
                            selectedWorkingDays,
                          );
                          if (value == true) {
                            newSelection.add(day);
                          } else {
                            newSelection.remove(day);
                          }
                          onWorkingDaysChanged(newSelection);
                        },
                  activeColor: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    day,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isReadOnly ? Colors.grey.shade700 : Colors.black87,
                    ),
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Start Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (allDays.indexOf(day) == 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Start Time',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                TimePickerDropdown(
                  initialTime: times.$1,
                  onTimeChanged: (newTime) =>
                      onCustomHoursChanged(day, newTime, times.$2),
                  isReadOnly: isReadOnly,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // End Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (allDays.indexOf(day) == 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'End Time',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                TimePickerDropdown(
                  initialTime: times.$2,
                  onTimeChanged: (newTime) =>
                      onCustomHoursChanged(day, times.$1, newTime),
                  isReadOnly: isReadOnly,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, String option) {
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
        if (option == 'same_hours') _buildMobileSameHours(context),
        if (option == 'different_hours') _buildMobileDifferentHours(context),
      ],
    );
  }

  Widget _buildMobileSameHours(BuildContext context) {
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
                    isReadOnly: isReadOnly,
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
                    isReadOnly: isReadOnly,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileDifferentHours(BuildContext context) {
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
        for (final day in allDays) _buildMobileDayRow(context, day),
      ],
    );
  }

  Widget _buildMobileDayRow(BuildContext context, String day) {
    final isExpanded = expandedDay == day;
    final times =
        customHours[day] ??
        (
          const TimeOfDay(hour: 9, minute: 0),
          const TimeOfDay(hour: 17, minute: 0),
        );

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
                      Text(
                        'from',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      TimePickerDropdown(
                        initialTime: times.$1,
                        onTimeChanged: (newTime) =>
                            onCustomHoursChanged(day, newTime, times.$2),
                        isReadOnly: isReadOnly,
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
                        initialTime: times.$2,
                        onTimeChanged: (newTime) =>
                            onCustomHoursChanged(day, times.$1, newTime),
                        isReadOnly: isReadOnly,
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
