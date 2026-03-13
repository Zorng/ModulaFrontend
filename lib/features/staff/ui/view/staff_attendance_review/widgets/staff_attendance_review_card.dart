import 'package:flutter/material.dart';
import 'package:modular_pos/features/staff/domain/models/staff_attendance_review_models.dart';
import 'package:modular_pos/features/staff/ui/components/staff_ui_formatters.dart';

class StaffAttendanceReviewCard extends StatelessWidget {
  const StaffAttendanceReviewCard({super.key, required this.record});

  final StaffAttendanceReviewRecord record;

  @override
  Widget build(BuildContext context) {
    final verification = record.locationVerification;
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Type', record.typeLabel),
            _row('Staff', record.account.displayName),
            _row('Phone', record.account.phone),
            _row('Branch', record.branch.name),
            _row('Occurred', formatStaffDateTime(record.occurredAt)),
            _row('Created', formatStaffDateTime(record.createdAt)),
            _row('Location', verification?.status ?? 'No verification'),
            if ((verification?.reason ?? '').trim().isNotEmpty)
              _row('Reason', verification!.reason!.trim()),
            if (verification?.distanceMeters != null)
              _row(
                'Distance',
                '${verification!.distanceMeters!.toStringAsFixed(2)} m',
              ),
            if ((record.forceEndReason ?? '').trim().isNotEmpty)
              _row('Force end', record.forceEndReason!.trim()),
            if ((record.forceEndedByAccountId ?? '').trim().isNotEmpty)
              _row('Ended by', record.forceEndedByAccountId!.trim()),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
