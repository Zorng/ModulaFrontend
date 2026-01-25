import 'package:flutter/material.dart';

import 'package:modular_pos/features/menu/domain/models/menu_category.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.itemCount,
    this.onTap,
  });

  final MenuCategory category;
  final int itemCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = category.isActive;
    final cardColor = isEnabled ? Colors.white : Colors.grey.shade200;

    return InkWell(
      onTap: onTap,
      canRequestFocus: onTap != null,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$itemCount items',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Chip(
                label: Text(isEnabled ? 'Active' : 'Inactive'),
                backgroundColor: isEnabled
                    ? Colors.green.shade100
                    : Colors.grey.shade300,
                side: BorderSide.none,
                labelStyle: TextStyle(
                  color:
                      isEnabled ? Colors.green.shade800 : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

