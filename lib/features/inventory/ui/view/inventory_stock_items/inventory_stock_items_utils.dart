import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

String pieceLabel(StockItem item) {
  if (item.pieceSize <= 1) return item.baseUnit;
  return '${item.pieceSize} ${item.baseUnit} per piece';
}

String categoryLabel(StockItem item, Map<String, String> categoryLookup) {
  if (item.categoryId != null && item.categoryId!.isNotEmpty) {
    final label = categoryLookup[item.categoryId!];
    if (label != null && label.isNotEmpty) return label;
  }
  return 'Uncategorized';
}
