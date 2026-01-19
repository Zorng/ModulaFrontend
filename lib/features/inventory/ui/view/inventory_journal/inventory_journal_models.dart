import 'package:modular_pos/features/inventory/domain/models/inventory_journal_summary.dart';

class InventoryJournalBranchGroup {
  const InventoryJournalBranchGroup({
    required this.branchId,
    required this.branchName,
    required this.summaries,
  });

  final String branchId;
  final String branchName;
  final List<InventoryJournalDaySummary> summaries;
}

