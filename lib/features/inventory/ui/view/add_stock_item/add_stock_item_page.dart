import 'package:flutter/material.dart';
import 'package:modular_pos/features/inventory/ui/components/stock_item_form.dart';

class AddStockItemPage extends StatelessWidget {
  const AddStockItemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const StockItemFormPage(mode: StockItemFormMode.create);
  }
}
