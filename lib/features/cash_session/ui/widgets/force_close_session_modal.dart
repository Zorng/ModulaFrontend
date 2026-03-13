import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForceCloseSessionModal extends StatefulWidget {
  const ForceCloseSessionModal({super.key, required this.onForceClosed});

  final void Function(
    double usdAmount,
    double khrAmount,
    String reason,
    String note,
  )
  onForceClosed;

  @override
  State<ForceCloseSessionModal> createState() => _ForceCloseSessionModalState();
}

class _ForceCloseSessionModalState extends State<ForceCloseSessionModal> {
  final _usdController = TextEditingController();
  final _khrController = TextEditingController();
  final _reasonController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _usdController.dispose();
    _khrController.dispose();
    _reasonController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final usd = double.tryParse(_usdController.text.trim());
    final khr = double.tryParse(_khrController.text.trim());
    final reason = _reasonController.text.trim();
    final note = _noteController.text.trim();

    if (usd == null && khr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter counted cash for at least one currency (USD or KHR).',
          ),
          backgroundColor: Color(0xFFED533C),
        ),
      );
      return;
    }

    if (reason.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a clear reason for the force close.'),
          backgroundColor: Color(0xFFED533C),
        ),
      );
      return;
    }

    widget.onForceClosed(usd ?? 0, khr ?? 0, reason, note);
  }

  @override
  Widget build(BuildContext context) {
    final decoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFED533C), width: 1.5),
      ),
    );

    return Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Force Close Session',
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
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF5C58A)),
              ),
              child: const Text(
                'Use force close only when the branch session cannot be closed normally. A reason is required for audit review.',
                style: TextStyle(
                  color: Color(0xFFB45309),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildField(
              label: 'Counted Cash USD',
              controller: _usdController,
              decoration: decoration,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Counted Cash KHR',
              controller: _khrController,
              decoration: decoration,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Reason',
              controller: _reasonController,
              decoration: decoration.copyWith(
                hintText:
                    'Explain why this branch session must be force closed',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Note (Optional)',
              controller: _noteController,
              decoration: decoration.copyWith(
                hintText: 'Add any extra context',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB45309),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Force Close Session'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required InputDecoration decoration,
    int maxLines = 1,
    TextInputType? keyboardType,
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
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: decoration,
        ),
      ],
    );
  }
}
