import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/input_formatters/decimal_text_input_formatter.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/modal_form_state_provider.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/unsaved_input_provider.dart';

/// A modal bottom sheet for adding a cash movement (Paid In/Paid Out).
class AddCashMovementModal extends ConsumerStatefulWidget {
  const AddCashMovementModal({
    super.key,
    required this.onMovementAdded,
  });

  /// Callback that passes the type ('Paid In'/'Paid Out') and the amounts.
  final void Function(
    String type,
    double usdAmount,
    double khrAmount,
    String reason,
  ) onMovementAdded;

  @override
  ConsumerState<AddCashMovementModal> createState() => _AddCashMovementModalState();
}

class _AddCashMovementModalState extends ConsumerState<AddCashMovementModal> {
  final _usdAmountController = TextEditingController();
  final _khrAmountController = TextEditingController();
  final _reasonController = TextEditingController();
  String _selectedType = 'Paid In'; // Default value

  @override
  void initState() {
    super.initState();
    
    // Restore saved form state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final formState = ref.read(cashMovementFormProvider);
      _selectedType = formState.type;
      _usdAmountController.text = formState.usdAmount;
      _khrAmountController.text = formState.khrAmount;
      _reasonController.text = formState.reason;
    });

    // Listen to changes and update state
    _usdAmountController.addListener(_onUsdChanged);
    _khrAmountController.addListener(_onKhrChanged);
    _reasonController.addListener(_onReasonChanged);
  }

  void _onUsdChanged() {
    ref.read(cashMovementFormProvider.notifier).updateUsdAmount(_usdAmountController.text);
    _updateUnsavedStatus();
  }

  void _onKhrChanged() {
    ref.read(cashMovementFormProvider.notifier).updateKhrAmount(_khrAmountController.text);
    _updateUnsavedStatus();
  }

  void _onReasonChanged() {
    ref.read(cashMovementFormProvider.notifier).updateReason(_reasonController.text);
    _updateUnsavedStatus();
  }

  void _updateUnsavedStatus() {
    final hasData = _usdAmountController.text.isNotEmpty ||
        _khrAmountController.text.isNotEmpty ||
        _reasonController.text.isNotEmpty;
    ref.read(unsavedInputProvider.notifier).markCashMovementUnsaved(hasData);
  }

  @override
  void dispose() {
    _usdAmountController.removeListener(_onUsdChanged);
    _khrAmountController.removeListener(_onKhrChanged);
    _reasonController.removeListener(_onReasonChanged);
    _usdAmountController.dispose();
    _khrAmountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final usdAmount = double.tryParse(_usdAmountController.text) ?? 0.0;
    final khrAmount = double.tryParse(_khrAmountController.text) ?? 0.0;
    final reason = _reasonController.text.trim();

    // Clear form state and unsaved status
    ref.read(cashMovementFormProvider.notifier).clear();
    ref.read(unsavedInputProvider.notifier).markCashMovementUnsaved(false);

    widget.onMovementAdded(
      _selectedType,
      usdAmount,
      khrAmount,
      reason,
    );
  }

  void _handleClose() {
    // Don't clear form state when closing - preserve for later
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final textFieldDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4.0),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4.0),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4.0),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1),
      ),
    );

    return Container(
      // Using Padding with MediaQuery to handle keyboard overlap gracefully.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cash Movement',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _handleClose,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form Fields
            _buildDropdownField(decoration: textFieldDecoration),
            const SizedBox(height: 16),
            _buildTextFieldWithLabel(
                label: 'USD Amount',
                decoration: textFieldDecoration,
                controller: _usdAmountController,
                isNumeric: true),
            const SizedBox(height: 16),
            _buildTextFieldWithLabel(
                label: 'KHR Amount',
                decoration: textFieldDecoration,
                controller: _khrAmountController,
                isNumeric: true),
            const SizedBox(height: 16),
            _buildTextFieldWithLabel(
                label: 'Reason',
                decoration: textFieldDecoration,
                controller: _reasonController,
                maxLines: 3),
            const SizedBox(height: 24),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                child: const Text('Add Cash Movement'),
              ),
            ),
            const SizedBox(height: 32), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({required InputDecoration decoration}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Type',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey(_selectedType),
          initialValue: _selectedType,
          decoration: decoration,
          items: ['Paid In', 'Paid Out']
              .map((label) => DropdownMenuItem(
                    value: label,
                    child: Text(label),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedType = value;
              });
              ref.read(cashMovementFormProvider.notifier).updateType(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildTextFieldWithLabel({
    required String label,
    required InputDecoration decoration,
    int maxLines = 1,
    required TextEditingController controller,
    bool isNumeric = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
          decoration: decoration,
          controller: controller,
          keyboardType: isNumeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          inputFormatters:
              isNumeric ? [DecimalTextInputFormatter(decimalRange: 2)] : [],
        ),
      ],
    );
  }
}