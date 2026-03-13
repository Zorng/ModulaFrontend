enum InventoryStatus { active, archived, unknown }

extension InventoryStatusX on InventoryStatus {
  bool get isActive => this == InventoryStatus.active;

  String get apiValue => switch (this) {
    InventoryStatus.active => 'ACTIVE',
    InventoryStatus.archived => 'ARCHIVED',
    InventoryStatus.unknown => 'UNKNOWN',
  };
}

InventoryStatus inventoryStatusFromRaw(String? raw) {
  switch ((raw ?? '').trim().toUpperCase()) {
    case 'ACTIVE':
      return InventoryStatus.active;
    case 'ARCHIVED':
      return InventoryStatus.archived;
    default:
      return InventoryStatus.unknown;
  }
}
