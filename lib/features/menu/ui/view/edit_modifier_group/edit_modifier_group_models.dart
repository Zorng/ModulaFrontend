import 'package:flutter/widgets.dart';

class EditModifierOptionRowModel {
  EditModifierOptionRowModel({
    String? id,
    String? name,
    double? price,
  })  : id = id ?? UniqueKey().toString(),
        nameController = TextEditingController(text: name),
        priceController =
            TextEditingController(text: price?.toStringAsFixed(2) ?? '');

  final String id;
  final TextEditingController nameController;
  final TextEditingController priceController;

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}

