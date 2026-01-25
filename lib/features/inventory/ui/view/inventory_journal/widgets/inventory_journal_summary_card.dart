import 'package:flutter/material.dart';

import 'package:modular_pos/features/inventory/domain/models/inventory_journal_summary.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_journal/inventory_journal_utils.dart';

class InventoryJournalSummaryCard extends StatelessWidget {
  const InventoryJournalSummaryCard({
    super.key,
    required this.summary,
    required this.onOpen,
  });

  final InventoryJournalDaySummary summary;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          formatYyyyMmDd(summary.date),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${summary.itemCount} item${summary.itemCount == 1 ? '' : 's'} modified · '
            '${summary.activityCount} activit${summary.activityCount == 1 ? 'y' : 'ies'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onOpen,
      ),
    );
  }
}

