import 'package:flutter/material.dart';
import 'package:modular_pos/features/staff/ui/view/staff_attendance/staff_attendance_models.dart';

StaffAttendanceDateRange buildUtcDayRange(DateTime date) {
  final start = DateTime(date.year, date.month, date.day);
  final end = start.add(const Duration(days: 1));
  return StaffAttendanceDateRange(
    fromIsoUtc: start.toUtc().toIso8601String(),
    toIsoUtc: end.toUtc().toIso8601String(),
  );
}

String formatDateYyyyMmDd(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String formatTimeHmAmPm(DateTime date) {
  final timeOfDay = TimeOfDay.fromDateTime(date);
  final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
  final minutes = timeOfDay.minute.toString().padLeft(2, '0');
  final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minutes $period';
}

String titleCaseSnake(String value) {
  if (value.isEmpty) return value;
  return value
      .split('_')
      .map((part) {
        if (part.isEmpty) return part;
        return part[0].toUpperCase() + part.substring(1).toLowerCase();
      })
      .join(' ');
}
