String orderDetailFormatTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String orderDetailOrderTypeLabel(String orderType) {
  return switch (orderType) {
    'dine_in' => 'Dine In',
    'take_away' => 'Take Away',
    'delivery' => 'Delivery',
    _ =>
      orderType
          .replaceAll('_', ' ')
          .split(' ')
          .map(
            (word) => word.isEmpty
                ? word
                : '${word[0].toUpperCase()}${word.substring(1)}',
          )
          .join(' '),
  };
}

String orderDetailStatusLabel(String status) {
  return switch (status) {
    'pending' => 'Pending Payment',
    'in_prep' => 'Preparing',
    'ready' => 'Ready',
    'delivered' => 'Delivered',
    'cancelled' => 'Cancelled',
    _ => status,
  };
}
