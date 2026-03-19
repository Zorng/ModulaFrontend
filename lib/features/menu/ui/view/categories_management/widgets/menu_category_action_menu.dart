import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/core/theme/app_theme.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/ui/view/categories_management/widgets/menu_category_form_body.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

class MenuCategoryActionMenu extends ConsumerWidget {
  const MenuCategoryActionMenu({
    super.key,
    required this.category,
    this.compact = true,
    this.useDialog = false,
    this.onArchived,
  });

  final MenuCategory category;
  final bool compact;
  final bool useDialog;
  final VoidCallback? onArchived;

  static Future<void> openView(
    BuildContext context,
    MenuCategory category, {
    bool useDialog = false,
    VoidCallback? onArchived,
  }) async {
    if (useDialog) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            backgroundColor: Theme.of(dialogContext).scaffoldBackgroundColor,
            surfaceTintColor: Theme.of(dialogContext).scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: MenuCategoryFormBody(
                mode: MenuCategoryFormMode.view,
                category: category,
                showHeader: true,
                allowArchiveInViewMode: true,
                backgroundColor: Theme.of(dialogContext).scaffoldBackgroundColor,
                onArchived: onArchived,
                onStatusActionRequested: (target) async {
                  Navigator.of(dialogContext).pop();
                  if (target.isActive) {
                    await archiveCategoryWithConfirm(
                      context,
                      target,
                      onCompleted: onArchived,
                    );
                    return;
                  }
                  final container = ProviderScope.containerOf(
                    context,
                    listen: false,
                  );
                  try {
                    await container
                        .read(menuViewModelProvider.notifier)
                        .restoreCategory(target);
                    if (!context.mounted) return;
                    onArchived?.call();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('"${target.name}" restored')),
                    );
                  } catch (_) {
                    if (!context.mounted) return;
                    final state = container.read(menuViewModelProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.error ?? 'Failed to restore category.',
                        ),
                      ),
                    );
                  }
                },
                onClose: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ),
      );
      return;
    }

    await context.push(AppRoute.adminMenuEditCategory.path, extra: category);
    onArchived?.call();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_MenuCategoryAction>(
      onSelected: (value) {
        switch (value) {
          case _MenuCategoryAction.view:
            openView(
              context,
              category,
              useDialog: useDialog,
              onArchived: onArchived,
            );
            break;
          case _MenuCategoryAction.archive:
            archiveCategoryWithConfirm(
              context,
              category,
              onCompleted: onArchived,
            );
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _MenuCategoryAction.view,
          child: Text('View'),
        ),
        if (category.isActive)
          const PopupMenuItem(
            value: _MenuCategoryAction.archive,
            child: Text('Archive'),
          ),
      ],
      child: Icon(compact ? Icons.more_vert : Icons.more_horiz),
    );
  }

  static Future<void> archiveCategoryWithConfirm(
    BuildContext context,
    MenuCategory category,
    {VoidCallback? onCompleted}
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final background = Theme.of(context).scaffoldBackgroundColor;
        return AlertDialog(
          backgroundColor: background,
          surfaceTintColor: background,
          title: const Text('Archive category?'),
          content: Text(
            '"${category.name}" will be archived and removed from active menu categories.',
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: AppTheme.cancelActionButtonStyle,
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Archive'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    try {
      final container = ProviderScope.containerOf(context, listen: false);
      await container.read(menuViewModelProvider.notifier).deleteCategory(
        category.id,
      );
      if (!context.mounted) return;
      onCompleted?.call();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${category.name}" archived')));
    } catch (_) {
      if (!context.mounted) return;
      final container = ProviderScope.containerOf(context, listen: false);
      final state = container.read(menuViewModelProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Failed to archive category.'),
        ),
      );
    }
  }

}

enum _MenuCategoryAction { view, archive }
