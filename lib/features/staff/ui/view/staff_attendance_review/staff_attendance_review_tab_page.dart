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
  static const double _dialogMaxWidth = 480;

  static const MenuStyle _whiteDropdownMenuStyle = MenuStyle(
    backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
    surfaceTintColor: WidgetStatePropertyAll<Color>(Colors.white),
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

  Future<void> _openFiltersDialog(
    BuildContext context,
    WidgetRef ref,
    StaffAttendanceReviewState state,
  ) async {
    final controller = ref.read(
      staffAttendanceReviewControllerProvider.notifier,
    );

    String? draftBranchId = state.selectedBranchId;
    String? draftAccountId = state.selectedAccountId;
    DateTimeRange draftDateRange = state.selectedDateRange;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          backgroundColor: Colors.white,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Filters'),
              TextButton(
                onPressed: () => setDialogState(() {
                  draftBranchId = null;
                  draftAccountId = null;
                }),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Clear filter'),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth = constraints.maxWidth;
                final rangeLabelStart = _fmtDate(draftDateRange.start);
                final rangeLabelEnd = _fmtDate(draftDateRange.end);
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Date range ──────────────────────────────────
                      SizedBox(
                        width: fieldWidth,
                        child: InkWell(
                          onTap: () async {
                            final picked = await _showSelectRangeModal(
                              context,
                              draftDateRange,
                            );
                            if (picked != null) {
                              setDialogState(() => draftDateRange = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.date_range_outlined,
                                  size: 20,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Date range',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.grey.shade600,
                                            ),
                                      ),
                                      Text(
                                        '$rangeLabelStart – $rangeLabelEnd',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ── Branch ──────────────────────────────────────
                      DropdownMenu<String?>(
                        key: ValueKey('filter_branch_$draftBranchId'),
                        width: fieldWidth,
                        requestFocusOnTap: true,
                        enableFilter: true,
                        menuHeight: 220,
                        initialSelection: draftBranchId,
                        label: const Text('Branch'),
                        leadingIcon: const Icon(Icons.store_outlined),
                        menuStyle: _whiteDropdownMenuStyle,
                        onSelected: (v) =>
                            setDialogState(() => draftBranchId = v),
                        dropdownMenuEntries: [
                          const DropdownMenuEntry<String?>(
                            value: null,
                            label: 'All branches',
                          ),
                          for (final branch in state.branches)
                            DropdownMenuEntry<String?>(
                              value: branch.branchId,
                              label: branch.branchName,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // ── Staff ────────────────────────────────────────
                      DropdownMenu<String?>(
                        key: ValueKey('filter_staff_$draftAccountId'),
                        width: fieldWidth,
                        requestFocusOnTap: true,
                        enableFilter: true,
                        menuHeight: 220,
                        initialSelection: draftAccountId,
                        label: const Text('Staff'),
                        leadingIcon: const Icon(Icons.person_outline),
                        menuStyle: _whiteDropdownMenuStyle,
                        onSelected: (v) =>
                            setDialogState(() => draftAccountId = v),
                        dropdownMenuEntries: [
                          const DropdownMenuEntry<String?>(
                            value: null,
                            label: 'All staff',
                          ),
                          for (final a in state.accounts)
                            DropdownMenuEntry<String?>(
                              value: a.accountId,
                              label: a.displayName,
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            SizedBox(
              width: double.maxFinite,
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await controller.setFilters(
                          branchId: draftBranchId,
                          accountId: draftAccountId,
                          dateRange: draftDateRange,
                        );
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Builder(
                  builder: (context) {
                    final selectedBranch = state.branches
                        .where((b) => b.branchId == state.selectedBranchId)
                        .firstOrNull;
                    final selectedAccount = state.selectedAccountId == null
                        ? null
                        : state.accounts
                              .where(
                                (a) => a.accountId == state.selectedAccountId,
                              )
                              .firstOrNull;
                    final dateLabel =
                        '${_fmtDate(state.selectedDateRange.start)} – ${_fmtDate(state.selectedDateRange.end)}';

                    return _FilterBar(
                      selectedBranchName: selectedBranch?.branchName,
                      dateLabel: dateLabel,
                      selectedAccountName: selectedAccount?.displayName,
                      hasActiveFilter:
                          state.selectedBranchId != null ||
                          state.selectedAccountId != null,
                      isRefreshing: state.isRefreshing,
                      onOpenFilters: () =>
                          _openFiltersDialog(context, ref, state),
                      onRefresh: state.isRefreshing ? null : controller.refresh,
                    );
                  },
                ),
                const SizedBox(height: 12),
                if (state.inlineError != null) ...[
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        UserErrorMessage.build(error: state.inlineError),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: state.records.isEmpty
                      ? const Card(
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No attendance records match the selected filters.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = AppBreakpoints.isLarge(
                              MediaQuery.of(context).size.width,
                            );
                            if (isWide) {
                              return StaffAttendanceReviewDataTable(
                                records: state.records,
                              );
                            }
                            return ListView(
                              children: [
                                for (final record in state.records)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: StaffAttendanceReviewCard(
                                      record: record,
                                    ),
                                  ),
                                if (state.records.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.center,
                                    child: OutlinedButton(
                                      onPressed:
                                          state.canLoadMore &&
                                              !state.isLoadingMore
                                          ? controller.loadMore
                                          : null,
                                      child: state.isLoadingMore
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
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
                if (state.records.isNotEmpty)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = AppBreakpoints.isLarge(
                        MediaQuery.of(context).size.width,
                      );
                      if (!isWide) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Align(
                          alignment: Alignment.center,
                          child: OutlinedButton(
                            onPressed: state.canLoadMore && !state.isLoadingMore
                                ? controller.loadMore
                                : null,
                            child: state.isLoadingMore
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    state.canLoadMore
                                        ? 'Load more'
                                        : 'All records loaded',
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Filter bar ───────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.dateLabel,
    required this.isRefreshing,
    required this.onOpenFilters,
    required this.hasActiveFilter,
    this.selectedBranchName,
    this.selectedAccountName,
    this.onRefresh,
  });

  final String? selectedBranchName;
  final String dateLabel;
  final String? selectedAccountName;
  final bool isRefreshing;
  final bool hasActiveFilter;
  final VoidCallback onOpenFilters;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Current filter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              // Filter button with active dot
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: onOpenFilters,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Text('Filter'),
                    if (hasActiveFilter)
                      Positioned(
                        top: -3,
                        right: -7,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChipPill(
                        label:
                            'Branch: ${selectedBranchName ?? 'All branches'}',
                      ),
                      const SizedBox(width: 6),
                      _FilterChipPill(label: 'Date: $dateLabel'),
                      const SizedBox(width: 6),
                      _FilterChipPill(
                        label: 'Staff: ${selectedAccountName ?? 'All staff'}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                onPressed: onRefresh,
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  maximumSize: const Size(44, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: isRefreshing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pill-style filter chip ─────────────────────────────────────────────────

class _FilterChipPill extends StatelessWidget {
  const _FilterChipPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Date format helper ─────────────────────────────────────────────────────

String _fmtDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}';
}
