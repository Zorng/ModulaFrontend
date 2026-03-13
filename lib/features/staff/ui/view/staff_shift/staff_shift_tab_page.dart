import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/features/staff/domain/models/staff_shift_models.dart';
import 'package:modular_pos/features/staff/ui/view/staff_shift/widgets/staff_shift_instance_card.dart';
import 'package:modular_pos/features/staff/ui/view/staff_shift/widgets/staff_shift_pattern_card.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_shift_controller.dart';

class StaffShiftTabPage extends ConsumerWidget {
  const StaffShiftTabPage({super.key});

  static const ButtonStyle _inlineFilledButtonStyle = ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(0, 48)),
  );

  static const ButtonStyle _inlineOutlinedButtonStyle = ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(0, 48)),
  );

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
            final membershipById = {
              for (final membership in state.memberships)
                membership.membershipId: membership.displayName,
            };
            return ListView(
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
                          for (final branch in state.branches)
                            DropdownMenuEntry<String?>(
                              value: branch.branchId,
                              label: branch.branchName,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownMenu<String?>(
                        initialSelection: state.selectedMembershipId,
                        label: const Text('Staff'),
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
                      ),
                    ),
                    FilledButton.tonalIcon(
                      style: _inlineFilledButtonStyle,
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2035),
                          initialDateRange: state.dateRange,
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
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      style: _inlineFilledButtonStyle,
                      onPressed:
                          state.selectedBranchId == null || state.isSaving
                          ? null
                          : () => _showPatternDialog(context, ref, state),
                      icon: const Icon(Icons.event_repeat_outlined),
                      label: const Text('Add pattern'),
                    ),
                    OutlinedButton.icon(
                      style: _inlineOutlinedButtonStyle,
                      onPressed:
                          state.selectedBranchId == null || state.isSaving
                          ? null
                          : () => _showInstanceDialog(context, ref, state),
                      icon: const Icon(Icons.event_available_outlined),
                      label: const Text('Add shift'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
        title: Text(pattern == null ? 'Add pattern' : 'Edit pattern'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownMenu<String>(
                    width: 360,
                    initialSelection: membershipId,
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: startController,
                    decoration: const InputDecoration(
                      labelText: 'Start time (HH:mm)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: endController,
                    decoration: const InputDecoration(
                      labelText: 'End time (HH:mm)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: effectiveFrom ?? DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setDialogState(() => effectiveFrom = picked);
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
                            final picked = await showDatePicker(
                              context: context,
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Note'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
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
            child: const Text('Save'),
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
        title: const Text('Deactivate pattern'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(staffShiftControllerProvider.notifier)
                  .deactivatePattern(
                    patternId: pattern.id,
                    reason: reasonController.text.trim(),
                  );
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Deactivate'),
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
        title: Text(instance == null ? 'Add shift' : 'Edit shift'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownMenu<String>(
                    width: 360,
                    initialSelection: membershipId,
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
                  const SizedBox(height: 12),
                  ValueListenableBuilder<DateTime>(
                    valueListenable: date,
                    builder: (context, selectedDate, _) => OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: startController,
                    decoration: const InputDecoration(
                      labelText: 'Start time (HH:mm)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: endController,
                    decoration: const InputDecoration(
                      labelText: 'End time (HH:mm)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Note'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
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
            child: const Text('Save'),
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
        title: const Text('Cancel shift'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(staffShiftControllerProvider.notifier)
                  .cancelInstance(
                    instanceId: instance.id,
                    reason: reasonController.text.trim(),
                  );
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    reasonController.dispose();
  }
}
