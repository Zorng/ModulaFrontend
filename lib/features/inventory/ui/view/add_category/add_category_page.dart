import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/ui/components/category_form.dart';

class AddInventoryCategoryPage extends StatelessWidget {
  const AddInventoryCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryFormPage(mode: CategoryFormMode.create);
  }
}

class CategoryFormPage extends StatelessWidget {
  const CategoryFormPage({super.key, required this.mode, this.category})
    : assert(
        mode == CategoryFormMode.create || category != null,
        'category is required for view/edit',
      );

  final CategoryFormMode mode;
  final InventoryCategory? category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(_title()),
        centerTitle: false,
      ),
      body: ColoredBox(
        color: Colors.white,
        child: SingleChildScrollView(
          child: CategoryFormBody(
            mode: mode,
            category: category,
            showHeader: false,
            onClose: () => context.pop(),
          ),
        ),
      ),
    );
  }

  String _title() => switch (mode) {
    CategoryFormMode.create => 'Add category',
    CategoryFormMode.view => 'Category details',
    CategoryFormMode.edit => 'Edit category',
  };
}
