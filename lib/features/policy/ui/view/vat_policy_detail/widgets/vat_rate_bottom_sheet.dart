import 'package:flutter/material.dart';
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: 'Enter rate',
              suffixText: '%',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

