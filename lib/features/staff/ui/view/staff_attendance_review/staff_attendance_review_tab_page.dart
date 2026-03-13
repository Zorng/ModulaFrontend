import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/features/staff/ui/view/staff_attendance_review/widgets/staff_attendance_review_card.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_attendance_review_controller.dart';

class StaffAttendanceReviewTabPage extends ConsumerWidget {
  const StaffAttendanceReviewTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(staffAttendanceReviewControllerProvider);
    final controller = ref.read(staffAttendanceReviewControllerProvider.notifier);

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
          data: (state) => ListView(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 220,
                    child: DropdownMenu<String?>(
                      initialSelection: state.selectedBranchId,
                      label: const Text('Branch'),
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
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownMenu<String?>(
                      initialSelection: state.selectedAccountId,
                      label: const Text('Staff'),
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
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2035),
                        initialDateRange: state.selectedDateRange,
                      );
                      if (picked != null) {
                        await controller.setDateRange(picked);
                      }
                    },
                    icon: const Icon(Icons.date_range_outlined),
                    label: const Text('Date range'),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: state.isRefreshing ? null : controller.refresh,
                    icon: state.isRefreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  ),
                ],
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
                Column(
                  children: [
                    for (final record in state.records)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: StaffAttendanceReviewCard(record: record),
                      ),
                  ],
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
                            state.canLoadMore ? 'Load more' : 'All records loaded',
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
