import 'package:flutter/material.dart';

import 'package:modular_pos/features/inventory/domain/models/inventory_journal_summary.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_journal/inventory_journal_models.dart';
import 'package:modular_pos/features/inventory/ui/view/inventory_journal/widgets/inventory_journal_summary_card.dart';

class InventoryJournalBranchSection extends StatelessWidget {
  const InventoryJournalBranchSection({
    super.key,
    required this.group,
    required this.onOpenSummary,
  });

  final InventoryJournalBranchGroup group;
  final ValueChanged<InventoryJournalDaySummary> onOpenSummary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(group.branchName, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...group.summaries.map(
          (summary) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InventoryJournalSummaryCard(
              summary: summary,
              onOpen: () => onOpenSummary(summary),
            ),
          ),
        ),
      ],
    );
  }
}

