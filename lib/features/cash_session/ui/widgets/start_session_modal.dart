import 'package:flutter/material.dart';

/// A modal bottom sheet for starting a new cash session.
///
/// It includes fields for opening float in USD and KHR, and an optional note.
class StartSessionModal extends StatefulWidget {
  const StartSessionModal({
    super.key,
    required this.onSessionStarted,
  });

  final void Function(String usdAmount, String khrAmount) onSessionStarted;

  @override
  State<StartSessionModal> createState() => _StartSessionModalState();
}

class _StartSessionModalState extends State<StartSessionModal> {
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
    // Define a consistent decoration for all text fields in this modal. Use `final` instead of `const`.
    final textFieldDecoration = InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      // Set all border properties to a borderless OutlineInputBorder to ensure no lines appear.
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
      height: 507,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title and Close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Start Session',
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
              currency: 'USD',
              currencyColor: const Color(0xFFED533C),
              decoration: textFieldDecoration,
              controller: _usdController,
            ),
            const SizedBox(height: 16),
            _buildCurrencyField(
              currency: 'KHR',
              currencyColor: const Color(0xFFED533C),
              decoration: textFieldDecoration,
              controller: _khrController,
            ),
            const SizedBox(height: 16),
            _buildTextFieldWithLabel(
              label: 'Note (Optional)',
              labelColor: Colors.black,
              maxLines: 3, // For the note field
              decoration: textFieldDecoration,
              controller: _noteController,
            ),
            const Spacer(),
            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final usdAmount = _usdController.text.isEmpty ? '0.00' : _usdController.text;
                  final khrAmount = _khrController.text.isEmpty ? '0.00' : _khrController.text;
                  // TODO: Implement API call to start session with the entered values
                  widget.onSessionStarted(usdAmount, khrAmount); // Notify the parent screen
                },
                child: const Text('Start Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to build a text field with a styled label above it.
  Widget _buildTextFieldWithLabel({
    required String label,
    required Color labelColor,
    int maxLines = 1,
    required InputDecoration decoration,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: labelColor, fontWeight: FontWeight.w500),
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

  /// Helper to build a currency input field with a multi-style label.
  Widget _buildCurrencyField({
    required String currency,
    required Color currencyColor,
    required InputDecoration decoration,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            // Default style for the entire text
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 14, // Match default text style
              fontFamily: 'Roboto', // Ensure consistent font
            ),
            children: <TextSpan>[
              const TextSpan(text: 'Opening Float '),
              TextSpan(
                text: currency,
                style: TextStyle(
                  color: currencyColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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