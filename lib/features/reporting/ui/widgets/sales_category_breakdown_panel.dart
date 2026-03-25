import 'package:flutter/material.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';
import 'package:modular_pos/features/reporting/ui/widgets/reporting_section_card.dart';

class SalesCategoryBreakdownPanel extends StatelessWidget {
  const SalesCategoryBreakdownPanel({super.key, required this.categories});

  final List<SalesCategoryBreakdownItem> categories;

  @override
  Widget build(BuildContext context) {
    return const ReportingSectionCard(
      title: 'Category breakdown',
      child: SizedBox.shrink(),
    );
  }
}
