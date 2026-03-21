import 'package:flutter/material.dart';
import 'package:modular_pos/features/staff/domain/models/staff_attendance_review_models.dart';
import 'package:modular_pos/features/staff/ui/components/staff_ui_formatters.dart';

class StaffAttendanceReviewCard extends StatelessWidget {
  const StaffAttendanceReviewCard({super.key, required this.record});

  final StaffAttendanceReviewRecord record;

  static const _avatarSize = 44.0;

  Color _typeColor(BuildContext context) {
    // Adjust based on your actual type values
    return switch (record.typeLabel.toLowerCase()) {
      'check in' => Colors.green.shade600,
      'check out' => Colors.orange.shade700,
      _ => Theme.of(context).colorScheme.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = _typeColor(context);
    final verification = record.locationVerification;
    final initials = record.account.displayName
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: _avatarSize,
                  height: _avatarSize,
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
                // Name + branch
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.account.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.branch.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    record.typeLabel,
                    style: TextStyle(
                      color: typeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 14),

            // ── Time info ────────────────────────────────────────────
            Row(
              children: [
                _infoChip(
                  context,
                  icon: Icons.access_time_outlined,
                  label: 'Occurred',
                  value: formatStaffDateTime(record.occurredAt),
                ),
                const SizedBox(width: 8),
                _infoChip(
                  context,
                  icon: Icons.add_circle_outline,
                  label: 'Created',
                  value: formatStaffDateTime(record.createdAt),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Location row ─────────────────────────────────────────
            _locationRow(context, verification),

            // ── Conditional fields ───────────────────────────────────
            if ((verification?.reason ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _detailRow(
                context,
                Icons.info_outline,
                'Reason',
                verification!.reason!.trim(),
              ),
            ],
            if ((record.forceEndReason ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _detailRow(
                context,
                Icons.warning_amber_outlined,
                'Force end',
                record.forceEndReason!.trim(),
                valueColor: Colors.orange.shade700,
              ),
            ],
            if ((record.forceEndedByAccountId ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _detailRow(
                context,
                Icons.person_outline,
                'Ended by',
                record.forceEndedByAccountId!.trim(),
              ),
            ],

            // ── Phone (subtle, bottom) ───────────────────────────────
            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 6),
                Text(
                  record.account.phone,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationRow(BuildContext context, dynamic verification) {
    final theme = Theme.of(context);
    final status = verification?.status ?? 'No verification';
    final distance = verification?.distanceMeters;

    Color statusColor = Colors.grey.shade500;
    IconData statusIcon = Icons.location_off_outlined;
    if (verification != null) {
      statusColor = Colors.green.shade600;
      statusIcon = Icons.location_on_outlined;
    }

    return Row(
      children: [
        Icon(statusIcon, size: 16, color: statusColor),
        const SizedBox(width: 6),
        Text(
          status,
          style: theme.textTheme.bodySmall?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (distance != null) ...[
          const SizedBox(width: 8),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.straighten_outlined,
            size: 14,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 4),
          Text(
            '${distance.toStringAsFixed(2)} m',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _detailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
