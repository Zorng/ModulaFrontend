import 'package:flutter/material.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';

class StaffListCard extends StatelessWidget {
  const StaffListCard({
    super.key,
    required this.staffMember,
    this.onTap,
  });

  final Staff staffMember;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    final String name = staffMember.userName;
    final String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Card(
      color: Colors.white,
      elevation: 2.0,
      shadowColor: Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            firstLetter,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
        title: Text(
          name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Row(
          children: [
            Text(
              staffMember.role ?? 'No Role',
              style: subtitleStyle,
            ),
            const SizedBox(width: 8),
            Text(
              staffMember.branch ?? 'No Branch',
              style: subtitleStyle,
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: staffMember.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            staffMember.isActive ? 'Active' : 'Inactive',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: staffMember.isActive ? Colors.green.shade700 : Colors.red.shade700,
                ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}