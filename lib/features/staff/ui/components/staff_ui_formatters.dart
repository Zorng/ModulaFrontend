import 'package:flutter/material.dart';

String formatStaffDate(DateTime? value) {
  if (value == null) return '-';
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String formatStaffDateTime(DateTime? value) {
  if (value == null) return '-';
  final date = formatStaffDate(value);
  final time = TimeOfDay.fromDateTime(value);
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$date $hour:$minute $period';
}

String formatShiftTimeRange(String start, String end) {
  final normalizedStart = start.trim().isEmpty ? '--:--' : start.trim();
  final normalizedEnd = end.trim().isEmpty ? '--:--' : end.trim();
  return '$normalizedStart - $normalizedEnd';
}

String formatDayOfWeekList(List<int> daysOfWeek) {
  const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final normalized = daysOfWeek.toSet().toList()..sort();
  if (normalized.isEmpty) return '-';
  return normalized
      .where((day) => day >= 0 && day < labels.length)
      .map((day) => labels[day])
      .join(', ');
}

String formatBranchAssignmentSummary(
  List<String> branchIds,
  Map<String, String> branchNameById,
) {
  if (branchIds.isEmpty) return 'No branches assigned';
  final names = branchIds
      .map((branchId) => branchNameById[branchId] ?? branchId)
      .toList(growable: false);
  if (names.length == 1) return names.first;
  final preview = names.take(2).join(', ');
  final remaining = names.length - 2;
  if (remaining <= 0) return preview;
  return '$preview +$remaining more';
}
