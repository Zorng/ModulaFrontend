import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/features/menu/ui/view/categories_management/widgets/menu_category_form_body.dart';

/// A form for creating a new category.
class AddCategoryPage extends StatelessWidget {
  const AddCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pageBackground = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: pageBackground,
        title: const Text('Add category'),
        centerTitle: false,
      ),
      body: ColoredBox(
        color: pageBackground,
        child: SingleChildScrollView(
          child: AddCategoryDialogBody(
            backgroundColor: pageBackground,
            useThemeCancelButtonStyle: true,
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
    this.backgroundColor = Colors.white,
    this.useThemeCancelButtonStyle = false,
    this.onClose,
  });

  final bool showHeader;
  final Color backgroundColor;
  final bool useThemeCancelButtonStyle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return MenuCategoryFormBody(
      mode: MenuCategoryFormMode.create,
      showHeader: showHeader,
      backgroundColor: backgroundColor,
      useThemeCancelButtonStyle: useThemeCancelButtonStyle,
      onClose: onClose ?? () => context.pop(),
    );
  }
}
