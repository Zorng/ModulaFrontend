import 'package:flutter/material.dart';
import 'package:modular_pos/features/sale/ui/view/order/order_utils.dart';

class OrderStatusBottomSheet extends StatefulWidget {
  const OrderStatusBottomSheet({
    super.key,
    required this.initialStatus,
    required this.onSubmit,
  });

  final String initialStatus;
  final Future<void> Function(String status) onSubmit;

  @override
  State<OrderStatusBottomSheet> createState() => _OrderStatusBottomSheetState();
}

class _OrderStatusBottomSheetState extends State<OrderStatusBottomSheet> {
  late String _selected;
  bool _isSaving = false;

  static const _statuses = ['in_prep', 'ready', 'delivered', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
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
            Row(
              children: [
                const Text(
                  'Update Order Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            RadioGroup<String>(
              groupValue: _selected,
              onChanged: (value) {
                if (_isSaving) return;
                if (value == null) return;
                setState(() => _selected = value);
              },
              child: Column(
                children: [
                  ..._statuses.map(
                    (status) => RadioListTile<String>(
                      title: Text(orderStatusLabel(status)),
                      value: status,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                        setState(() => _isSaving = true);
                        try {
                          await widget.onSubmit(_selected);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        } finally {
                          if (mounted) setState(() => _isSaving = false);
                        }
                      },
                child: Text(_isSaving ? 'Updating...' : 'Update Status'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
