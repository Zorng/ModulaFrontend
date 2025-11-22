import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/domain/utils/stock_quantity_formatter.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';

class AdjustStockQuantityPage extends ConsumerStatefulWidget {
  const AdjustStockQuantityPage({super.key, required this.item});

  final StockItem item;

  @override
  ConsumerState<AdjustStockQuantityPage> createState() =>
      _AdjustStockQuantityPageState();
}

class _AdjustStockQuantityPageState
    extends ConsumerState<AdjustStockQuantityPage> {
  final _pcsCtrl = TextEditingController(text: '0');
  final _baseUnitCtrl = TextEditingController(text: '0');
  final _noteCtrl = TextEditingController();
  _AdjustmentType _type = _AdjustmentType.add;
  String? _selectedBatchId;
  bool _isSaving = false;

  @override
  void dispose() {
    _pcsCtrl.dispose();
    _baseUnitCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final inventoryState = ref.watch(stockInventoryControllerProvider);
    final batches =
        inventoryState.batches
            .where((batch) => batch.stockItemId == item.id)
            .toList()
          ..sort(_compareBatches);
    final resolvedBatchId =
        _selectedBatchId ?? (batches.isNotEmpty ? batches.first.id : null);
    final selectedBatch = resolvedBatchId == null
        ? null
        : batches.firstWhere(
            (batch) => batch.id == resolvedBatchId,
            orElse: () => batches.first,
          );
    return Scaffold(
      appBar: AppBar(title: Text('Adjust ${item.name}'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(item.name),
              subtitle: Text(
                '${item.branchName} • ${item.category} • ${_pieceLabel(item)}',
              ),
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
                    'Min ${StockQuantityFormatter(baseQty: item.minThreshold, pieceSize: item.pieceSize, baseUnit: item.baseUnit).format()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<_AdjustmentType>(
            segments: const [
              ButtonSegment(
                value: _AdjustmentType.add,
                label: Text('Add stock'),
              ),
              ButtonSegment(
                value: _AdjustmentType.reduce,
                label: Text('Reduce stock'),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (value) => setState(() => _type = value.first),
          ),
          const SizedBox(height: 16),
          if (batches.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No batches available yet. Please restock this item first.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InventoryDropdown<String>(
                  initialValue: resolvedBatchId,
                  label: const Text('Batch'),
                  entries: batches
                      .map(
                        (batch) => DropdownMenuEntry(
                          value: batch.id,
                          label:
                              '${batch.receivedDate} · ${batch.expiryDate ?? 'No expiry'}',
                        ),
                      )
                      .toList(),
                  onSelected: (value) =>
                      setState(() => _selectedBatchId = value),
                ),
                const SizedBox(height: 12),
                if (selectedBatch != null)
                  Text(
                    'Batch on hand: ${StockQuantityFormatter(baseQty: selectedBatch.onHand, pieceSize: item.pieceSize, baseUnit: item.baseUnit).format()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          const SizedBox(height: 16),
          _QuantityInputs(
            item: item,
            pcsCtrl: _pcsCtrl,
            baseCtrl: _baseUnitCtrl,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteCtrl,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSaving
                ? null
                : () => _submit(batches, resolvedBatchId),
            child: const Text('Apply adjustment'),
          ),
          const SizedBox(height: 24),
          if (batches.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batches',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ..._buildBatchList(
                      batches: batches,
                      selectedId: resolvedBatchId,
                      item: item,
                      onSelected: (id) => setState(() => _selectedBatchId = id),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submit(List<StockBatch> batches, String? batchId) async {
    final pcs = int.tryParse(_pcsCtrl.text.trim()) ?? 0;
    final base = int.tryParse(_baseUnitCtrl.text.trim()) ?? 0;
    final totalBaseQty = widget.item.pieceSize <= 1
        ? base
        : pcs * widget.item.pieceSize + base;
    if (totalBaseQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a non-zero quantity')),
      );
      return;
    }
    if (batchId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a batch to adjust')));
      return;
    }
    final magnitude = totalBaseQty.abs();
    final delta = _type == _AdjustmentType.add ? magnitude : -magnitude;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(stockInventoryControllerProvider.notifier)
          .adjustBatch(batchId: batchId, delta: delta);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_typeLabel()} of $magnitude applied')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to adjust stock: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _typeLabel() =>
      _type == _AdjustmentType.add ? 'Addition' : 'Reduction';
}

enum _AdjustmentType { add, reduce }

class _QuantityInputs extends StatelessWidget {
  const _QuantityInputs({
    required this.item,
    required this.pcsCtrl,
    required this.baseCtrl,
  });

  final StockItem item;
  final TextEditingController pcsCtrl;
  final TextEditingController baseCtrl;

  @override
  Widget build(BuildContext context) {
    if (item.pieceSize <= 1) {
      return TextFormField(
        controller: baseCtrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Quantity (${item.baseUnit})',
          hintText: 'Enter amount',
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: pcsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Pieces',
              hintText: 'e.g., number of cartons',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: baseCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Extra (${item.baseUnit})',
              hintText: 'Optional remainder',
            ),
          ),
        ),
      ],
    );
  }
}

String _pieceLabel(StockItem item) {
  if (item.pieceSize <= 1) return item.baseUnit;
  return '${item.pieceSize} ${item.baseUnit} per piece';
}

int _compareBatches(StockBatch a, StockBatch b) {
  final aExpiry = a.expiryDate;
  final bExpiry = b.expiryDate;
  if (aExpiry == null && bExpiry == null) {
    return a.receivedDate.compareTo(b.receivedDate);
  }
  if (aExpiry == null) return 1;
  if (bExpiry == null) return -1;
  final cmp = aExpiry.compareTo(bExpiry);
  return cmp == 0 ? a.receivedDate.compareTo(b.receivedDate) : cmp;
}

List<Widget> _buildBatchList({
  required List<StockBatch> batches,
  required String? selectedId,
  required StockItem item,
  required ValueChanged<String> onSelected,
}) {
  final widgets = <Widget>[];
  for (var i = 0; i < batches.length; i++) {
    final batch = batches[i];
    widgets.add(
      ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Restock date: ${batch.receivedDate}'),
            Text('Expiry date: ${batch.expiryDate ?? 'No expiry'}'),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            StockQuantityFormatter(
              baseQty: batch.onHand,
              pieceSize: item.pieceSize,
              baseUnit: item.baseUnit,
            ).format(),
          ),
        ),
        trailing: batch.id == selectedId
            ? const Icon(Icons.check_circle, size: 16)
            : null,
        onTap: () => onSelected(batch.id),
      ),
    );
    if (i < batches.length - 1) {
      widgets.add(const Divider(height: 1));
    }
  }
  return widgets;
}
