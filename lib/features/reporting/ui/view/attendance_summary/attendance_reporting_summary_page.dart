import 'package:flutter/material.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_section_card.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_state_views.dart';

class AttendanceReportingSummaryPage extends StatelessWidget {
  const AttendanceReportingSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ReportingSectionCard(
          title: 'Attendance Reporting',
          subtitle: 'Current backend state for `/v0/reports/attendance/*`.',
          child: ReportingMessageStateView(
            icon: Icons.info_outline,
            title: 'Attendance reporting is unavailable',
            message:
                'The current backend contract returns `REPORT_NOT_AVAILABLE` for attendance reporting. This tab stays visible so the final shell and access flow are in place, but the data-driven UI will be enabled when backend support is ready.',
          ),
        ),
      ],
    );
  }
}
