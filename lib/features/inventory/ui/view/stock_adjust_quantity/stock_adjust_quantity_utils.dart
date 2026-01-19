import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

String pieceLabel(StockItem item) {
  if (item.pieceSize <= 1) return item.baseUnit;
  return '${item.pieceSize} ${item.baseUnit} per piece';
}

int compareBatches(StockBatch a, StockBatch b) {
  final aExpiry = a.expiryDate;
  final bExpiry = b.expiryDate;
  if (aExpiry == null && bExpiry == null) {
    return a.receivedDate.compareTo(b.receivedDate);
  }
  if (aExpiry == null) return 1;
  if (bExpiry == null) return -1;
  final cmp = aExpiry.compareTo(bExpiry);
  return cmp == 0 ? a.receivedDate.compareTo(b.receivedDate) : cmp;
}

