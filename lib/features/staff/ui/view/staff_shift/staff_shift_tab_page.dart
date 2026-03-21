import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/staff/domain/models/staff_shift_models.dart';
import 'package:modular_pos/features/staff/ui/view/staff_shift/widgets/staff_shift_instance_card.dart';
import 'package:modular_pos/features/staff/ui/view/staff_shift/widgets/staff_shift_instance_data_table.dart';
import 'package:modular_pos/features/staff/ui/view/staff_shift/widgets/staff_shift_pattern_card.dart';
import 'package:modular_pos/features/staff/ui/view/staff_shift/widgets/staff_shift_pattern_data_table.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_shift_controller.dart';

class StaffShiftTabPage extends ConsumerStatefulWidget {
  const StaffShiftTabPage({super.key});
  @override
  ConsumerState<StaffShiftTabPage> createState() => _StaffShiftTabPageState();
}

class _StaffShiftTabPageState extends ConsumerState<StaffShiftTabPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const double _dialogMaxWidth = 600;
  static const double _rangeModalMaxWidth = 560;
  static const double _rangeModalMaxHeight = 680;
  // static const double _topControlHeight = 56;

  static const MenuStyle _whiteDropdownMenuStyle = MenuStyle(
    backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
    surfaceTintColor: WidgetStatePropertyAll<Color>(Colors.white),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isPatternsTab => _tabController.index == 0;

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

  Future<DateTime?> _showSelectDateModal(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    final theme = Theme.of(context);
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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
    StaffShiftState state,
  ) async {
    final controller = ref.read(staffShiftControllerProvider.notifier);

    String? draftBranchId = state.selectedBranchId;
    String? draftMembershipId = state.selectedMembershipId;
    DateTimeRange draftDateRange = state.dateRange;

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
                  draftMembershipId = null;
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
          content: _buildDialogContent(
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
                        key: ValueKey('filter_staff_$draftMembershipId'),
                        width: fieldWidth,
                        requestFocusOnTap: true,
                        enableFilter: true,
                        menuHeight: 220,
                        initialSelection: draftMembershipId,
                        label: const Text('Staff'),
                        leadingIcon: const Icon(Icons.person_outline),
                        menuStyle: _whiteDropdownMenuStyle,
                        onSelected: (v) =>
                            setDialogState(() => draftMembershipId = v),
                        dropdownMenuEntries: [
                          const DropdownMenuEntry<String?>(
                            value: null,
                            label: 'All staff',
                          ),
                          for (final m in state.memberships)
                            DropdownMenuEntry<String?>(
                              value: m.membershipId,
                              label: m.displayName,
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
            _buildDialogActions(
              context: context,
              confirmLabel: 'Apply',
              onConfirm: () async {
                Navigator.of(context).pop();
                await controller.setFilters(
                  branchId: draftBranchId,
                  membershipId: draftMembershipId,
                  dateRange: draftDateRange,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(staffShiftControllerProvider);
    final controller = ref.read(staffShiftControllerProvider.notifier);

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
                    context: 'Failed to load shift data',
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
            final membershipById = {
              for (final membership in state.memberships)
                membership.membershipId: membership.displayName,
            };
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Builder(
                  builder: (context) {
                    final selectedBranch = state.branches
                        .where((b) => b.branchId == state.selectedBranchId)
                        .firstOrNull;
                    final selectedMembership =
                        state.selectedMembershipId == null
                        ? null
                        : state.memberships
                              .where(
                                (m) =>
                                    m.membershipId ==
                                    state.selectedMembershipId,
                              )
                              .firstOrNull;
                    final dateLabel =
                        '${_fmtDate(state.dateRange.start)} – ${_fmtDate(state.dateRange.end)}';

                    return _FilterBar(
                      selectedBranchName: selectedBranch?.branchName,
                      dateLabel: dateLabel,
                      selectedMembershipName: selectedMembership?.displayName,
                      hasActiveFilter: state.selectedMembershipId != null,
                      isSaving: state.isSaving,
                      isRefreshing: state.isRefreshing,
                      isPatternsTab: _isPatternsTab,
                      onOpenFilters: () =>
                          _openFiltersDialog(context, ref, state),
                      onAddPattern:
                          state.selectedBranchId == null || state.isSaving
                          ? null
                          : () => _showPatternDialog(context, ref, state),
                      onAddShift:
                          state.selectedBranchId == null || state.isSaving
                          ? null
                          : () => _showInstanceDialog(context, ref, state),
                      onRefresh: state.isRefreshing ? null : controller.refresh,
                    );
                  },
                ),
                const SizedBox(height: 8),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Patterns'),
                    Tab(text: 'Instances'),
                  ],
                ),
                if (state.inlineError != null) ...[
                  const SizedBox(height: 8),
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        UserErrorMessage.build(error: state.inlineError),
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = AppBreakpoints.isLarge(
                            MediaQuery.of(context).size.width,
                          );
                          if (state.schedule.patterns.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Card(
                                color: Colors.white,
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'No shift patterns for the selected filters.',
                                  ),
                                ),
                              ),
                            );
                          }
                          if (isWide) {
                            return Column(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: StaffShiftPatternDataTable(
                                      patterns: state.schedule.patterns,
                                      membershipById: membershipById,
                                      onEdit: (pattern) => _showPatternDialog(
                                        context,
                                        ref,
                                        state,
                                        pattern: pattern,
                                      ),
                                      onDeactivate: (pattern) =>
                                          _showDeactivatePatternDialog(
                                            context,
                                            ref,
                                            pattern: pattern,
                                          ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: _buildLoadMoreButton(
                                    canLoadMore: state.patternHasMore,
                                    isLoading: state.isLoadingPatternMore,
                                    onPressed: controller.loadMorePatterns,
                                  ),
                                ),
                              ],
                            );
                          }
                          return ListView(
                            padding: const EdgeInsets.only(top: 12),
                            children: [
                              for (final pattern in state.schedule.patterns)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: StaffShiftPatternCard(
                                    pattern: pattern,
                                    membershipLabel:
                                        membershipById[pattern.membershipId] ??
                                        pattern.membershipId,
                                    onEdit: () => _showPatternDialog(
                                      context,
                                      ref,
                                      state,
                                      pattern: pattern,
                                    ),
                                    onDeactivate: () =>
                                        _showDeactivatePatternDialog(
                                          context,
                                          ref,
                                          pattern: pattern,
                                        ),
                                  ),
                                ),
                              if (state.schedule.patterns.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.center,
                                  child: _buildLoadMoreButton(
                                    canLoadMore: state.patternHasMore,
                                    isLoading: state.isLoadingPatternMore,
                                    onPressed: controller.loadMorePatterns,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = AppBreakpoints.isLarge(
                            MediaQuery.of(context).size.width,
                          );
                          if (state.schedule.instances.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Card(
                                color: Colors.white,
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'No shift instances for the selected filters.',
                                  ),
                                ),
                              ),
                            );
                          }
                          if (isWide) {
                            return Column(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: StaffShiftInstanceDataTable(
                                      instances: state.schedule.instances,
                                      membershipById: membershipById,
                                      onEdit: (instance) => _showInstanceDialog(
                                        context,
                                        ref,
                                        state,
                                        instance: instance,
                                      ),
                                      onCancel: (instance) =>
                                          _showCancelInstanceDialog(
                                            context,
                                            ref,
                                            instance: instance,
                                          ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: _buildLoadMoreButton(
                                    canLoadMore: state.instanceHasMore,
                                    isLoading: state.isLoadingInstanceMore,
                                    onPressed: controller.loadMoreInstances,
                                  ),
                                ),
                              ],
                            );
                          }
                          return ListView(
                            padding: const EdgeInsets.only(top: 12),
                            children: [
                              for (final instance in state.schedule.instances)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: StaffShiftInstanceCard(
                                    instance: instance,
                                    membershipLabel:
                                        membershipById[instance.membershipId] ??
                                        instance.membershipId,
                                    onEdit: () => _showInstanceDialog(
                                      context,
                                      ref,
                                      state,
                                      instance: instance,
                                    ),
                                    onCancel: () => _showCancelInstanceDialog(
                                      context,
                                      ref,
                                      instance: instance,
                                    ),
                                  ),
                                ),
                              if (state.schedule.instances.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.center,
                                  child: _buildLoadMoreButton(
                                    canLoadMore: state.instanceHasMore,
                                    isLoading: state.isLoadingInstanceMore,
                                    onPressed: controller.loadMoreInstances,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showPatternDialog(
    BuildContext context,
    WidgetRef ref,
    StaffShiftState state, {
    StaffShiftPattern? pattern,
  }) async {
    final membershipItems = state.memberships;
    String membershipId =
        pattern?.membershipId ??
        state.selectedMembershipId ??
        (membershipItems.isNotEmpty ? membershipItems.first.membershipId : '');
    final selectedDays = pattern?.daysOfWeek.toSet() ?? <int>{1, 2, 3, 4, 5};
    final startController = TextEditingController(
      text: pattern?.plannedStartTime ?? '08:00',
    );
    final endController = TextEditingController(
      text: pattern?.plannedEndTime ?? '17:00',
    );
    final noteController = TextEditingController(text: pattern?.note ?? '');
    DateTime? effectiveFrom = pattern?.effectiveFrom ?? state.dateRange.start;
    DateTime? effectiveTo = pattern?.effectiveTo;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.white,
        title: Text(pattern == null ? 'Add pattern' : 'Edit pattern'),
        content: _buildDialogContent(
          child: StatefulBuilder(
            builder: (context, setDialogState) => LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth = constraints.maxWidth;
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: fieldWidth,
                        child: DropdownMenu<String>(
                          width: fieldWidth,
                          requestFocusOnTap: false,
                          initialSelection: membershipId,
                          menuStyle: _whiteDropdownMenuStyle,
                          label: const Text('Staff'),
                          onSelected: (value) {
                            if (value == null) return;
                            setDialogState(() => membershipId = value);
                          },
                          dropdownMenuEntries: membershipItems
                              .map(
                                (membership) => DropdownMenuEntry<String>(
                                  value: membership.membershipId,
                                  label: membership.displayName,
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: fieldWidth,
                        child: TextField(
                          controller: startController,
                          decoration: const InputDecoration(
                            labelText: 'Start time (HH:mm)',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: fieldWidth,
                        child: TextField(
                          controller: endController,
                          decoration: const InputDecoration(
                            labelText: 'End time (HH:mm)',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: fieldWidth,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(7, (index) {
                            final labels = [
                              'Sun',
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                            ];
                            final selected = selectedDays.contains(index);
                            return FilterChip(
                              label: Text(labels[index]),
                              selected: selected,
                              onSelected: (value) {
                                setDialogState(() {
                                  if (value) {
                                    selectedDays.add(index);
                                  } else {
                                    selectedDays.remove(index);
                                  }
                                });
                              },
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: fieldWidth,
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final picked = await _showSelectDateModal(
                                    context,
                                    initialDate:
                                        effectiveFrom ?? DateTime.now(),
                                    firstDate: DateTime(2024),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) {
                                    setDialogState(
                                      () => effectiveFrom = picked,
                                    );
                                  }
                                },
                                child: Text(
                                  'From: ${effectiveFrom == null ? '-' : effectiveFrom!.toIso8601String().split('T').first}',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final picked = await _showSelectDateModal(
                                    context,
                                    initialDate:
                                        effectiveTo ??
                                        effectiveFrom ??
                                        DateTime.now(),
                                    firstDate: DateTime(2024),
                                    lastDate: DateTime(2035),
                                  );
                                  setDialogState(() => effectiveTo = picked);
                                },
                                child: Text(
                                  'To: ${effectiveTo == null ? '-' : effectiveTo!.toIso8601String().split('T').first}',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: fieldWidth,
                        child: TextField(
                          controller: noteController,
                          decoration: const InputDecoration(labelText: 'Note'),
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          _buildDialogActions(
            context: context,
            confirmLabel: 'Save',
            onCancel: () async => Navigator.of(context).pop(false),
            onConfirm: () async {
              final controller = ref.read(
                staffShiftControllerProvider.notifier,
              );
              if (pattern == null) {
                await controller.createPattern(
                  membershipId: membershipId,
                  branchId: state.selectedBranchId!,
                  daysOfWeek: selectedDays.toList()..sort(),
                  plannedStartTime: startController.text.trim(),
                  plannedEndTime: endController.text.trim(),
                  effectiveFrom: effectiveFrom,
                  effectiveTo: effectiveTo,
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                );
              } else {
                await controller.updatePattern(
                  patternId: pattern.id,
                  daysOfWeek: selectedDays.toList()..sort(),
                  plannedStartTime: startController.text.trim(),
                  plannedEndTime: endController.text.trim(),
                  effectiveTo: effectiveTo,
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                );
              }
              if (context.mounted) Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );

    startController.dispose();
    endController.dispose();
    noteController.dispose();
    if (saved == true) {
      ref.invalidate(staffShiftControllerProvider);
    }
  }

  Future<void> _showDeactivatePatternDialog(
    BuildContext context,
    WidgetRef ref, {
    required StaffShiftPattern pattern,
  }) async {
    final reasonController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.white,
        title: const Text('Deactivate pattern'),
        content: _buildDialogContent(
          child: TextField(
            controller: reasonController,
            decoration: const InputDecoration(labelText: 'Reason'),
          ),
        ),
        actions: [
          _buildDialogActions(
            context: context,
            confirmLabel: 'Deactivate',
            onConfirm: () async {
              await ref
                  .read(staffShiftControllerProvider.notifier)
                  .deactivatePattern(
                    patternId: pattern.id,
                    reason: reasonController.text.trim(),
                  );
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
    reasonController.dispose();
  }

  Future<void> _showInstanceDialog(
    BuildContext context,
    WidgetRef ref,
    StaffShiftState state, {
    StaffShiftInstance? instance,
  }) async {
    final membershipItems = state.memberships;
    String membershipId =
        instance?.membershipId ??
        state.selectedMembershipId ??
        (membershipItems.isNotEmpty ? membershipItems.first.membershipId : '');
    final date = ValueNotifier<DateTime>(
      instance?.date ?? state.dateRange.start,
    );
    final startController = TextEditingController(
      text: instance?.plannedStartTime ?? '08:00',
    );
    final endController = TextEditingController(
      text: instance?.plannedEndTime ?? '17:00',
    );
    final noteController = TextEditingController(text: instance?.note ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.white,
        title: Text(instance == null ? 'Add shift' : 'Edit shift'),
        content: _buildDialogContent(
          child: StatefulBuilder(
            builder: (context, setDialogState) => LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth = constraints.maxWidth;
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: fieldWidth,
                        child: DropdownMenu<String>(
                          width: fieldWidth,
                          requestFocusOnTap: false,
                          initialSelection: membershipId,
                          menuStyle: _whiteDropdownMenuStyle,
                          label: const Text('Staff'),
                          onSelected: (value) {
                            if (value == null) return;
                            setDialogState(() => membershipId = value);
                          },
                          dropdownMenuEntries: membershipItems
                              .map(
                                (membership) => DropdownMenuEntry<String>(
                                  value: membership.membershipId,
                                  label: membership.displayName,
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: fieldWidth,
                        child: ValueListenableBuilder<DateTime>(
                          valueListenable: date,
                          builder: (context, selectedDate, _) => OutlinedButton(
                            onPressed: () async {
                              final picked = await _showSelectDateModal(
                                context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) date.value = picked;
                            },
                            child: Text(
                              'Date: ${selectedDate.toIso8601String().split('T').first}',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: fieldWidth,
                        child: TextField(
                          controller: startController,
                          decoration: const InputDecoration(
                            labelText: 'Start time (HH:mm)',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: fieldWidth,
                        child: TextField(
                          controller: endController,
                          decoration: const InputDecoration(
                            labelText: 'End time (HH:mm)',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: fieldWidth,
                        child: TextField(
                          controller: noteController,
                          decoration: const InputDecoration(labelText: 'Note'),
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          _buildDialogActions(
            context: context,
            confirmLabel: 'Save',
            onConfirm: () async {
              final controller = ref.read(
                staffShiftControllerProvider.notifier,
              );
              if (instance == null) {
                await controller.createInstance(
                  membershipId: membershipId,
                  branchId: state.selectedBranchId!,
                  date: date.value,
                  plannedStartTime: startController.text.trim(),
                  plannedEndTime: endController.text.trim(),
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                );
              } else {
                await controller.updateInstance(
                  instanceId: instance.id,
                  date: date.value,
                  plannedStartTime: startController.text.trim(),
                  plannedEndTime: endController.text.trim(),
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                );
              }
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
    startController.dispose();
    endController.dispose();
    noteController.dispose();
    date.dispose();
  }

  Future<void> _showCancelInstanceDialog(
    BuildContext context,
    WidgetRef ref, {
    required StaffShiftInstance instance,
  }) async {
    final reasonController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.white,
        title: const Text('Cancel shift'),
        content: _buildDialogContent(
          child: TextField(
            controller: reasonController,
            decoration: const InputDecoration(labelText: 'Reason'),
          ),
        ),
        actions: [
          _buildDialogActions(
            context: context,
            confirmLabel: 'Save',
            onConfirm: () async {
              await ref
                  .read(staffShiftControllerProvider.notifier)
                  .cancelInstance(
                    instanceId: instance.id,
                    reason: reasonController.text.trim(),
                  );
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
    reasonController.dispose();
  }

  Widget _buildDialogActions({
    required BuildContext context,
    required String confirmLabel,
    required Future<void> Function() onConfirm,
    Future<void> Function()? onCancel,
  }) {
    return SizedBox(
      width: double.maxFinite,
      child: Row(
        children: [
          Expanded(
            child: FilledButton.tonal(
              onPressed: () async {
                if (onCancel != null) {
                  await onCancel();
                  return;
                }
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: () async => onConfirm(),
              child: Text(confirmLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogContent({required Widget child}) {
    return SizedBox(width: double.maxFinite, child: child);
  }

  Widget _buildLoadMoreButton({
    required bool canLoadMore,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: canLoadMore && !isLoading ? onPressed : null,
      child: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(canLoadMore ? 'Load more' : 'All records loaded'),
    );
  }
}

// ── Filter bar ───────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.dateLabel,
    required this.isSaving,
    required this.isRefreshing,
    required this.isPatternsTab,
    required this.onOpenFilters,
    required this.hasActiveFilter,
    this.selectedBranchName,
    this.selectedMembershipName,
    this.onAddPattern,
    this.onAddShift,
    this.onRefresh,
  });

  final String? selectedBranchName;
  final String dateLabel;
  final String? selectedMembershipName;
  final bool isSaving;
  final bool isRefreshing;
  final bool isPatternsTab;
  final bool hasActiveFilter;
  final VoidCallback onOpenFilters;
  final VoidCallback? onAddPattern;
  final VoidCallback? onAddShift;
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;

          final currentFilterTitle = Text(
            'Current Filter',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
              letterSpacing: 0.2,
            ),
          );

          final chipsRow = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChipPill(
                  label: 'Branch: ${selectedBranchName ?? 'All branches'}',
                ),
                const SizedBox(width: 6),
                _FilterChipPill(label: 'Date: $dateLabel'),
                const SizedBox(width: 6),
                _FilterChipPill(
                  label: 'Staff: ${selectedMembershipName ?? 'All staff'}',
                ),
              ],
            ),
          );

          final buttonStyle = FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );

          final filterBtn = TextButton(
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
          );

          final addPatternBtn = FilledButton.tonalIcon(
            style: buttonStyle,
            onPressed: onAddPattern,
            icon: const Icon(Icons.event_repeat_outlined, size: 16),
            label: const Text('Add pattern'),
          );

          final addShiftBtn = FilledButton.tonalIcon(
            style: buttonStyle,
            onPressed: onAddShift,
            icon: const Icon(Icons.event_available_outlined, size: 16),
            label: const Text('Add shift'),
          );

          final refreshBtn = IconButton.filledTonal(
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
          );

          if (isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [currentFilterTitle, const Spacer(), filterBtn]),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: chipsRow),
                    const SizedBox(width: 10),
                    isPatternsTab ? addPatternBtn : addShiftBtn,
                    const SizedBox(width: 6),
                    refreshBtn,
                  ],
                ),
              ],
            );
          }

          // ── Small screen: primary actions first, filter info below ──────────
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: primary action buttons
              Row(
                children: [
                  Expanded(child: addPatternBtn),
                  const SizedBox(width: 6),
                  Expanded(child: addShiftBtn),
                ],
              ),
              const SizedBox(height: 15),
              const Divider(height: 1, thickness: 1),
              // Row 2: "Current filter" label (left) + filter button (right)
              Row(children: [currentFilterTitle, const Spacer(), filterBtn]),
              // Row 3: scrollable chips + refresh
              Row(
                children: [
                  Expanded(child: chipsRow),
                  const SizedBox(width: 6),
                  refreshBtn,
                ],
              ),
            ],
          );
        },
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
      padding: EdgeInsets.only(left: 10, right: 6, top: 6, bottom: 6),
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
