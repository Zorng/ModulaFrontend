import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/features/staff/domain/models/staff_shift_models.dart';
import 'package:modular_pos/features/staff/ui/components/staff_status_chip.dart';
import 'package:modular_pos/features/staff/ui/components/staff_ui_formatters.dart';

class StaffShiftPatternDataTable extends StatelessWidget {
  const StaffShiftPatternDataTable({
    super.key,
    required this.patterns,
    required this.membershipById,
    required this.onEdit,
    required this.onDeactivate,
  });

  final List<StaffShiftPattern> patterns;
  final Map<String, String> membershipById;
  final ValueChanged<StaffShiftPattern> onEdit;
  final ValueChanged<StaffShiftPattern> onDeactivate;


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
                        label: Text('Days', style: AppTableTheme.headerText),
                      ),
                      DataColumn(
                        label: Text('Time', style: AppTableTheme.headerText),
                      ),
                      DataColumn(
                        label: Text(
                          'Effective',
                          style: AppTableTheme.headerText,
                        ),
                      ),
                      DataColumn(
                        label: Text('Status', style: AppTableTheme.headerText),
                      ),
                      DataColumn(
                        label: Expanded(
                          child: Text(
                            'Actions',
                            style: AppTableTheme.headerText,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                    rows: patterns
                        .map(
                          (pattern) => DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  membershipById[pattern.membershipId] ??
                                      pattern.membershipId,
                                  style: AppTableTheme.cellText,
                                ),
                              ),
                              DataCell(
                                Text(
                                  formatDayOfWeekList(pattern.daysOfWeek),
                                  style: AppTableTheme.cellText,
                                ),
                              ),
                              DataCell(
                                Text(
                                  formatShiftTimeRange(
                                    pattern.plannedStartTime,
                                    pattern.plannedEndTime,
                                  ),
                                  style: AppTableTheme.cellText,
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${formatStaffDate(pattern.effectiveFrom)} → ${formatStaffDate(pattern.effectiveTo)}',
                                  style: AppTableTheme.cellText,
                                ),
                              ),
                              DataCell(
                                StaffStatusChip.shiftPattern(
                                  status: pattern.status,
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Edit',
                                        onPressed: () => onEdit(pattern),
                                        iconSize: 18,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Deactivate',
                                        onPressed: () =>
                                            onDeactivate(pattern),
                                        iconSize: 18,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        color: Theme.of(context).colorScheme.error,
                                        icon: const Icon(Icons.block),
                                      ),
                                    ],
                                  ),
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
