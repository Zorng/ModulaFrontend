import 'package:flutter/material.dart';

String viewCartsFormatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final monthNames = const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = monthNames[date.month - 1];
  final year = date.year;
  return '$month $day, $year';
}

String viewCartsFormatTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String viewCartsStateLabel(String state) {
  return switch (state) {
    'draft' => 'Draft',
    'finalized' => 'Finalized',
    'voided' => 'Voided',
    'reopened' => 'Reopened',
    _ => state,
  };
}

Color viewCartsStateColor(String state) {
  return switch (state) {
    'draft' => Colors.amber.shade700,
    'finalized' => Colors.green.shade700,
    'voided' => Colors.red.shade700,
    'reopened' => Colors.blue.shade700,
    _ => Colors.grey.shade700,
  };
}

