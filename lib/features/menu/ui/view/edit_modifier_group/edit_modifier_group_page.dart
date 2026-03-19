import 'package:flutter/material.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/view/add_modifier_group/add_modifier_group_page.dart';

class EditModifierGroupPage extends StatelessWidget {
  const EditModifierGroupPage({super.key, required this.group});

  final ModifierGroup group;

  @override
  Widget build(BuildContext context) {
    return AddModifierGroupPage(
      initialGroup: group,
      initialMode: ModifierGroupFormMode.edit,
    );
  }
}
