import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/domain/utils/stock_quantity_formatter.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_journal_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_adjust_quantity/stock_adjust_quantity_utils.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_adjust_quantity/widgets/adjust_quantity_inputs.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_adjust_quantity/widgets/stock_batch_list_card.dart';
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
          ..sort(compareBatches);
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
              subtitle: Text('${item.branchName} • ${_pieceLabel(item)}'),
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
              ButtonSegment(value: _AdjustmentType.add, label: Text('Add')),
              ButtonSegment(
                value: _AdjustmentType.reduce,
                label: Text('Remove'),
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
                'Batch tracking is not available yet. Adjustments will apply to the total on-hand quantity.',
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
          AdjustQuantityInputs(
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
            StockBatchListCard(
              batches: batches,
              selectedId: resolvedBatchId,
              item: item,
              onSelected: (id) => setState(() => _selectedBatchId = id),
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
    final effectiveBatchId =
        batchId ?? (batches.isEmpty ? widget.item.id : null);
    if (effectiveBatchId == null) {
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
          .adjustBatch(batchId: effectiveBatchId, delta: delta);
      final actor = ref.read(loginControllerProvider).user?.name ?? 'System';
      ref
          .read(inventoryJournalControllerProvider.notifier)
          .recordEntry(
            InventoryJournalEntry(
              id: 'ja-${DateTime.now().microsecondsSinceEpoch}',
              itemId: widget.item.id,
              itemName: widget.item.name,
              branchId: widget.item.branchId,
              branchName: widget.item.branchName,
              reason: _type == _AdjustmentType.add
                  ? InventoryJournalReason.add
                  : InventoryJournalReason.remove,
              delta: delta,
              note: _noteCtrl.text.trim().isEmpty
                  ? _type == _AdjustmentType.add
                        ? 'Manual addition'
                        : 'Manual reduction'
                  : _noteCtrl.text.trim(),
              actor: actor,
              createdAt: DateTime.now(),
              occurredAt: DateTime.now(),
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_typeLabel()} of $magnitude applied')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to adjust stock.',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapped.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _typeLabel() =>
      _type == _AdjustmentType.add ? 'Addition' : 'Reduction';
}

enum _AdjustmentType { add, reduce }

String _pieceLabel(StockItem item) => pieceLabel(item);
