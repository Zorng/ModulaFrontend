import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/ui/view/category_management/widgets/inventory_category_actions.dart';

class InventoryCategoryTile extends ConsumerWidget {
  const InventoryCategoryTile({
    super.key,
    required this.category,
    required this.itemCount,
    this.onArchived,
  });

  final InventoryCategory category;
  final int itemCount;
  final VoidCallback? onArchived;

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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              '$itemCount stock item${itemCount == 1 ? '' : 's'}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (category.description != null &&
                category.description!.isNotEmpty)
              const SizedBox(height: 6),
            if (category.description != null &&
                category.description!.isNotEmpty)
              Text(
                category.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category.isActive ? 'Active' : 'Archived',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: category.isActive ? scheme.primary : scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            InventoryCategoryActionMenu(
              category: category,
              compact: true,
              onArchived: onArchived,
            ),
          ],
        ),
        onTap: () => InventoryCategoryActionMenu.openView(context, category),
      ),
    );
  }
}
