import 'package:flutter/material.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/components/stock_item_form.dart';

class StockItemDetailPage extends StatelessWidget {
  const StockItemDetailPage({
    super.key,
    required this.item,
  });

  final StockItem item;

  @override
  Widget build(BuildContext context) {
    return StockItemFormPage(mode: StockItemFormMode.view, item: item);
  }
}
