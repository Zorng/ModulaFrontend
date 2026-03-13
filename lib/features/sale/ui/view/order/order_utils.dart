import 'package:flutter/material.dart';

String formatOrderTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String formatOrderDate(DateTime date) {
  const months = [
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
  final month = months[date.month - 1];
  final day = date.day.toString().padLeft(2, '0');
  final year = date.year;
  return '$month $day, $year';
}

String orderStatusLabel(String status) {
  return switch (status) {
    'pending' => 'Pending Payment',
    'in_prep' => 'Preparing',
    'ready' => 'Ready',
    'delivered' => 'Delivered',
    'cancelled' => 'Cancelled',
    _ => status,
  };
}

Color orderStatusColor(String status) {
  return switch (status) {
    'pending' => Colors.orange.withValues(alpha: 0.18),
    'delivered' => Colors.green.withValues(alpha: 0.15),
    'cancelled' => Colors.grey.withValues(alpha: 0.15),
    'ready' => Colors.blue.withValues(alpha: 0.15),
    _ => Colors.amber.withValues(alpha: 0.2), // in_prep
  };
}

Color orderStatusTextColor(String status) {
  return switch (status) {
    'pending' => Colors.orange.shade900,
    'delivered' => Colors.green.shade800,
    'cancelled' => Colors.grey.shade700,
    'ready' => Colors.blue.shade800,
    _ => Colors.amber.shade800,
  };
}

String orderTypeLabel(String orderType) {
  return switch (orderType) {
    'dine_in' => 'Dine In',
    'take_away' => 'Take Away',
    'delivery' => 'Delivery',
    _ =>
      orderType
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) {
            if (word.isEmpty) return word;
            return word[0].toUpperCase() + word.substring(1);
          })
          .join(' '),
  };
}
