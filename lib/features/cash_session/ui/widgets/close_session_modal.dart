import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A modal bottom sheet for closing a cash session.
///
/// It includes fields for closing float in USD and KHR, and an optional note.
class CloseSessionModal extends StatefulWidget {
  const CloseSessionModal({
    super.key,
    required this.onSessionClosed,
  });

  final void Function(double usdAmount, double khrAmount, String note)
      onSessionClosed;

  @override
  State<CloseSessionModal> createState() => _CloseSessionModalState();
}

class _CloseSessionModalState extends State<CloseSessionModal> {
  final _usdController = TextEditingController();
  final _khrController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _usdController.dispose();
    _khrController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define a consistent decoration for all text fields in this modal.
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
            // Header: Title and Close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Close Session',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Form fields
            _buildCurrencyField(
              label: 'Closing Float USD',
              decoration: textFieldDecoration,
              controller: _usdController,
            ),
            const SizedBox(height: 16),
            _buildCurrencyField(
              label: 'Closing Float KHR',
              decoration: textFieldDecoration,
              controller: _khrController,
            ),
            const SizedBox(height: 16),
            _buildTextFieldWithLabel(
              label: 'Note (Optional)',
              maxLines: 3,
              decoration: textFieldDecoration,
              controller: _noteController,
            ),
            const SizedBox(height: 24),
            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final usdAmount =
                      double.tryParse(_usdController.text.trim()) ?? 0.0;
                  final khrAmount =
                      double.tryParse(_khrController.text.trim()) ?? 0.0;
                  final note = _noteController.text.trim();
                  widget.onSessionClosed(usdAmount, khrAmount, note);
                },
                child: const Text('Close Session'),
              ),
            ),
            const SizedBox(height: 32), // Bottom padding
          ],
        ),
      ),
    );
  }

  /// Helper to build a text field with a styled label above it.
  Widget _buildTextFieldWithLabel({
    required String label,
    int maxLines = 1,
    required InputDecoration decoration,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
          decoration: decoration,
          controller: controller,
        ),
      ],
    );
  }

  /// Helper to build a currency input field.
  Widget _buildCurrencyField({
    required String label,
    required InputDecoration decoration,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: decoration,
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

}