import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A modal bottom sheet for adding a cash movement (Paid In/Paid Out).
class AddCashMovementModal extends StatefulWidget {
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
  State<AddCashMovementModal> createState() => _AddCashMovementModalState();
}

class _AddCashMovementModalState extends State<AddCashMovementModal> {
  final _usdAmountController = TextEditingController();
  final _khrAmountController = TextEditingController();
  final _reasonController = TextEditingController();
  String _selectedType = 'Paid In'; // Default value

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed.
    _usdAmountController.dispose();
    _khrAmountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textFieldDecoration = InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
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
                  onPressed: () => Navigator.of(context).pop(),
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
                onPressed: () {
                  final usdAmount =
                      double.tryParse(_usdAmountController.text) ?? 0.0;
                  final khrAmount =
                      double.tryParse(_khrAmountController.text) ?? 0.0;
                  final reason = _reasonController.text.trim();

                  widget.onMovementAdded(
                    _selectedType,
                    usdAmount,
                    khrAmount,
                    reason,
                  );
                },
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
          inputFormatters: isNumeric ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))] : [],
        ),
      ],
    );
  }
}
