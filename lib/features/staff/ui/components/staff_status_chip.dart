import 'package:flutter/material.dart';
import 'package:modular_pos/features/staff/domain/models/staff_membership_models.dart';
import 'package:modular_pos/features/staff/domain/models/staff_shift_models.dart';

class StaffStatusChip extends StatelessWidget {
  StaffStatusChip.membership({
    super.key,
    required MembershipLifecycleStatus status,
  }) : _label = formatMembershipLifecycleStatus(status),
       _color = _membershipColor(status);

  StaffStatusChip.shiftPattern({
    super.key,
    required StaffShiftPatternStatus status,
  }) : _label = _formatPatternStatus(status),
       _color = _patternColor(status);

  StaffStatusChip.shiftInstance({
    super.key,
    required StaffShiftInstanceStatus status,
  }) : _label = _formatInstanceStatus(status),
       _color = _instanceColor(status);

  final String _label;
  final Color _color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: _color),
      ),
    );
  }

  static Color _membershipColor(MembershipLifecycleStatus status) {
    switch (status) {
      case MembershipLifecycleStatus.invited:
        return Colors.blue.shade700;
      case MembershipLifecycleStatus.active:
        return Colors.green.shade700;
      case MembershipLifecycleStatus.revoked:
        return Colors.red.shade700;
      case MembershipLifecycleStatus.unknown:
        return Colors.grey.shade700;
    }
  }

  static String _formatPatternStatus(StaffShiftPatternStatus status) {
    switch (status) {
      case StaffShiftPatternStatus.active:
        return 'Active';
      case StaffShiftPatternStatus.inactive:
        return 'Inactive';
      case StaffShiftPatternStatus.unknown:
        return 'Unknown';
    }
  }

  static Color _patternColor(StaffShiftPatternStatus status) {
    switch (status) {
      case StaffShiftPatternStatus.active:
        return Colors.green.shade700;
      case StaffShiftPatternStatus.inactive:
        return Colors.grey.shade700;
      case StaffShiftPatternStatus.unknown:
        return Colors.grey.shade600;
    }
  }

  static String _formatInstanceStatus(StaffShiftInstanceStatus status) {
    switch (status) {
      case StaffShiftInstanceStatus.planned:
        return 'Planned';
      case StaffShiftInstanceStatus.updated:
        return 'Updated';
      case StaffShiftInstanceStatus.cancelled:
        return 'Cancelled';
      case StaffShiftInstanceStatus.unknown:
        return 'Unknown';
    }
  }

  static Color _instanceColor(StaffShiftInstanceStatus status) {
    switch (status) {
      case StaffShiftInstanceStatus.planned:
        return Colors.blue.shade700;
      case StaffShiftInstanceStatus.updated:
        return Colors.orange.shade700;
      case StaffShiftInstanceStatus.cancelled:
        return Colors.red.shade700;
      case StaffShiftInstanceStatus.unknown:
        return Colors.grey.shade600;
    }
  }
}
