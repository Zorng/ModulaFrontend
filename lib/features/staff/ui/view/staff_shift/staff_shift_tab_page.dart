import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/staff/domain/models/staff_shift_models.dart';
import 'package:modular_pos/features/staff/ui/view/staff_shift/widgets/staff_shift_instance_card.dart';
import 'package:modular_pos/features/staff/ui/view/staff_shift/widgets/staff_shift_pattern_card.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_shift_controller.dart';

class StaffShiftTabPage extends ConsumerWidget {
  const StaffShiftTabPage({super.key});

  static const double _dialogMaxWidth = 600;
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            final topButtonStyle = FilledButton.styleFrom(
              minimumSize: const Size(0, _topControlHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            );
            Widget labeledControl({
              required String title,
              required Widget child,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 4),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  SizedBox(height: _topControlHeight, child: child),
                ],
              );
            }

            final membershipById = {
              for (final membership in state.memberships)
                membership.membershipId: membership.displayName,
            };
            final addPatternButton = FilledButton.tonalIcon(
              style: topButtonStyle,
              onPressed: state.selectedBranchId == null || state.isSaving
                  ? null
                  : () => _showPatternDialog(context, ref, state),
              icon: const Icon(Icons.event_repeat_outlined),
              label: const Text('Add pattern'),
            );
            final addShiftButton = FilledButton.tonalIcon(
              style: topButtonStyle,
              onPressed: state.selectedBranchId == null || state.isSaving
                  ? null
                  : () => _showInstanceDialog(context, ref, state),
              icon: const Icon(Icons.event_available_outlined),
              label: const Text('Add shift'),
            );
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmall = AppBreakpoints.isSmall(
                        constraints.maxWidth,
                      );
                      final menuWidth = isSmall ? constraints.maxWidth : 240.0;
                      final wideMenuWidth = (constraints.maxWidth - 8) / 2;
                      final resolvedMenuWidth = isSmall
                          ? menuWidth
                          : wideMenuWidth;

                      final branchMenu = DropdownMenu<String?>(
                        width: resolvedMenuWidth,
                        initialSelection: state.selectedBranchId,
                        hintText: 'Select branch',
                        inputDecorationTheme: _topDropdownDecorationTheme,
                        menuStyle: _whiteDropdownMenuStyle,
                        onSelected: controller.setBranchId,
                        dropdownMenuEntries: [
                          for (final branch in state.branches)
                            DropdownMenuEntry<String?>(
                              value: branch.branchId,
                              label: branch.branchName,
                            ),
                        ],
                      );

                      final staffMenu = DropdownMenu<String?>(
                        width: resolvedMenuWidth,
                        initialSelection: state.selectedMembershipId,
                        hintText: 'Select staff',
                        inputDecorationTheme: _topDropdownDecorationTheme,
                        menuStyle: _whiteDropdownMenuStyle,
                        onSelected: controller.setMembershipId,
                        dropdownMenuEntries: [
                          const DropdownMenuEntry<String?>(
                            value: null,
                            label: 'All staff',
                          ),
                          ...state.memberships.map(
                            (membership) => DropdownMenuEntry<String?>(
                              value: membership.membershipId,
                              label: membership.displayName,
                            ),
                          ),
                        ],
                      );

                      final branchField = labeledControl(
                        title: 'Branch',
                        child: branchMenu,
                      );
                      final staffField = labeledControl(
                        title: 'Staff',
                        child: staffMenu,
                      );

                      final dateRangeBtn = FilledButton.tonalIcon(
                        style: topButtonStyle,
                        onPressed: () async {
                          final picked = await _showSelectRangeModal(
                            context,
                            state.dateRange,
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

                      if (isSmall) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            branchField,
                            const SizedBox(height: 8),
                            staffField,
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: dateRangeBtn),
                                const SizedBox(width: 8),
                                refreshBtn,
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: addPatternButton),
                                const SizedBox(width: 8),
                                Expanded(child: addShiftButton),
                              ],
                            ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(child: branchField),
                              const SizedBox(width: 8),
                              Expanded(child: staffField),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: dateRangeBtn),
                              const SizedBox(width: 8),
                              Expanded(child: addPatternButton),
                              const SizedBox(width: 8),
                              Expanded(child: addShiftButton),
                              const SizedBox(width: 8),
                              refreshBtn,
                            ],
                          ),
                        ],
                      );
                    },
                  ),
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
                const SizedBox(height: 4),
                Text(
                  'Patterns',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (state.schedule.patterns.isEmpty)
                  const Card(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No shift patterns for the selected filters.',
                      ),
                    ),
                  )
                else
                  Column(
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
                            onDeactivate: () => _showDeactivatePatternDialog(
                              context,
                              ref,
                              pattern: pattern,
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                Text(
                  'Instances',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (state.schedule.instances.isEmpty)
                  const Card(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No shift instances for the selected filters.',
                      ),
                    ),
                  )
                else
                  Column(
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
                    ],
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
}
