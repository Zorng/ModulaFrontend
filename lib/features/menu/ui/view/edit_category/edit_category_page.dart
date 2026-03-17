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
    return Scaffold(
      appBar: AppBar(centerTitle: false, title: const Text('Category details')),
      body: ColoredBox(
        color: Colors.white,
        child: SingleChildScrollView(
          child: MenuCategoryFormBody(
          mode: MenuCategoryFormMode.view,
          category: category,
          showHeader: false,
          allowArchiveInViewMode: false,
          backgroundColor: Colors.white,
        ),
        ),
      ),
    );
  }
}
