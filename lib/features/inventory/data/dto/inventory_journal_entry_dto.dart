class InventoryJournalEntryDto {
  const InventoryJournalEntryDto({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.stockItemId,
    required this.stockItemName,
    required this.reason,
    required this.delta,
    required this.note,
    required this.actorId,
    required this.actorName,
    required this.createdAt,
    required this.occurredAt,
  });

  final String id;
  final String branchId;
  final String branchName;
  final String stockItemId;
  final String stockItemName;
  final String reason;
  final int delta;
  final String note;
  final String actorId;
  final String actorName;
  final DateTime createdAt;
  final DateTime occurredAt;

  factory InventoryJournalEntryDto.fromJson(Map<String, dynamic> json) {
    final reason = (json['reason'] ?? json['type'] ?? '').toString();
    final deltaRaw =
        json['delta'] ?? json['qty'] ?? json['quantity'] ?? json['qtyDeducted'] ?? 0;
    final createdAtRaw = json['createdAt'] ??
        json['created_at'] ??
        json['timestamp'] ??
        DateTime.now().toIso8601String();
    final occurredRaw = json['occurredAt'] ?? json['occurred_at'];
    final createdAt = _asDateTime(createdAtRaw) ?? DateTime.now().toUtc();
    final occurredAt = occurredRaw != null
        ? (_asDateTime(occurredRaw) ?? createdAt)
        : createdAt;
    return InventoryJournalEntryDto(
      id: json['id']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
      stockItemId:
          json['stockItemId']?.toString() ?? json['itemId']?.toString() ?? '',
      stockItemName:
          json['stockItemName']?.toString() ?? json['itemName']?.toString() ?? 'Item',
      reason: reason,
      delta: _asInt(deltaRaw) ?? 0,
      note: json['note']?.toString() ?? '',
      actorId:
          json['actorId']?.toString() ?? json['createdBy']?.toString() ?? '',
      actorName:
          json['actor']?.toString() ??
          json['createdBy']?.toString() ??
          json['userName']?.toString() ??
          '',
      createdAt: createdAt,
      occurredAt: occurredAt,
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toUtc();
}

