import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/navigation/app_kebab_menu.dart';

class MenuPageActionsMenu extends StatelessWidget {
  const MenuPageActionsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return AppKebabMenu(
      items: [
        KebabMenuItem(
          label: 'Categories Management',
          onTap: () {
            context.push(AppRoute.adminMenuCategories.path);
          },
        ),
        KebabMenuItem(
          label: 'Modifiers Management',
          onTap: () {
            context.push(AppRoute.adminMenuModifiers.path);
          },
        ),
      ],
    );
  }
}
