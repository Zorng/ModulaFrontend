import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_controller.dart';

class InventoryCategoryTile extends ConsumerWidget {
  const InventoryCategoryTile({
    super.key,
    required this.category,
    required this.itemCount,
  });

  final InventoryCategory category;
  final int itemCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 3,
      color: Colors.white,
      shadowColor: scheme.shadow.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.name,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              '$itemCount stock item${itemCount == 1 ? '' : 's'}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category.isActive ? 'Active' : 'Inactive',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: category.isActive ? scheme.primary : scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<_CategoryAction>(
              onSelected: (action) {
                switch (action) {
                  case _CategoryAction.rename:
                    _showRenameDialog(context, ref);
                    break;
                  case _CategoryAction.toggle:
                    ref
                        .read(categoryControllerProvider.notifier)
                        .updateCategory(
                          category.copyWith(isActive: !category.isActive),
                        );
                    break;
                  case _CategoryAction.delete:
                    ref
                        .read(categoryControllerProvider.notifier)
                        .deleteCategory(category.id);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _CategoryAction.rename,
                  child: Text('Rename'),
                ),
                PopupMenuItem(
                  value: _CategoryAction.toggle,
                  child: Text(category.isActive ? 'Deactivate' : 'Activate'),
                ),
                const PopupMenuItem(
                  value: _CategoryAction.delete,
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: category.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename category'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Category name'),
          autofocus: true,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor:
                          Theme.of(context).textTheme.bodyLarge?.color,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      final value = ctrl.text.trim();
                      if (value.isEmpty) return;
                      context.pop(value);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (result != null) {
      ref
          .read(categoryControllerProvider.notifier)
          .updateCategory(category.copyWith(name: result));
    }
  }
}

enum _CategoryAction { rename, toggle, delete }
