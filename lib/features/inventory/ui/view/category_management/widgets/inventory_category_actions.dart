import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/ui/components/category_form.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';

class InventoryCategoryActionMenu extends ConsumerWidget {
  const InventoryCategoryActionMenu({
    super.key,
    required this.category,
    this.compact = true,
    this.useDialog = false,
    this.onArchived,
  });

  final InventoryCategory category;
  final bool compact;
  final bool useDialog;
  final VoidCallback? onArchived;

  static Future<void> openView(
    BuildContext context,
    InventoryCategory category, {
    bool useDialog = false,
    VoidCallback? onArchived,
  }) async {
    if (useDialog) {
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: CategoryFormBody(
              mode: CategoryFormMode.view,
              category: category,
              showHeader: true,
              allowArchiveInViewMode: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              onArchived: onArchived,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      );
      return;
    }

    await context.push(AppRoute.inventoryCategoryDetail.path, extra: category);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_CategoryAction>(
      onSelected: (value) {
        switch (value) {
          case _CategoryAction.view:
            openView(
              context,
              category,
              useDialog: useDialog,
              onArchived: onArchived,
            );
            break;
          case _CategoryAction.archive:
            _archiveCategory(context, ref);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: _CategoryAction.view, child: Text('View')),
        if (category.isActive)
          const PopupMenuItem(
            value: _CategoryAction.archive,
            child: Text('Archive'),
          ),
      ],
      child: Icon(compact ? Icons.more_vert : Icons.more_horiz),
    );
  }

  Future<void> _archiveCategory(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive category?'),
        content: Text(
          '"${category.name}" will be archived and detached from stock items.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref
          .read(categoryControllerProvider.notifier)
          .deleteCategory(category.id);
      if (!context.mounted) return;
      onArchived?.call();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${category.name}" archived')));
    } catch (e) {
      if (!context.mounted) return;
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to archive category.',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapped.message)));
    }
  }
}

enum _CategoryAction { view, archive }
