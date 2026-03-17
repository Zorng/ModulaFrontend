import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/features/menu/ui/view/categories_management/widgets/menu_category_form_body.dart';

/// A form for creating a new category.
class AddCategoryPage extends StatelessWidget {
  const AddCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Add category'),
        centerTitle: false,
      ),
      body: ColoredBox(
        color: Colors.white,
        child: SingleChildScrollView(
          child: AddCategoryDialogBody(
            onClose: () => context.pop(),
          ),
        ),
      ),
    );
  }
}

class AddCategoryDialogBody extends StatelessWidget {
  const AddCategoryDialogBody({
    super.key,
    this.showHeader = false,
    this.onClose,
  });

  final bool showHeader;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return MenuCategoryFormBody(
      mode: MenuCategoryFormMode.create,
      showHeader: showHeader,
      backgroundColor: Colors.white,
      onClose: onClose ?? () => context.pop(),
    );
  }
}
