import 'package:equatable/equatable.dart';

enum InventoryJournalReason {
  restock,
  add,
  remove,
  sale,
  voided,
  reopen,
  unknown,
}

extension InventoryJournalReasonLabel on InventoryJournalReason {
  String get label => switch (this) {
    InventoryJournalReason.restock => 'Restock',
    InventoryJournalReason.add => 'Add',
    InventoryJournalReason.remove => 'Remove',
    InventoryJournalReason.sale => 'Sale',
    InventoryJournalReason.voided => 'Void',
    InventoryJournalReason.reopen => 'Reopen',
    InventoryJournalReason.unknown => 'Other',
  };
}

class InventoryJournalEntry extends Equatable {
  const InventoryJournalEntry({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.branchId,
    required this.branchName,
    required this.reason,
    required this.delta,
    required this.note,
    required this.actor,
    required this.timestamp,
  });

  final String id;
  final String itemId;
  final String itemName;
  final String branchId;
  final String branchName;
  final InventoryJournalReason reason;
  final int delta;
  final String note;
  final String actor;
  final DateTime timestamp;

  InventoryJournalEntry copyWith({
    String? id,
    String? itemId,
    String? itemName,
    String? branchId,
    String? branchName,
    InventoryJournalReason? reason,
    int? delta,
    String? note,
    String? actor,
    DateTime? timestamp,
  }) {
    return InventoryJournalEntry(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      reason: reason ?? this.reason,
      delta: delta ?? this.delta,
      note: note ?? this.note,
      actor: actor ?? this.actor,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
    id,
    itemId,
    itemName,
    branchId,
    branchName,
    reason,
    delta,
    note,
    actor,
    timestamp,
  ];
}
