import 'package:flutter/widgets.dart';

class ModifierOptionRowModel {
  ModifierOptionRowModel({
    String? id,
    String? name,
    String? price,
    List<ModifierComponentRowModel>? components,
  }) : id = id ?? UniqueKey().toString(),
       nameController = TextEditingController(text: name ?? ''),
       priceController = TextEditingController(text: price ?? ''),
       components = components ?? <ModifierComponentRowModel>[];

  final String id;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final List<ModifierComponentRowModel> components;

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    for (final component in components) {
      component.dispose();
    }
  }
}

class ModifierComponentRowModel {
  ModifierComponentRowModel({
    String? stockItemId,
    String? quantity,
    this.trackingMode = 'TRACKED',
  }) : id = UniqueKey().toString(),
       quantityController = TextEditingController(text: quantity ?? '') {
    selectedStockItemId = stockItemId;
  }

  final String id;
  String? selectedStockItemId;
  final TextEditingController quantityController;
  final String trackingMode;

  void dispose() {
    quantityController.dispose();
  }
}

