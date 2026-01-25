import 'package:flutter/widgets.dart';

class ModifierOptionRowModel {
  ModifierOptionRowModel()
      : id = UniqueKey().toString(),
        nameController = TextEditingController(),
        priceController = TextEditingController();

  final String id;
  final TextEditingController nameController;
  final TextEditingController priceController;

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}

