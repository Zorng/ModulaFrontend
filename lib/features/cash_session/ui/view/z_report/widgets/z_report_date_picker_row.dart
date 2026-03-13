import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ZReportDatePickerRow extends StatelessWidget {
  const ZReportDatePickerRow({
    super.key,
    required this.date,
    required this.onPick,
    this.label = 'Date',
    this.isFilterApplied = true,
    this.inactiveLabel = 'Any date',
  });

  final DateTime date;
  final ValueChanged<DateTime> onPick;
  final String label;
  final bool isFilterApplied;
  final String inactiveLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked == null) return;
            onPick(picked);
          },
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          label: Text(
            isFilterApplied
                ? DateFormat('yyyy-MM-dd').format(date)
                : inactiveLabel,
          ),
        ),
      ],
    );
  }
}
