import 'package:flutter/material.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';

class StaffListCard extends StatelessWidget {
  const StaffListCard({super.key, required this.staffMember, this.onTap});

  final Staff staffMember;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    final String name = staffMember.userName;
    final String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final statusLabel =
        staffMember.status ?? (staffMember.isActive ? 'Active' : 'Inactive');
    final statusColor = _statusColor(statusLabel, context);
    final statusTextColor = _statusTextColor(statusLabel, context);

    return Card(
      color: Colors.white,
      elevation: 2.0,
      shadowColor: Colors.grey.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(staffMember.role ?? 'No Role', style: subtitleStyle),
            const SizedBox(width: 8),
            Text(staffMember.branch ?? 'No Branch', style: subtitleStyle),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statusLabel,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: statusTextColor),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Color _statusColor(String status, BuildContext context) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'invited':
        return Colors.blue;
      case 'disabled':
        return Colors.orange;
      case 'archived':
        return Colors.grey;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color _statusTextColor(String status, BuildContext context) {
    final base = _statusColor(status, context);
    if (base == Colors.grey) return Colors.grey.shade700;
    if (base == Colors.orange) return Colors.orange.shade700;
    if (base == Colors.blue) return Colors.blue.shade700;
    if (base == Colors.green) return Colors.green.shade700;
    return Theme.of(context).colorScheme.primary;
  }
}
