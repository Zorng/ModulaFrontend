import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/display/staff_shift_info_chip.dart';
import 'package:modular_pos/features/staff/domain/models/staff_membership_models.dart';
import 'package:modular_pos/features/staff/ui/components/staff_status_chip.dart';
import 'package:modular_pos/features/staff/ui/components/staff_ui_formatters.dart';

class StaffMembershipListCard extends StatelessWidget {
  const StaffMembershipListCard({
    super.key,
    required this.membership,
    required this.branchNameById,
    required this.onTap,
  });

  final StaffMembershipSummary membership;
  final Map<String, String> branchNameById;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = membership.displayName
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final buttonStyle = FilledButton.styleFrom(
      minimumSize: const Size(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          membership.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatBranchAssignmentSummary(
                            // <-- branch moved here
                            membership.branchIds,
                            branchNameById,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StaffStatusChip.membership(
                    status: membership.membershipStatus,
                  ),
                ],
              ),

              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 14),

              // ── Info chips ────────────────────────────────────────
              Row(
                children: [
                  InfoChip(
                    icon: Icons.person_outline,
                    label: 'Role',
                    value: membership.roleKey,
                  ),
                  const SizedBox(width: 8),
                  InfoChip(
                    icon: Icons.phone_outlined, // <-- phone moved here
                    label: 'Phone',
                    value: membership.phone,
                  ),
                ],
              ),

              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 10),

              // ── Footer ────────────────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    size: 13,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${membership.primaryLifecycleLabel}: ${formatStaffDateTime(membership.primaryLifecycleTimestamp)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: onTap,
                    style: buttonStyle,
                    child: const Text('View'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
