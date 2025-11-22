import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/domain/utils/stock_quantity_formatter.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';

class AdjustStockQuantityPage extends ConsumerStatefulWidget {
  const AdjustStockQuantityPage({super.key, required this.item});

  final StockItem item;

  @override
  ConsumerState<AdjustStockQuantityPage> createState() => _AdjustStockQuantityPageState();
}

class _AdjustStockQuantityPageState extends ConsumerState<AdjustStockQuantityPage> {
  final _amountCtrl = TextEditingController(text: '0');
  final _noteCtrl = TextEditingController();
  _AdjustmentType _type = _AdjustmentType.receive;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      appBar: AppBar(
        title: Text('Adjust ${item.name}'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(item.name),
              subtitle: Text('${item.branchName} • ${item.category} • ${_pieceLabel(item)}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    StockQuantityFormatter(
                      baseQty: item.onHand,
                      pieceSize: item.pieceSize,
                      baseUnit: item.baseUnit,
                    ).format(),
                  ),
                  Text(
                    'Min ${StockQuantityFormatter(
                      baseQty: item.minThreshold,
                      pieceSize: item.pieceSize,
                      baseUnit: item.baseUnit,
                    ).format()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<_AdjustmentType>(
            segments: const [
              ButtonSegment(value: _AdjustmentType.receive, label: Text('Receive')),
              ButtonSegment(value: _AdjustmentType.waste, label: Text('Waste')),
              ButtonSegment(value: _AdjustmentType.correction, label: Text('Correction')),
            ],
            selected: {_type},
            onSelectionChanged: (value) => setState(() => _type = value.first),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              hintText: 'Enter units',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submit,
            child: const Text('Apply adjustment'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final amount = int.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a non-zero quantity')),
      );
      return;
    }

    // Placeholder until backend integration.
    ref.read(stockInventoryControllerProvider.notifier);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_typeLabel()} of $amount recorded (mock)')),
    );
  }

  String _typeLabel() => switch (_type) {
        _AdjustmentType.receive => 'Receive',
        _AdjustmentType.waste => 'Waste',
        _AdjustmentType.correction => 'Correction',
      };
}

enum _AdjustmentType { receive, waste, correction }

String _pieceLabel(StockItem item) {
  if (item.pieceSize <= 1) return item.baseUnit;
  return '${item.pieceSize} ${item.baseUnit} per piece';
}
