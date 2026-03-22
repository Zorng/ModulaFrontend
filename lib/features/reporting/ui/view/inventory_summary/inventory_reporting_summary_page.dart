import 'package:flutter/material.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_section_card.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_state_views.dart';

class InventoryReportingSummaryPage extends StatelessWidget {
  const InventoryReportingSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ReportingSectionCard(
          title: 'Inventory Reporting',
          subtitle:
              'Restock-spend summary is planned for the next reporting UI slice.',
          child: ReportingMessageStateView(
            icon: Icons.bar_chart_outlined,
            title: 'Inventory summary is next',
            message:
                'The route and bottom-navigation tab are in place. The next implementation batch will bind the restock-spend summary and drill-down pages to the reporting repository.',
          ),
        ),
      ],
    );
  }
}
