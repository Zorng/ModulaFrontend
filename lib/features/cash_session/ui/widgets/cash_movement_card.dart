import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/modal_form_state_provider.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/unsaved_input_provider.dart';

typedef CashMovementSubmitCallback =
    Future<CashMovementSubmitResult> Function(
      String type,
      double usdAmount,
      double khrAmount,
      String reason,
    );

class CashMovementSubmitResult {
  const CashMovementSubmitResult._({
    required this.isSuccess,
    this.errorMessage,
  });

  const CashMovementSubmitResult.success() : this._(isSuccess: true);

  const CashMovementSubmitResult.failure(String message)
    : this._(isSuccess: false, errorMessage: message);

  final bool isSuccess;
  final String? errorMessage;
}

/// A card for adding cash movements with session requirement check.
class CashMovementCard extends ConsumerStatefulWidget {
  const CashMovementCard({
    super.key,
    required this.onAddCashMovement,
    this.isWide = false,
  });

  final CashMovementSubmitCallback? onAddCashMovement;
  final bool isWide;

  @override
  ConsumerState<CashMovementCard> createState() => _CashMovementCardState();
}

class _CashMovementCardState extends ConsumerState<CashMovementCard> {
  static const _selectedControlColor = Color(0xFFED533C);

  String _movementType = 'paid-in';
  String _adjustmentDirection = 'increase';
  String _currency = 'usd';
  bool _isSubmitting = false;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Restore saved form state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final formState = ref.read(cashMovementFormProvider);
      // Map the type from form state
      if (formState.type == 'Paid In') {
        _movementType = 'paid-in';
      } else if (formState.type == 'Paid Out') {
        _movementType = 'paid-out';
      } else if (formState.type == 'Adjustment') {
        _movementType = 'adjustment';
      }
      // For currency, use USD amount if it has data, otherwise KHR
      if (formState.usdAmount.isNotEmpty) {
        _currency = 'usd';
        _amountController.text = formState.usdAmount;
      } else if (formState.khrAmount.isNotEmpty) {
        _currency = 'khr';
        _amountController.text = formState.khrAmount;
      }
      _noteController.text = formState.reason;
    });

    // Listen to changes and update state
    _amountController.addListener(_onAmountChanged);
    _noteController.addListener(_onNoteChanged);
  }

  void _onAmountChanged() {
    // Save to the appropriate currency field
    if (_currency == 'usd') {
      ref
          .read(cashMovementFormProvider.notifier)
          .updateUsdAmount(_amountController.text);
      ref.read(cashMovementFormProvider.notifier).updateKhrAmount('');
    } else {
      ref
          .read(cashMovementFormProvider.notifier)
          .updateKhrAmount(_amountController.text);
      ref.read(cashMovementFormProvider.notifier).updateUsdAmount('');
    }
    _updateUnsavedStatus();
  }

  void _onNoteChanged() {
    ref
        .read(cashMovementFormProvider.notifier)
        .updateReason(_noteController.text);
    _updateUnsavedStatus();
  }

  void _updateUnsavedStatus() {
    final hasData =
        _amountController.text.isNotEmpty || _noteController.text.isNotEmpty;
    ref.read(unsavedInputProvider.notifier).markCashMovementUnsaved(hasData);
  }

  void _onMovementTypeChanged(String value) {
    setState(() {
      _movementType = value;
      if (_movementType != 'adjustment') {
        _adjustmentDirection = 'increase';
      }
    });
    ref
        .read(cashMovementFormProvider.notifier)
        .updateType(_mappedMovementType(value));
  }

  void _onAdjustmentDirectionChanged(String value) {
    setState(() {
      _adjustmentDirection = value;
    });
  }

  void _onCurrencyChanged(String value) {
    setState(() {
      _currency = value;
    });
    // When currency changes, update the appropriate field
    _onAmountChanged();
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _noteController.removeListener(_onNoteChanged);
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final sessionState = ref.read(cashSessionViewModelProvider);
    final selectedMovementType = _resolvedMovementType(sessionState);
    final amountText = _amountController.text.trim();
    final note = _noteController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Color(0xFFED533C),
        ),
      );
      return;
    }

    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reason for the movement'),
          backgroundColor: Color(0xFFED533C),
        ),
      );
      return;
    }

    final mappedType = _mappedMovementType(selectedMovementType);
    if (!sessionState.canRecordMovementType(mappedType)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You do not have permission to record this movement type.',
          ),
          backgroundColor: Color(0xFFED533C),
        ),
      );
      return;
    }

    final isNegativeAdjustment =
        selectedMovementType == 'adjustment' &&
        _adjustmentDirection == 'decrease';
    final signedAmount = isNegativeAdjustment ? -amount : amount;
    final usdAmount = _currency == 'usd' ? signedAmount : 0.0;
    final khrAmount = _currency == 'khr' ? signedAmount : 0.0;

    if (widget.onAddCashMovement == null) return;

    setState(() {
      _isSubmitting = true;
    });

    final result = await widget.onAddCashMovement!(
      mappedType,
      usdAmount,
      khrAmount,
      note,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result.isSuccess) {
      ref.read(cashMovementFormProvider.notifier).clear();
      ref.read(unsavedInputProvider.notifier).markCashMovementUnsaved(false);
      _amountController.clear();
      _noteController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cash movement added successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.errorMessage ?? 'Unable to add cash movement. Try again.',
        ),
        backgroundColor: const Color(0xFFED533C),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final sessionState = ref.watch(cashSessionViewModelProvider);
    final isSessionOpen = sessionState.sessionStatus == SessionStatus.open;
    final canWriteAnyMovement = sessionState.canWriteAnyMovement;
    final selectedMovementType = _resolvedMovementType(sessionState);

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a Cash Movement',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isSessionOpen) ...[
              const SizedBox(height: 16),
              _NoSessionEmptyState(textTheme: textTheme),
            ] else if (!canWriteAnyMovement) ...[
              const SizedBox(height: 16),
              _ReadOnlyMovementState(textTheme: textTheme),
            ] else ...[
              const SizedBox(height: 16),
              _buildEnabledForm(
                sessionState,
                selectedMovementType,
                colorScheme,
                textTheme,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required bool isSelected,
    required bool enabled,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required VoidCallback? onPressed,
  }) {
    final backgroundColor = enabled
        ? (isSelected ? _selectedControlColor : Colors.white)
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = enabled
        ? (isSelected ? Colors.white : colorScheme.onSurface)
        : colorScheme.onSurfaceVariant;
    final borderColor = enabled
        ? (isSelected ? _selectedControlColor : colorScheme.outlineVariant)
        : colorScheme.outlineVariant;

    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        side: BorderSide(
          color: borderColor,
          width: isSelected && enabled ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: foregroundColor,
        ),
      ),
    );
  }

  String _mappedMovementType(String value) {
    return switch (value) {
      'paid-in' => 'Paid In',
      'paid-out' => 'Paid Out',
      'adjustment' => 'Adjustment',
      _ => 'Paid In',
    };
  }

  String _resolvedMovementType(CashSessionState sessionState) {
    final allowedTypes = <String>[
      if (sessionState.canRecordPaidIn) 'paid-in',
      if (sessionState.canRecordPaidOut) 'paid-out',
      if (sessionState.canRecordAdjustment) 'adjustment',
    ];
    if (allowedTypes.contains(_movementType)) {
      return _movementType;
    }
    return allowedTypes.isEmpty ? 'paid-in' : allowedTypes.first;
  }

  Widget _buildEnabledForm(
    CashSessionState sessionState,
    String selectedMovementType,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (widget.isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(
            'Movement Type',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(height: 8),
          _buildMovementTypeRow(
            sessionState,
            selectedMovementType,
            colorScheme,
            textTheme,
          ),
          if (selectedMovementType == 'adjustment') ...[
            const SizedBox(height: 16),
            _buildFieldLabel(
              'Adjustment Direction',
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
            const SizedBox(height: 8),
            _buildAdjustmentDirectionRow(colorScheme, textTheme),
          ],
          const SizedBox(height: 16),
          _buildFieldLabel(
            'Currency',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(height: 8),
          _buildCurrencyRow(colorScheme, textTheme),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAmountField(colorScheme, textTheme)),
              const SizedBox(width: 12),
              Expanded(child: _buildReasonField(colorScheme, textTheme)),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 220,
              child: _buildSubmitButton(selectedMovementType),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(
          'Movement Type',
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        const SizedBox(height: 8),
        _buildMovementTypeRow(
          sessionState,
          selectedMovementType,
          colorScheme,
          textTheme,
        ),
        if (selectedMovementType == 'adjustment') ...[
          const SizedBox(height: 16),
          _buildFieldLabel(
            'Adjustment Direction',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(height: 8),
          _buildAdjustmentDirectionRow(colorScheme, textTheme),
        ],
        const SizedBox(height: 16),
        _buildFieldLabel(
          'Currency',
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        const SizedBox(height: 8),
        _buildCurrencyRow(colorScheme, textTheme),
        const SizedBox(height: 16),
        _buildAmountField(colorScheme, textTheme),
        const SizedBox(height: 16),
        _buildReasonField(colorScheme, textTheme),
        const SizedBox(height: 16),
        _buildSubmitButton(selectedMovementType),
      ],
    );
  }

  Widget _buildFieldLabel(
    String label, {
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Text(
      label,
      style: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildMovementTypeRow(
    CashSessionState sessionState,
    String selectedMovementType,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final buttons = <Widget>[
      if (sessionState.canRecordPaidIn)
        Expanded(
          child: _buildTypeButton(
            label: 'Paid In',
            isSelected: selectedMovementType == 'paid-in',
            enabled: !_isSubmitting,
            colorScheme: colorScheme,
            textTheme: textTheme,
            onPressed: () => _onMovementTypeChanged('paid-in'),
          ),
        ),
      if (sessionState.canRecordPaidOut)
        Expanded(
          child: _buildTypeButton(
            label: 'Paid Out',
            isSelected: selectedMovementType == 'paid-out',
            enabled: !_isSubmitting,
            colorScheme: colorScheme,
            textTheme: textTheme,
            onPressed: () => _onMovementTypeChanged('paid-out'),
          ),
        ),
      if (sessionState.canRecordAdjustment)
        Expanded(
          child: _buildTypeButton(
            label: 'Adjustment',
            isSelected: selectedMovementType == 'adjustment',
            enabled: !_isSubmitting,
            colorScheme: colorScheme,
            textTheme: textTheme,
            onPressed: () => _onMovementTypeChanged('adjustment'),
          ),
        ),
    ];

    return Row(children: _withSpacing(buttons, const SizedBox(width: 8)));
  }

  Widget _buildAdjustmentDirectionRow(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildTypeButton(
            label: 'Increase',
            isSelected: _adjustmentDirection == 'increase',
            enabled: !_isSubmitting,
            colorScheme: colorScheme,
            textTheme: textTheme,
            onPressed: () => _onAdjustmentDirectionChanged('increase'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildTypeButton(
            label: 'Decrease',
            isSelected: _adjustmentDirection == 'decrease',
            enabled: !_isSubmitting,
            colorScheme: colorScheme,
            textTheme: textTheme,
            onPressed: () => _onAdjustmentDirectionChanged('decrease'),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyRow(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      children: [
        Expanded(
          child: _buildCurrencyButton(
            icon: Icons.attach_money,
            label: 'Dollars',
            value: 'usd',
            isSelected: _currency == 'usd',
            enabled: !_isSubmitting,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCurrencyButton(
            icon: Icons.money,
            label: 'KHR',
            value: 'khr',
            isSelected: _currency == 'khr',
            enabled: !_isSubmitting,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(
          'Amount',
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          enabled: !_isSubmitting,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Enter amount',
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReasonField(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(
          'Reason',
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          enabled: !_isSubmitting,
          decoration: InputDecoration(
            hintText: 'Enter reason (required)',
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          maxLines: widget.isWide ? 1 : 3,
        ),
      ],
    );
  }

  Widget _buildSubmitButton(String selectedMovementType) {
    final actionLabel = switch (selectedMovementType) {
      'adjustment' => 'Apply Adjustment',
      _ => 'Add Cash Movement',
    };
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFED533C),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(actionLabel),
      ),
    );
  }

  Widget _buildCurrencyButton({
    required IconData icon,
    required String label,
    required String value,
    required bool isSelected,
    required bool enabled,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final backgroundColor = enabled
        ? (isSelected ? _selectedControlColor : Colors.white)
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = enabled
        ? (isSelected ? Colors.white : colorScheme.onSurface)
        : colorScheme.onSurfaceVariant;
    final borderColor = enabled
        ? (isSelected ? _selectedControlColor : colorScheme.outlineVariant)
        : colorScheme.outlineVariant;

    return OutlinedButton(
      onPressed: enabled
          ? () {
              if (mounted) {
                _onCurrencyChanged(value);
              }
            }
          : null,
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        side: BorderSide(
          color: borderColor,
          width: isSelected && enabled ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: foregroundColor),
          const SizedBox(height: 4),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: foregroundColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> children, Widget spacer) {
    if (children.isEmpty) return children;
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) spaced.add(spacer);
      spaced.add(children[i]);
    }
    return spaced;
  }
}

class _NoSessionEmptyState extends StatelessWidget {
  const _NoSessionEmptyState({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_outline,
                size: 20,
                color: Color(0xFFC2410C),
              ),
              const SizedBox(width: 8),
              Text(
                'Cash Session Required',
                style: textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF9A3412),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Manual movements are available only while a cash session is open.',
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF9A3412),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go(AppRoute.cashSession.path),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFED533C),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Open Cash Session'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyMovementState extends StatelessWidget {
  const _ReadOnlyMovementState({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.visibility_outlined,
                size: 20,
                color: Color(0xFF475569),
              ),
              const SizedBox(width: 8),
              Text(
                'Read-only movement access',
                style: textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF334155),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'You can review movement history for this branch session, but you cannot record manual cash movements.',
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
