import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/modal_form_state_provider.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/unsaved_input_provider.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';
import 'package:modular_pos/core/theme/app_buttons.dart';

/// A modal bottom sheet for closing a cash session.
///
/// It includes fields for closing float in USD and KHR, and an optional note.
/// Displays a confirmation summary with variance calculation before final closure.
class CloseSessionModal extends ConsumerStatefulWidget {
  const CloseSessionModal({super.key, required this.onSessionClosed});

  final void Function(double usdAmount, double khrAmount, String note)
  onSessionClosed;

  @override
  ConsumerState<CloseSessionModal> createState() => _CloseSessionModalState();
}

class _CloseSessionModalState extends ConsumerState<CloseSessionModal> {
  final _usdController = TextEditingController();
  final _khrController = TextEditingController();
  final _noteController = TextEditingController();

  // State to toggle between Input Form and Confirmation Summary
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();

    // Restore saved form state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final formState = ref.read(closeSessionFormProvider);
      _usdController.text = formState.usdAmount;
      _khrController.text = formState.khrAmount;
      _noteController.text = formState.note;
    });

    // Listen to changes and update state
    _usdController.addListener(_onUsdChanged);
    _khrController.addListener(_onKhrChanged);
    _noteController.addListener(_onNoteChanged);
  }

  void _onUsdChanged() {
    ref
        .read(closeSessionFormProvider.notifier)
        .updateUsdAmount(_usdController.text);
    _updateUnsavedStatus();
  }

  void _onKhrChanged() {
    ref
        .read(closeSessionFormProvider.notifier)
        .updateKhrAmount(_khrController.text);
    _updateUnsavedStatus();
  }

  void _onNoteChanged() {
    ref
        .read(closeSessionFormProvider.notifier)
        .updateNote(_noteController.text);
    _updateUnsavedStatus();
  }

  void _updateUnsavedStatus() {
    final hasData =
        _usdController.text.isNotEmpty ||
        _khrController.text.isNotEmpty ||
        _noteController.text.isNotEmpty;
    ref.read(unsavedInputProvider.notifier).markCloseSessionUnsaved(hasData);
  }

  @override
  void dispose() {
    _usdController.removeListener(_onUsdChanged);
    _khrController.removeListener(_onKhrChanged);
    _noteController.removeListener(_onNoteChanged);
    _usdController.dispose();
    _khrController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Check inputs and cart status before showing confirmation
  Future<void> _handleReview() async {
    final usdText = _usdController.text.trim();
    final khrText = _khrController.text.trim();

    // Validate: at least one field must have a valid value
    final usd = double.tryParse(usdText);
    final khr = double.tryParse(khrText);

    if (usd == null && khr == null) {
      // Both fields are empty or invalid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid closing float for at least one currency (USD or KHR)',
          ),
          backgroundColor: Color(0xFFED533C),
        ),
      );
      return;
    }

    // Check if cart has items before closing session
    final cartState = ref.read(saleCartProvider);
    if (cartState.lines.isNotEmpty) {
      // Show warning dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Cart Not Empty'),
              content: Text(
                'You have ${cartState.lines.length} item(s) in your cart. '
                'Closing the session will clear the cart and all items will be lost.\n\n'
                'Are you sure you want to continue?',
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: AppButtons.secondary(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Discard'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      );

      if (confirmed != true) return;

      // Clear cart
      ref.read(saleCartProvider.notifier).clear();
    }

    // If validations pass, show confirmation view
    setState(() {
      _isConfirming = true;
    });
  }

  void _handleFinalClose() {
    final usdAmount = double.tryParse(_usdController.text.trim()) ?? 0.0;
    final khrAmount = double.tryParse(_khrController.text.trim()) ?? 0.0;
    final note = _noteController.text.trim();

    // Clear form state and unsaved status
    ref.read(closeSessionFormProvider.notifier).clear();
    ref.read(unsavedInputProvider.notifier).markCloseSessionUnsaved(false);

    widget.onSessionClosed(usdAmount, khrAmount, note);
  }

  void _handleClose() {
    // Don't clear form state when closing - preserve for later
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
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
                Text(
                  _isConfirming ? 'Confirm Closure' : 'Close Session',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: _handleClose),
              ],
            ),
            const SizedBox(height: 24),

            if (_isConfirming) _buildConfirmationView() else _buildInputForm(),

            const SizedBox(height: 32), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm() {
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
          child: FilledButton(
             onPressed: _handleReview,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFED533C),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Review Closure'),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationView() {
    final sessionState = ref.watch(cashSessionViewModelProvider);

    // Current Inputs
    final countedUsd = double.tryParse(_usdController.text.trim()) ?? 0.0;
    final countedKhr = double.tryParse(_khrController.text.trim()) ?? 0.0;

    // Expected Values
    // Note: Assuming totalPaidIn includes USD and totalPaidOut includes USD.
    // If KHR is tracked separately, these fields need to be available in CashSessionState.
    // Currently using available fields.
    final expectedUsd =
        sessionState.openFloatUsd +
        sessionState.totalPaidIn -
        sessionState.totalPaidOut;
    final expectedKhr = sessionState.openFloatKhr; // Simplified as KHR totals not explicit in state

    // Variance
    final varianceUsd = countedUsd - expectedUsd;
    final varianceKhr = countedKhr - expectedKhr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 12),
               Expanded(
                child: Text(
                  'Please review the expected vs counted cash. Variance indicates discrepancies.',
                  style: TextStyle(color: Colors.blue, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Comparison Table
        Table(
          columnWidths: const {
            0: FlexColumnWidth(1.2), // Label
            1: FlexColumnWidth(1),   // Expected
            2: FlexColumnWidth(1),   // Counted
            3: FlexColumnWidth(1),   // Variance
          },
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade200),
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade50),
              children: [
                _buildTableCell('Currency', isHeader: true),
                _buildTableCell('Expected', isHeader: true, align: TextAlign.right),
                _buildTableCell('Counted', isHeader: true, align: TextAlign.right),
                _buildTableCell('Variance', isHeader: true, align: TextAlign.right),
              ],
            ),
            // USD Row
            TableRow(
              children: [
                _buildTableCell('USD', isBold: true),
                _buildTableCell('\$${expectedUsd.toStringAsFixed(2)}', align: TextAlign.right),
                _buildTableCell('\$${countedUsd.toStringAsFixed(2)}', align: TextAlign.right),
                _buildTableCell(
                  '\$${varianceUsd.toStringAsFixed(2)}',
                  align: TextAlign.right,
                  color: _getVarianceColor(varianceUsd),
                  isBold: true,
                ),
              ],
            ),
            // KHR Row
            TableRow(
              children: [
                _buildTableCell('KHR', isBold: true),
                _buildTableCell('${expectedKhr.toStringAsFixed(0)}', align: TextAlign.right),
                _buildTableCell('${countedKhr.toStringAsFixed(0)}', align: TextAlign.right),
                _buildTableCell(
                  '${varianceKhr.toStringAsFixed(0)}',
                   align: TextAlign.right,
                  color: _getVarianceColor(varianceKhr),
                  isBold: true,
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Actions
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () {
                  setState(() {
                    _isConfirming = false;
                  });
                },
                style: AppButtons.secondary(context),
                child: const Text('Back to Edit'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: _handleFinalClose,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFED533C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Confirm Close'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableCell(String text, {
     bool isHeader = false,
     TextAlign align = TextAlign.left,
     Color? color,
     bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? (isHeader ? Colors.grey.shade700 : Colors.black87),
          fontSize: 13,
        ),
      ),
    );
  }

  Color _getVarianceColor(double variance) {
    if (variance.abs() < 0.01) return Colors.green; // Zero variance
    return Colors.red; // Discrepancy
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
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
