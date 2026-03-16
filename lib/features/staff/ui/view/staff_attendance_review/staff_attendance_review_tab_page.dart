import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/staff/ui/view/staff_attendance_review/widgets/staff_attendance_review_card.dart';
import 'package:modular_pos/features/staff/ui/view/staff_attendance_review/widgets/staff_attendance_review_data_table.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_attendance_review_controller.dart';

class StaffAttendanceReviewTabPage extends ConsumerWidget {
  const StaffAttendanceReviewTabPage({super.key});

  static const double _rangeModalMaxWidth = 560;
  static const double _rangeModalMaxHeight = 680;
  static const double _topControlHeight = 56;

  static const MenuStyle _whiteDropdownMenuStyle = MenuStyle(
    backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
    surfaceTintColor: WidgetStatePropertyAll<Color>(Colors.white),
  );

  static const InputDecorationTheme _topDropdownDecorationTheme =
      InputDecorationTheme(
        hintStyle: TextStyle(fontSize: 14),
        constraints: BoxConstraints(
          minHeight: _topControlHeight,
          maxHeight: _topControlHeight,
        ),
        border: OutlineInputBorder(),
      );

  Future<DateTimeRange?> _showSelectRangeModal(
    BuildContext context,
    DateTimeRange initialRange,
  ) {
    final theme = Theme.of(context);
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      initialDateRange: initialRange,
      helpText: 'Select date range',
      saveText: 'Apply',
      cancelText: 'Cancel',
      fieldStartHintText: 'Start date',
      fieldEndHintText: 'End date',
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final pickerTheme = theme.copyWith(
          dialogTheme: theme.dialogTheme.copyWith(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
          ),
          datePickerTheme: theme.datePickerTheme.copyWith(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            rangePickerBackgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
        return Theme(
          data: pickerTheme,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 640;
              if (!isWide) return child;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _rangeModalMaxWidth,
                    maxHeight: _rangeModalMaxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: child,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(staffAttendanceReviewControllerProvider);
    final controller = ref.read(
      staffAttendanceReviewControllerProvider.notifier,
    );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  UserErrorMessage.build(
                    context: 'Failed to load attendance',
                    error: error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: controller.refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (state) {
            final topButtonStyle = FilledButton.styleFrom(
              minimumSize: const Size(0, _topControlHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            );

            return ListView(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final menuWidth =
                        (constraints.maxWidth - 16 - _topControlHeight) / 2;

                    final branchMenu = DropdownMenu<String?>(
                      width: menuWidth,
                      requestFocusOnTap: false,
                      initialSelection: state.selectedBranchId,
                      label: const Text('Branch'),
                      inputDecorationTheme: _topDropdownDecorationTheme,
                      menuStyle: _whiteDropdownMenuStyle,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onSelected: controller.setBranchId,
                      dropdownMenuEntries: [
                        const DropdownMenuEntry<String?>(
                          value: null,
                          label: 'All branches',
                        ),
                        ...state.branches.map(
                          (branch) => DropdownMenuEntry<String?>(
                            value: branch.branchId,
                            label: branch.branchName,
                          ),
                        ),
                      ],
                    );

                    final staffMenu = DropdownMenu<String?>(
                      width: menuWidth,
                      requestFocusOnTap: false,
                      initialSelection: state.selectedAccountId,
                      label: const Text('Staff'),
                      inputDecorationTheme: _topDropdownDecorationTheme,
                      menuStyle: _whiteDropdownMenuStyle,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onSelected: controller.setAccountId,
                      dropdownMenuEntries: [
                        const DropdownMenuEntry<String?>(
                          value: null,
                          label: 'All staff',
                        ),
                        ...state.accounts.map(
                          (membership) => DropdownMenuEntry<String?>(
                            value: membership.accountId,
                            label: membership.displayName,
                          ),
                        ),
                      ],
                    );

                    final dateRangeBtn = FilledButton.tonalIcon(
                      style: topButtonStyle,
                      onPressed: () async {
                        final picked = await _showSelectRangeModal(
                          context,
                          state.selectedDateRange,
                        );
                        if (picked != null) {
                          await controller.setDateRange(picked);
                        }
                      },
                      icon: const Icon(Icons.date_range_outlined),
                      label: const Text('Date range'),
                    );

                    final refreshBtn = Tooltip(
                      message: 'Refresh',
                      child: IconButton.filledTonal(
                        onPressed: state.isRefreshing
                            ? null
                            : controller.refresh,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(
                            _topControlHeight,
                            _topControlHeight,
                          ),
                          maximumSize: const Size(
                            _topControlHeight,
                            _topControlHeight,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: state.isRefreshing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh),
                      ),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: dateRangeBtn),
                            const SizedBox(width: 8),
                            refreshBtn,
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            branchMenu,
                            const SizedBox(width: 8),
                            staffMenu,
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Clear filters',
                              onPressed: state.selectedBranchId != null ||
                                      state.selectedAccountId != null
                                  ? controller.clearFilters
                                  : null,
                              style: IconButton.styleFrom(
                                minimumSize: const Size(
                                  _topControlHeight,
                                  _topControlHeight,
                                ),
                                maximumSize: const Size(
                                  _topControlHeight,
                                  _topControlHeight,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.filter_alt_off_outlined),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                if (state.inlineError != null)
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        UserErrorMessage.build(error: state.inlineError),
                      ),
                    ),
                  ),
                if (state.inlineError != null) const SizedBox(height: 12),
                if (state.records.isEmpty)
                  const Card(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No attendance records match the selected filters.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = AppBreakpoints.isLarge(
                        MediaQuery.of(context).size.width,
                      );
                      if (isWide) {
                        return StaffAttendanceReviewDataTable(
                          records: state.records,
                        );
                      }
                      return Column(
                        children: [
                          for (final record in state.records)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: StaffAttendanceReviewCard(record: record),
                            ),
                        ],
                      );
                    },
                  ),
                if (state.records.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.center,
                    child: OutlinedButton(
                      onPressed: state.canLoadMore && !state.isLoadingMore
                          ? controller.loadMore
                          : null,
                      child: state.isLoadingMore
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              state.canLoadMore
                                  ? 'Load more'
                                  : 'All records loaded',
                            ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
