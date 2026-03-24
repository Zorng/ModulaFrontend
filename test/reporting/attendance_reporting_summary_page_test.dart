import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/reporting/ui/view/attendance_summary/attendance_reporting_summary_page.dart';

void main() {
  testWidgets('renders attendance coming soon placeholder', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AttendanceReportingSummaryPage())),
    );

    expect(find.text('Attendance Coming Soon'), findsOneWidget);
    expect(
      find.textContaining('Attendance reporting is not available yet'),
      findsOneWidget,
    );
  });
}
