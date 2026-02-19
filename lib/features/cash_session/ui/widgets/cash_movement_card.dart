import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/modal_form_state_provider.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/unsaved_input_provider.dart';

/// A card for adding cash movements with session requirement check.
class CashMovementCard extends ConsumerStatefulWidget {
  const CashMovementCard({super.key, required this.onAddCashMovement});

  final void Function(
    String type,
    double usdAmount,
    double khrAmount,
    String reason,
  )? onAddCashMovement;

  @override
  ConsumerState<CashMovementCard> createState() => _CashMovementCardState();
}

class _CashMovementCardState extends ConsumerState<CashMovementCard> {
  String _movementType = 'paid-in';
  String _currency = 'usd';
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
      ref.read(cashMovementFormProvider.notifier).updateUsdAmount(_amountController.text);
      ref.read(cashMovementFormProvider.notifier).updateKhrAmount('');
    } else {
      ref.read(cashMovementFormProvider.notifier).updateKhrAmount(_amountController.text);
      ref.read(cashMovementFormProvider.notifier).updateUsdAmount('');
    }
    _updateUnsavedStatus();
  }

  void _onNoteChanged() {
    ref.read(cashMovementFormProvider.notifier).updateReason(_noteController.text);
    _updateUnsavedStatus();
  }

  void _updateUnsavedStatus() {
    final hasData = _amountController.text.isNotEmpty ||
        _noteController.text.isNotEmpty;
    ref.read(unsavedInputProvider.notifier).markCashMovementUnsaved(hasData);
  }

  void _onMovementTypeChanged(String value) {
    setState(() {
      _movementType = value;
    });
    // Update form state with mapped type
    final mappedType = value == 'paid-in' ? 'Paid In' : 'Paid Out';
    ref.read(cashMovementFormProvider.notifier).updateType(mappedType);
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

  void _handleSubmit() {
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

    final usdAmount = _currency == 'usd' ? amount : 0.0;
    final khrAmount = _currency == 'khr' ? amount : 0.0;
    

    final mappedType = _movementType == 'paid-in' ? 'Paid In' : 'Paid Out';

    // Clear form via provider which updates controllers through listener
    ref.read(cashMovementFormProvider.notifier).clear();
    ref.read(unsavedInputProvider.notifier).markCashMovementUnsaved(false);
    
    // Also manually clear controllers to be safe/instant
    _amountController.clear();
    _noteController.clear();

    if (widget.onAddCashMovement != null) {
      widget.onAddCashMovement!(mappedType, usdAmount, khrAmount, note);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cash movement added successfully'),
          backgroundColor: Color(0xFF10B981), // Success Green
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final sessionState = ref.watch(cashSessionViewModelProvider);
    final isSessionOpen = sessionState.sessionStatus == SessionStatus.open;

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
            const SizedBox(height: 16),

            // Cash Session Required Warning
            if (!isSessionOpen)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFED533C),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 20,
                          color: const Color(0xFFED533C),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cash Session Required',
                          style: textTheme.labelLarge?.copyWith(
                            color: const Color(0xFFED533C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Open a cash session before adding a cash movement.',
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFED533C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          context.go(AppRoute.cashSession.path);
                        },
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
              ),

            if (!isSessionOpen) const SizedBox(height: 16),

            // Movement Type
            Text(
              'Movement Type',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    label: 'Paid-in',
                    value: 'paid-in',
                    isSelected: _movementType == 'paid-in',
                    enabled: isSessionOpen,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTypeButton(
                    label: 'Paid-out',
                    value: 'paid-out',
                    isSelected: _movementType == 'paid-out',
                    enabled: isSessionOpen,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Currency
            Text(
              'Currency',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildCurrencyButton(
                    icon: Icons.attach_money,
                    label: 'Dollars',
                    value: 'usd',
                    isSelected: _currency == 'usd',
                    enabled: isSessionOpen,
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
                    enabled: isSessionOpen,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amount
            Text(
              'Amount',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              enabled: isSessionOpen,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
                disabledBorder: OutlineInputBorder(
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
            const SizedBox(height: 16),

            // Note (Reason)
            Text(
              'Reason',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              enabled: isSessionOpen,
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
                disabledBorder: OutlineInputBorder(
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
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Add Cash Movement Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSessionOpen ? _handleSubmit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: isSessionOpen
                      ? const Color(0xFFED533C)
                      : colorScheme.surfaceContainerHighest,
                  foregroundColor: isSessionOpen
                      ? Colors.white
                      : colorScheme.onSurfaceVariant,
                  disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                  disabledForegroundColor: colorScheme.onSurfaceVariant,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add Cash Movement'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required String value,
    required bool isSelected,
    required bool enabled,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return OutlinedButton(
      onPressed: enabled
          ? () {
              if (mounted) {
                _onMovementTypeChanged(value);
              }
            }
          : null,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected && enabled
            ? colorScheme.primary
            : Colors.transparent,
        foregroundColor: enabled
            ? (isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant)
            : colorScheme.onSurfaceVariant,
        side: BorderSide(
          color: enabled
              ? (isSelected ? colorScheme.primary : colorScheme.outlineVariant)
              : colorScheme.outlineVariant,
          width: isSelected && enabled ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label),
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
    return OutlinedButton(
      onPressed: enabled
          ? () {
              if (mounted) {
                _onCurrencyChanged(value);
              }
            }
          : null,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected && enabled
            ? colorScheme.primary
            : Colors.transparent,
        foregroundColor: enabled
            ? (isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant)
            : colorScheme.onSurfaceVariant,
        side: BorderSide(
          color: enabled
              ? (isSelected ? colorScheme.primary : colorScheme.outlineVariant)
              : colorScheme.outlineVariant,
          width: isSelected && enabled ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(label, style: textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
