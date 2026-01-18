import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/navigation/app_kebab_menu.dart';
import 'package:modular_pos/features/menu/ui/view/categories_management_page.dart';
import 'package:modular_pos/features/menu/ui/view/modifiers_management_page.dart';

class MenuPageActionsMenu extends StatelessWidget {
  const MenuPageActionsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return AppKebabMenu(
      items: [
        KebabMenuItem(
          label: 'Categories Management',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CategoriesManagementPage(),
              ),
            );
          },
        ),
        KebabMenuItem(
          label: 'Modifiers Management',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ModifiersManagementPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}
