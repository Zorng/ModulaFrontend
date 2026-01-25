import 'package:flutter/material.dart';
import 'package:modular_pos/features/sale/ui/view/order/order_utils.dart';

class OrderFiltersBar extends StatelessWidget {
  const OrderFiltersBar({
    super.key,
    required this.selectedDate,
    required this.onPickDate,
    required this.statuses,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  final DateTime selectedDate;
  final VoidCallback onPickDate;
  final List<String> statuses;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: onPickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(formatOrderDate(selectedDate)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: statuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = statuses[index];
                return ChoiceChip(
                  label: Text(orderStatusLabel(status)),
                  selected: selectedStatus == status,
                  onSelected: (_) => onStatusChanged(status),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
