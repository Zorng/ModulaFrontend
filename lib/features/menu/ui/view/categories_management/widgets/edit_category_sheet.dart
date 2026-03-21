import 'package:flutter/material.dart';

import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/ui/view/categories_management/widgets/menu_category_form_body.dart';

class EditCategorySheet extends StatelessWidget {
  const EditCategorySheet({
    super.key,
    required this.category,
    this.startInEdit = false,
  });

  final MenuCategory category;
  final bool startInEdit;

  @override
  Widget build(BuildContext context) {
    return MenuCategoryFormBody(
      mode: startInEdit ? MenuCategoryFormMode.edit : MenuCategoryFormMode.view,
      category: category,
      showHeader: true,
      allowArchiveInViewMode: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      onClose: () => Navigator.of(context).pop(),
    );
  }
}
