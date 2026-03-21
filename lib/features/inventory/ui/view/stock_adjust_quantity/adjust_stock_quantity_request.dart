import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

class AdjustStockQuantityRequest {
  const AdjustStockQuantityRequest({required this.item, this.initialBranchId});

  final StockItem item;
  final String? initialBranchId;
}
