import 'package:flutter/widgets.dart';

class ModifierOptionRowModel {
  ModifierOptionRowModel({
    String? id,
    String? name,
    String? price,
  }) : id = id ?? UniqueKey().toString(),
       nameController = TextEditingController(text: name ?? ''),
       priceController = TextEditingController(text: price ?? '');

  final String id;
  final TextEditingController nameController;
  final TextEditingController priceController;

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}

