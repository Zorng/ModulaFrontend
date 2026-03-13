import 'package:flutter/material.dart';

class TodayShiftCard extends StatelessWidget {
  const TodayShiftCard({
    super.key,
    required this.date,
    required this.shift,
    required this.shiftSource,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    this.nextInstanceDate,
    this.nextInstanceShift,
  });

  final String date;
  final String shift;
  final String shiftSource;
  final String checkIn;
  final String checkOut;
  final String status;
  final String? nextInstanceDate;
  final String? nextInstanceShift;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Shift',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            _Row(label: 'Date', value: date),
            const SizedBox(height: 8),
            _Row(label: 'Shift', value: shift),
            const SizedBox(height: 8),
            _Row(label: 'Source', value: shiftSource),
            if (nextInstanceDate != null && nextInstanceShift != null) ...[
              const SizedBox(height: 8),
              _Row(label: 'Next one-time shift', value: nextInstanceDate!),
              const SizedBox(height: 8),
              _Row(label: 'Next shift time', value: nextInstanceShift!),
            ],
            const SizedBox(height: 8),
            _Row(label: 'Check in', value: checkIn),
            const SizedBox(height: 8),
            _Row(label: 'Check out', value: checkOut),
            const SizedBox(height: 8),
            _Row(label: 'Status', value: status),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
