import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/ui/view/categories_management/widgets/menu_category_form_body.dart';

/// A page for viewing and editing a category.
class EditCategoryPage extends ConsumerWidget {
  const EditCategoryPage({super.key, required this.category});

  final MenuCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageBackground = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: pageBackground,
        centerTitle: false,
        title: const Text('Category details'),
      ),
      body: ColoredBox(
        color: pageBackground,
        child: SingleChildScrollView(
          child: MenuCategoryFormBody(
            mode: MenuCategoryFormMode.view,
            category: category,
            showHeader: false,
            allowArchiveInViewMode: true,
            backgroundColor: pageBackground,
            useThemeCancelButtonStyle: true,
          ),
        ),
      ),
    );
  }
}
