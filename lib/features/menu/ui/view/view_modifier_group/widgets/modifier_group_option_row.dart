import 'package:flutter/material.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

class ModifierGroupOptionRow extends StatelessWidget {
  const ModifierGroupOptionRow({super.key, required this.option});

  final ModifierOption option;

  @override
  Widget build(BuildContext context) {
    return Text(option.name);
  }
}
