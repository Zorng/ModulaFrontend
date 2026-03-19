import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

class ModifierGroupTile extends StatelessWidget {
  const ModifierGroupTile({
    super.key,
    required this.group,
  });

  final ModifierGroup group;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1024;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () {
        context.push(AppRoute.adminMenuViewModifierGroup.path, extra: group);
      },
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${group.options.length} options - ${group.selectionType == 'single' ? 'Single' : 'Multiple'} select',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isMobile)
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                )
              else
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    context.push(
                      AppRoute.adminMenuEditModifierGroup.path,
                      extra: group,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
