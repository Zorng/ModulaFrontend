import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/ui/components/category_form.dart';

class InventoryCategoryActionMenu extends StatelessWidget {
  const InventoryCategoryActionMenu({
    super.key,
    required this.category,
    this.compact = true,
    this.useDialog = false,
  });

  final InventoryCategory category;
  final bool compact;
  final bool useDialog;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return PopupMenuButton<_CategoryAction>(
        onSelected: (_) => _openView(context),
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: _CategoryAction.view,
            child: Text('View'),
          ),
        ],
        child: const Icon(Icons.more_vert),
      );
    }

    return SizedBox(
      width: 96,
      child: ElevatedButton(
        style: AppTableTheme.actionButtonStyle,
        onPressed: () => _openView(context),
        child: const Text('View'),
      ),
    );
  }

  Future<void> _openView(BuildContext context) async {
    if (useDialog) {
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: CategoryFormBody(
              mode: CategoryFormMode.view,
              category: category,
              showHeader: true,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      );
      return;
    }

    await context.push(AppRoute.inventoryCategoryDetail.path, extra: category);
  }
}

enum _CategoryAction { view }
