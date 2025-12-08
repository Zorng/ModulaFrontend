import 'package:flutter/material.dart';

/// A modal bottom sheet for closing a cash session.
///
/// It includes fields for closing float in USD and KHR, and an optional note.
class CloseSessionModal extends StatelessWidget {
  const CloseSessionModal({
    super.key,
    required this.onSessionClosed,
  });

  final VoidCallback onSessionClosed;

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
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Form fields
            _buildCurrencyField(
              label: 'Closing Float USD',
              decoration: textFieldDecoration,
            ),
            const SizedBox(height: 16),
            _buildCurrencyField(
              label: 'Closing Float KHR',
              decoration: textFieldDecoration,
            ),
            const SizedBox(height: 16),
            _buildTextFieldWithLabel(
              label: 'Note (Optional)',
              maxLines: 3,
              decoration: textFieldDecoration,
            ),
            const SizedBox(height: 24),
            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement API call to close session with the entered values
                  onSessionClosed();
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
        ),
      ],
    );
  }

  /// Helper to build a currency input field.
  Widget _buildCurrencyField({
    required String label,
    required InputDecoration decoration,
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }
}