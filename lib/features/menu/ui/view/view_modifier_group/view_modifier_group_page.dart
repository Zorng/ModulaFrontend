import 'package:flutter/material.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/view/add_modifier_group/add_modifier_group_page.dart';

class ViewModifierGroupPage extends StatelessWidget {
  const ViewModifierGroupPage({
    super.key,
    required this.group,
    this.showBack = true,
  });

  final ModifierGroup group;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return AddModifierGroupPage(
      initialGroup: group,
      initialMode: ModifierGroupFormMode.view,
    );
  }
}
