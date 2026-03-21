import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/discount/domain/models/discount_scope.dart';
import 'package:modular_pos/features/discount/ui/components/discount_form_details_section.dart';
import 'package:modular_pos/features/discount/ui/components/discount_form_message.dart';
import 'package:modular_pos/features/discount/ui/components/discount_form_schedule_section.dart';
import 'package:modular_pos/features/discount/ui/components/discount_form_targeting_section.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_form_controller.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_support_providers.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';

class DiscountRuleFormPage extends ConsumerStatefulWidget {
  const DiscountRuleFormPage({super.key, this.ruleId});

  final String? ruleId;

  @override
  ConsumerState<DiscountRuleFormPage> createState() =>
      _DiscountRuleFormPageState();
}

class _DiscountRuleFormPageState extends ConsumerState<DiscountRuleFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _percentageController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _percentageController = TextEditingController();
    Future<void>(() {
      ref.read(discountFormControllerProvider.notifier).load(widget.ruleId);
    });
  }

  @override
  void didUpdateWidget(covariant DiscountRuleFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ruleId == widget.ruleId) return;
    Future<void>(() {
      ref.read(discountFormControllerProvider.notifier).load(widget.ruleId);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _percentageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discountFormControllerProvider);
    final controller = ref.read(discountFormControllerProvider.notifier);
    final branchesAsync = ref.watch(discountTenantBranchesProvider);
    final width = MediaQuery.of(context).size.width;
    final isLarge = AppBreakpoints.isLarge(width);
    final horizontalPadding = width >= 1440
        ? 32.0
        : (isLarge ? 24.0 : (AppBreakpoints.isMedium(width) ? 20.0 : 16.0));
    final session = ref.watch(loginControllerProvider).session;
    final availableBranches =
        branchesAsync.asData?.value ?? const <BranchListItem>[];
    final selectedBranchName = _selectedBranchName(
      selectedBranchId: state.selectedBranchId,
      branches: availableBranches,
    );
    final branchItemsAsync =
        state.scope == DiscountScopes.item &&
            state.selectedBranchId.trim().isNotEmpty
        ? ref.watch(discountBranchMenuItemsProvider(state.selectedBranchId))
        : const AsyncValue.data(<MenuItem>[]);

    _syncController(_nameController, state.name);
    _syncController(_percentageController, state.percentageText);

    Future<void> save() async {
      if (state.isReadOnly) return;
      if (!_formKey.currentState!.validate()) return;

      if (!state.isEditMode) {
        final confirmed = await _showCreateConfirmationDialog(
          context: context,
          state: state,
          selectedBranchName: selectedBranchName,
          availableItems: branchItemsAsync.asData?.value ?? const <MenuItem>[],
        );
        if (confirmed != true || !context.mounted) return;
      }

      final tenantId = (session?.activeTenantId ?? session?.user.tenantId ?? '')
          .trim();
      final saved = await controller.save(tenantId: tenantId);
      if (saved == null) {
        final nextState = ref.read(discountFormControllerProvider);
        final overlapWarning = nextState.overlapWarning;
        if (overlapWarning == null || !context.mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            final conflictSummary = overlapWarning.conflictingRuleIds.isEmpty
                ? 'This rule overlaps with another discount on the same branch.'
                : 'Conflicting rule ids: ${overlapWarning.conflictingRuleIds.join(', ')}';
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text('Confirm overlap'),
              content: Text('${overlapWarning.message}\n\n$conflictSummary'),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: AppTheme.cancelActionButtonStyle,
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
        if (confirmed != true) return;
        final retrySaved = await controller.save(
          tenantId: tenantId,
          confirmOverlap: true,
        );
        if (retrySaved == null || !context.mounted) return;
        context.pop(retrySaved);
        return;
      }
      if (!context.mounted) return;
      context.pop(saved);
    }

    void navigateBack() {
      if (context.canPop()) {
        context.pop();
        return;
      }
      context.go(AppRoute.discount.path);
    }

    Future<void> pickDateTime({required bool isStart}) async {
      if (state.isReadOnly) return;
      final existing = isStart ? state.startAt : state.endAt;
      final now = DateTime.now();
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: existing ?? now,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 5),
        builder: (context, child) => _PickerThemeWrapper(child: child),
      );
      if (pickedDate == null || !context.mounted) return;

      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(existing ?? now),
        builder: (context, child) => _PickerThemeWrapper(child: child),
      );
      if (pickedTime == null || !context.mounted) return;

      final next = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      if (isStart) {
        controller.setStartAt(next);
      } else {
        controller.setEndAt(next);
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: false,
        leading: AppBackButton(
          onPressed: navigateBack,
          icon: Icons.arrow_back,
          tooltip: 'Back',
        ),
        title: Text(state.isEditMode ? 'Edit discount' : 'Add discount'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              isLarge ? 24 : 16,
              horizontalPadding,
              24,
            ),
            children: [
              if (state.error != null) ...[
                DiscountFormMessage(message: state.error!),
                const SizedBox(height: 16),
              ],
              if (branchesAsync.hasError) ...[
                const DiscountFormMessage(
                  message: 'Failed to load tenant branches.',
                ),
                const SizedBox(height: 16),
              ],
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                DiscountFormDetailsSection(
                  nameController: _nameController,
                  percentageController: _percentageController,
                  scope: state.scope,
                  selectedBranchId: state.selectedBranchId,
                  selectedBranchName: selectedBranchName,
                  availableBranches: availableBranches,
                  isEditMode: state.isEditMode,
                  isSaving: state.isSaving,
                  isReadOnly: state.isReadOnly,
                  onBranchChanged: controller.setBranchId,
                  onScopeChanged: controller.setScope,
                  onNameChanged: controller.setName,
                  onPercentageChanged: controller.setPercentageText,
                ),
                const SizedBox(height: 16),
                DiscountFormScheduleSection(
                  startLabel: _formatDateTime(state.startAt),
                  endLabel: _formatDateTime(state.endAt),
                  enabled: !state.isReadOnly,
                  onPickStart: () => pickDateTime(isStart: true),
                  onPickEnd: () => pickDateTime(isStart: false),
                  onClearStart: state.startAt == null
                      ? null
                      : controller.clearStartAt,
                  onClearEnd: state.endAt == null
                      ? null
                      : controller.clearEndAt,
                ),
                const SizedBox(height: 16),
                DiscountFormTargetingSection(
                  scope: state.scope,
                  selectedBranchName: selectedBranchName,
                  availableItems:
                      branchItemsAsync.asData?.value ?? const <MenuItem>[],
                  selectedItemIds: state.parsedItemIds,
                  invalidItemIds: state.invalidItemIds,
                  isReadOnly: state.isReadOnly,
                  isLoadingItems: branchItemsAsync.isLoading,
                  itemLoadError: branchItemsAsync.hasError
                      ? 'Failed to load branch menu items.'
                      : null,
                  onSelectionChanged: controller.setSelectedItemIds,
                  onRetryLoad: branchItemsAsync.hasError
                      ? () => ref.refresh(
                          discountBranchMenuItemsProvider(
                            state.selectedBranchId,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 20),
                if (!state.isReadOnly)
                  _DiscountFormActionRow(
                    isSaving: state.isSaving,
                    isCreate: !state.isEditMode,
                    onCancel: navigateBack,
                    onSubmit: save,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }
}

class _DiscountFormActionRow extends StatelessWidget {
  const _DiscountFormActionRow({
    required this.isSaving,
    required this.isCreate,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool isSaving;
  final bool isCreate;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 140,
          child: FilledButton(
            style: AppTheme.cancelActionButtonStyle,
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 172,
          child: FilledButton(
            onPressed: isSaving ? null : onSubmit,
            child: Text(isCreate ? 'Create discount' : 'Save changes'),
          ),
        ),
      ],
    );
  }
}

Future<bool?> _showCreateConfirmationDialog({
  required BuildContext context,
  required dynamic state,
  required String selectedBranchName,
  required List<MenuItem> availableItems,
}) {
  final itemLookup = {for (final item in availableItems) item.id: item.name};
  final selectedLabels = state.parsedItemIds
      .take(5)
      .map((itemId) => itemLookup[itemId] ?? itemId)
      .join(', ');
  final hasMoreItems = state.parsedItemIds.length > 5;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Confirm discount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PreviewRow(label: 'Name', value: state.name.trim()),
            _PreviewRow(
              label: 'Percentage',
              value: '${state.percentageText.trim()}%',
            ),
            _PreviewRow(
              label: 'Scope',
              value: state.scope == DiscountScopes.branchWide
                  ? 'Branch-wide'
                  : 'Item-level',
            ),
            _PreviewRow(label: 'Branch', value: selectedBranchName),
            _PreviewRow(
              label: 'Schedule',
              value:
                  '${_formatDateTime(state.startAt)} to ${_formatDateTime(state.endAt)}',
            ),
            if (state.scope == DiscountScopes.item)
              _PreviewRow(
                label: 'Items',
                value: state.parsedItemIds.isEmpty
                    ? 'None selected'
                    : hasMoreItems
                    ? '$selectedLabels and ${state.parsedItemIds.length - 5} more'
                    : selectedLabels,
              ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: AppTheme.cancelActionButtonStyle,
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Create'),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

String _selectedBranchName({
  required String selectedBranchId,
  required List<BranchListItem> branches,
}) {
  for (final branch in branches) {
    if (branch.branchId == selectedBranchId) {
      return branch.branchName;
    }
  }
  return '';
}

String _formatDateTime(DateTime? value) {
  if (value == null) return 'Not set';
  return '${value.year}-${_two(value.month)}-${_two(value.day)} '
      '${_two(value.hour)}:${_two(value.minute)}';
}

String _two(int value) => value.toString().padLeft(2, '0');

class _PickerThemeWrapper extends StatelessWidget {
  const _PickerThemeWrapper({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        datePickerTheme: theme.datePickerTheme.copyWith(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          headerBackgroundColor: Colors.white,
          rangePickerBackgroundColor: Colors.white,
        ),
        timePickerTheme: theme.timePickerTheme.copyWith(
          backgroundColor: Colors.white,
          dialBackgroundColor: Colors.white,
          hourMinuteColor: Colors.white,
        ),
        colorScheme: theme.colorScheme.copyWith(
          surface: Colors.white,
          surfaceContainerHigh: Colors.white,
          surfaceContainerHighest: Colors.white,
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }
}
