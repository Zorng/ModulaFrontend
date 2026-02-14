import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class VatRateBottomSheet extends StatefulWidget {
  const VatRateBottomSheet({
    super.key,
    required this.initialValue,
  });

  final String initialValue;

  @override
  State<VatRateBottomSheet> createState() => _VatRateBottomSheetState();
}

class _VatRateBottomSheetState extends State<VatRateBottomSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _isValid {
    final parsed = int.tryParse(_controller.text.trim());
    return parsed != null && parsed >= 1 && parsed <= 10;
  }

  String? get _errorText {
    final text = _controller.text.trim();
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < 1 || parsed > 10) {
      return 'Only 1 to 10% VAT is allowed';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VAT rate (%)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: InputDecoration(
              hintText: '1 – 10',
              suffixText: '%',
              errorText: _errorText,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  _isValid ? () => context.pop(_controller.text.trim()) : null,
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
