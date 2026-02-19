import 'package:flutter/material.dart';

class ShiftInfoCard extends StatelessWidget {
  const ShiftInfoCard({
    super.key,
    required this.schedule,
    required this.expanded,
    required this.loading,
    required this.onToggle,
  });

  final List<Map<String, String>> schedule;
  final bool expanded;
  final bool loading;
  final VoidCallback onToggle;

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
            Row(
              children: [
                Text('Shift Info', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onToggle,
                  icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ),
              ],
            ),
            if (expanded)
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                const SizedBox(height: 12),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(0.9),
                    1: FlexColumnWidth(1.1),
                  },
                  children: [
                    TableRow(
                      children: [
                        Text(
                          'Day',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Shifts',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    ...schedule.map(
                      (row) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(row['day'] ?? ''),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(row['shift'] ?? ''),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
          ],
        ),
      ),
    );
  }
}

