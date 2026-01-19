import 'package:flutter/material.dart';

import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/view/edit_modifier_group/edit_modifier_group_page.dart';
import 'package:modular_pos/features/menu/ui/view/view_modifier_group/view_modifier_group_page.dart';

class ModifierGroupTile extends StatelessWidget {
  const ModifierGroupTile({
    super.key,
    required this.group,
  });

  final ModifierGroup group;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewModifierGroupPage(group: group),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${group.options.length} options • ${group.selectionType == 'single' ? 'Single' : 'Multiple'} select',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditModifierGroupPage(group: group),
                    ),
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
