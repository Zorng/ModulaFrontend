import 'package:flutter/material.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_section_card.dart';

class ReportingPlaceholderPanelCard extends StatelessWidget {
  const ReportingPlaceholderPanelCard({
    super.key,
    required this.title,
    required this.height,
    this.message = 'Empty',
  });

  final String title;
  final double height;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ReportingSectionCard(
        title: title,
        child: Center(
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ),
      ),
    );
  }
}
