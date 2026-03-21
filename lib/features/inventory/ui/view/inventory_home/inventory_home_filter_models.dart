enum InventoryHomeStockStatusFilter { all, inStock, lowStock, outOfStock }

String inventoryHomeStockStatusFilterLabel(
  InventoryHomeStockStatusFilter filter,
) {
  return switch (filter) {
    InventoryHomeStockStatusFilter.all => 'All statuses',
    InventoryHomeStockStatusFilter.inStock => 'In stock',
    InventoryHomeStockStatusFilter.lowStock => 'Low stock',
    InventoryHomeStockStatusFilter.outOfStock => 'Out of stock',
  };
}

String inventoryHomeStockStatusFilterValue(
  InventoryHomeStockStatusFilter filter,
) {
  return switch (filter) {
    InventoryHomeStockStatusFilter.all => 'all',
    InventoryHomeStockStatusFilter.inStock => 'in_stock',
    InventoryHomeStockStatusFilter.lowStock => 'low_stock',
    InventoryHomeStockStatusFilter.outOfStock => 'out_of_stock',
  };
}

InventoryHomeStockStatusFilter inventoryHomeStockStatusFilterFromValue(
  String raw,
) {
  return switch (raw.trim().toLowerCase()) {
    'in_stock' => InventoryHomeStockStatusFilter.inStock,
    'low_stock' => InventoryHomeStockStatusFilter.lowStock,
    'out_of_stock' => InventoryHomeStockStatusFilter.outOfStock,
    _ => InventoryHomeStockStatusFilter.all,
  };
}

class InventoryHomeFilterDraft {
  const InventoryHomeFilterDraft({
    required this.categoryId,
    required this.branchId,
    required this.stockStatus,
  });

  final String categoryId;
  final String branchId;
  final InventoryHomeStockStatusFilter stockStatus;
}

class InventoryHomeFilterStatusItem {
  const InventoryHomeFilterStatusItem({
    required this.label,
    required this.value,
    this.isEmphasized = false,
  });

  final String label;
  final String value;
  final bool isEmphasized;
}
