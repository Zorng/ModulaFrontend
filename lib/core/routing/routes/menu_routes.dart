import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/view/add_category/add_category_page.dart';
import 'package:modular_pos/features/menu/ui/view/add_modifier_group/add_modifier_group_page.dart';
import 'package:modular_pos/features/menu/ui/view/categories_management/categories_management_page.dart';
import 'package:modular_pos/features/menu/ui/view/edit_category/edit_category_page.dart';
import 'package:modular_pos/features/menu/ui/view/edit_modifier_group/edit_modifier_group_page.dart';
import 'package:modular_pos/features/menu/ui/view/menu/menu_page.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form/menu_item_form_page.dart';
import 'package:modular_pos/features/menu/ui/view/menu_shell/menu_bottom_nav_shell_page.dart';
import 'package:modular_pos/features/menu/ui/view/modifiers_management/modifiers_management_page.dart';
import 'package:modular_pos/features/menu/ui/view/view_menu_item/view_menu_item_page.dart';
import 'package:modular_pos/features/menu/ui/view/view_modifier_group/view_modifier_group_page.dart';

List<RouteBase> buildMenuRoutes() {
  return [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MenuBottomNavShellPage(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.adminMenu.path,
              name: AppRoute.adminMenu.name,
              builder: (context, state) => const MenuPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.adminMenuCategories.path,
              name: AppRoute.adminMenuCategories.name,
              builder: (context, state) => const CategoriesManagementPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.adminMenuModifiers.path,
              name: AppRoute.adminMenuModifiers.name,
              builder: (context, state) => const ModifiersManagementPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoute.adminMenuAddCategory.path,
      name: AppRoute.adminMenuAddCategory.name,
      builder: (context, state) => const AddCategoryPage(),
    ),
    GoRoute(
      path: AppRoute.adminMenuEditCategory.path,
      name: AppRoute.adminMenuEditCategory.name,
      builder: (context, state) {
        final category = state.extra as MenuCategory;
        return EditCategoryPage(category: category);
      },
    ),
    GoRoute(
      path: AppRoute.adminMenuAddModifierGroup.path,
      name: AppRoute.adminMenuAddModifierGroup.name,
      builder: (context, state) => const AddModifierGroupPage(),
    ),
    GoRoute(
      path: AppRoute.adminMenuViewModifierGroup.path,
      name: AppRoute.adminMenuViewModifierGroup.name,
      builder: (context, state) {
        final group = state.extra as ModifierGroup;
        return ViewModifierGroupPage(group: group);
      },
    ),
    GoRoute(
      path: AppRoute.adminMenuEditModifierGroup.path,
      name: AppRoute.adminMenuEditModifierGroup.name,
      builder: (context, state) {
        final group = state.extra as ModifierGroup;
        return EditModifierGroupPage(group: group);
      },
    ),
    GoRoute(
      path: AppRoute.adminMenuItemForm.path,
      name: AppRoute.adminMenuItemForm.name,
      builder: (context, state) {
        final item = state.extra is MenuItem ? state.extra as MenuItem : null;
        return MenuItemFormPage(initialItem: item);
      },
    ),
    GoRoute(
      path: AppRoute.adminMenuViewMenuItem.path,
      name: AppRoute.adminMenuViewMenuItem.name,
      builder: (context, state) {
        final item = state.extra as MenuItem;
        return ViewMenuItemPage(menuItem: item);
      },
    ),
  ];
}
