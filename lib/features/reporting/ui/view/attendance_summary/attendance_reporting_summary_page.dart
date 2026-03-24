import 'package:flutter/material.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_state_views.dart';

class AttendanceReportingSummaryPage extends StatelessWidget {
  const AttendanceReportingSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: ReportingMessageStateView(
          icon: Icons.groups_2_outlined,
          title: 'Attendance Coming Soon',
          message:
              'Attendance reporting is not available yet.',
        ),
      ),
    );
  }
}
