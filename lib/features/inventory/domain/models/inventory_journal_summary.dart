import 'package:equatable/equatable.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';

class InventoryJournalDaySummary extends Equatable {
  const InventoryJournalDaySummary({
    required this.date,
    required this.itemCount,
    required this.activityCount,
    required this.entries,
  });

  final DateTime date;
  final int itemCount;
  final int activityCount;
  final List<InventoryJournalEntry> entries;

  @override
  List<Object?> get props => [date, itemCount, activityCount, entries];
}

// Hot-reload compatibility shim for older references.
class JournalSummary extends InventoryJournalDaySummary {
  const JournalSummary({
    required super.date,
    required super.itemCount,
    required super.activityCount,
    required super.entries,
  });
}
