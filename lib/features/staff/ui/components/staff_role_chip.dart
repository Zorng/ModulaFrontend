import 'package:flutter/material.dart';
import 'package:modular_pos/features/staff/domain/models/staff_membership_models.dart';

class StaffRoleChip extends StatelessWidget {
  const StaffRoleChip({super.key, required this.roleKey});

  final String roleKey;

  @override
  Widget build(BuildContext context) {
    final color = _colorForRole(roleKey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        formatRoleKey(roleKey),
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }

  Color _colorForRole(String rawRole) {
    switch (rawRole.trim().toUpperCase()) {
      case 'OWNER':
        return Colors.deepPurple.shade700;
      case 'ADMIN':
        return Colors.purple.shade700;
      case 'MANAGER':
        return Colors.blue.shade700;
      case 'CASHIER':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
