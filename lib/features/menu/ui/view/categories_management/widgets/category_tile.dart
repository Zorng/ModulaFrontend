import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/ui/view/categories_management/widgets/menu_category_action_menu.dart';

class CategoryTile extends ConsumerWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.itemCount,
    this.onArchived,
  });

  final MenuCategory category;
  final int itemCount;
  final VoidCallback? onArchived;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isMobile = MediaQuery.of(context).size.width < 1024;
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
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$itemCount item${itemCount == 1 ? '' : 's'}',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (category.description.isNotEmpty) const SizedBox(height: 6),
            if (category.description.isNotEmpty)
              Text(
                category.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: isMobile
            ? Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              )
            : SizedBox(
                width: category.isActive ? 176 : 88,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (category.isActive) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              MenuCategoryActionMenu.archiveCategoryWithConfirm(
                                context,
                                category,
                                onCompleted: onArchived,
                              ),
                          child: const Text('Archive'),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: FilledButton(
                        onPressed: () => MenuCategoryActionMenu.openView(
                          context,
                          category,
                          onArchived: onArchived,
                        ),
                        child: const Text('Edit'),
                      ),
                    ),
                  ],
                ),
              ),
        onTap: () => MenuCategoryActionMenu.openView(
          context,
          category,
          onArchived: onArchived,
        ),
      ),
    );
  }
}

