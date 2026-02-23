import 'package:flutter/material.dart';

class StaffAttendanceKeyValueRow extends StatelessWidget {
  const StaffAttendanceKeyValueRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        Expanded(child: Text(value, textAlign: TextAlign.end)),
      ],
    );
  }
}
