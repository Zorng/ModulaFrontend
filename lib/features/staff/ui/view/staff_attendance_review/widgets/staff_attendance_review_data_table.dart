import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/features/staff/domain/models/staff_attendance_review_models.dart';
import 'package:modular_pos/features/staff/ui/components/staff_ui_formatters.dart';

class StaffAttendanceReviewDataTable extends StatelessWidget {
  const StaffAttendanceReviewDataTable({super.key, required this.records});

  final List<StaffAttendanceReviewRecord> records;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: AppTableTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTableTheme.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: DataTable(
                    columnSpacing: 20,
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 72,
                    headingRowColor: WidgetStateProperty.all(
                      AppTableTheme.headerBackground,
                    ),
                    dataRowColor: const WidgetStatePropertyAll(
                      AppTableTheme.background,
                    ),
                    dividerThickness: 1,
                    border: const TableBorder(),
                    columns: const [
                      DataColumn(
                        label: Text('Staff', style: AppTableTheme.headerText),
                      ),
                      DataColumn(
                        label: Text('Branch', style: AppTableTheme.headerText),
                      ),
                      DataColumn(
                        label: Text('Type', style: AppTableTheme.headerText),
                      ),
                      DataColumn(
                        label: Text(
                          'Occurred',
                          style: AppTableTheme.headerText,
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Location',
                          style: AppTableTheme.headerText,
                        ),
                      ),
                    ],
                    rows: records
                        .map(
                          (record) => DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  record.account.displayName,
                                  style: AppTableTheme.cellText,
                                ),
                              ),
                              DataCell(
                                Text(
                                  record.branch.name,
                                  style: AppTableTheme.cellText,
                                ),
                              ),
                              DataCell(
                                Text(
                                  record.typeLabel,
                                  style: AppTableTheme.cellText,
                                ),
                              ),
                              DataCell(
                                Text(
                                  formatStaffDateTime(record.occurredAt),
                                  style: AppTableTheme.cellText,
                                ),
                              ),
                              DataCell(
                                Text(
                                  record.locationVerification?.status ??
                                      'No verification',
                                  style: AppTableTheme.cellText,
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
