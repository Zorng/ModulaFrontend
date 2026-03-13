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
  final normalized = state.trim().toUpperCase();
  return switch (normalized) {
    'PENDING' => 'Pending',
    'FINALIZED' => 'Finalized',
    'VOID_PENDING' => 'Void Pending',
    'VOIDED' => 'Voided',
    _ => normalized.isEmpty ? state : normalized,
  };
}

Color viewCartsStateColor(String state) {
  final normalized = state.trim().toUpperCase();
  return switch (normalized) {
    'PENDING' => Colors.amber.shade700,
    'FINALIZED' => Colors.green.shade700,
    'VOID_PENDING' => Colors.deepOrange.shade700,
    'VOIDED' => Colors.red.shade700,
    _ => Colors.grey.shade700,
  };
}

String viewCartsPaymentMethodLabel(String paymentMethod) {
  final normalized = paymentMethod.trim().toUpperCase();
  return switch (normalized) {
    'KHQR' => 'KHQR',
    'CASH' => 'Cash',
    _ => normalized.isEmpty ? paymentMethod : normalized,
  };
}

String viewCartsTenderCurrencyLabel(String tenderCurrency) {
  final normalized = tenderCurrency.trim().toUpperCase();
  return switch (normalized) {
    'USD' => 'USD',
    'KHR' => 'KHR',
    _ => normalized.isEmpty ? tenderCurrency : normalized,
  };
}

String viewCartsFulfillmentLabel(String fulfillmentStatus) {
  final normalized = fulfillmentStatus.trim().toUpperCase();
  return switch (normalized) {
    'PENDING' => 'Pending',
    'IN_PREP' => 'In Prep',
    'READY' => 'Ready',
    'DELIVERED' => 'Delivered',
    'CANCELLED' => 'Cancelled',
    _ => normalized.isEmpty ? fulfillmentStatus : normalized,
  };
}

String viewCartsFormatUsd(double amount) => '\$${amount.toStringAsFixed(2)}';

String viewCartsFormatKhr(double amount) => '៛${amount.round()}';
