import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/inventory/data/branch_stock_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/domain/utils/stock_quantity_formatter.dart';
import 'package:modular_pos/features/inventory/ui/models/inventory_branch_option.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_adjust_quantity/stock_adjust_quantity_utils.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_adjust_quantity/widgets/adjust_quantity_inputs.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_adjust_quantity/widgets/stock_batch_list_card.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_journal_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';

class AdjustStockQuantityPage extends ConsumerStatefulWidget {
  const AdjustStockQuantityPage({
    super.key,
    required this.item,
    this.initialBranchId,
  });

  final StockItem item;
  final String? initialBranchId;

  @override
  ConsumerState<AdjustStockQuantityPage> createState() =>
      _AdjustStockQuantityPageState();
}

class _AdjustStockQuantityPageState
    extends ConsumerState<AdjustStockQuantityPage> {
  final _pcsCtrl = TextEditingController(text: '0');
  final _baseUnitCtrl = TextEditingController(text: '0');
  final _noteCtrl = TextEditingController();
  _AdjustmentMode _mode = _AdjustmentMode.delta;
  _AdjustmentType _type = _AdjustmentType.add;
  _RestockBatchStatus _restockBatchStatus = _RestockBatchStatus.active;
  String? _selectedBranchId;
  int? _selectedBranchOnHand;
  int? _selectedBranchMinThreshold;
  bool _isBranchContextLoading = false;
  String? _selectedBatchId;
  String? _branchError;
  String? _submitError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedBranchId = _normalizeBranchId(widget.initialBranchId);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final branchState = ref.read(branchControllerProvider);
      if (branchState.branches.isEmpty) {
        try {
          await ref.read(branchControllerProvider.notifier).loadInitial();
        } catch (_) {
          // Keep user-branch fallback options when the branch directory fails.
        }
      }
      await _loadSelectedBranchContext();
    });
  }

  @override
  void dispose() {
    _pcsCtrl.dispose();
    _baseUnitCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseItem = widget.item;
    final inventoryState = ref.watch(stockInventoryControllerProvider);
    final loginState = ref.watch(loginControllerProvider);
    final activeTenantId =
        (loginState.session?.activeTenantId ??
                loginState.session?.user.tenantId)
            ?.trim() ??
        '';
    final tenantBranches = ref
        .watch(branchControllerProvider.select((state) => state.branches))
        .where(
          (branch) =>
              activeTenantId.isEmpty ||
              branch.tenantId.trim().isEmpty ||
              branch.tenantId.trim() == activeTenantId,
        )
        .toList(growable: false);
    final branchOptions = buildInventoryBranchOptions(
      items: [baseItem],
      tenantBranches: tenantBranches,
      userBranches: loginState.user?.branches ?? const [],
    ).where((entry) => entry.id != 'all').toList(growable: false);
    final resolvedSelectedBranchId =
        branchOptions.any((entry) => entry.id == _selectedBranchId)
        ? _selectedBranchId
        : null;
    final selectedBranchEntries = branchOptions
        .where((entry) => entry.id == resolvedSelectedBranchId)
        .toList(growable: false);
    final selectedBranchName = selectedBranchEntries.isNotEmpty
        ? selectedBranchEntries.first.name
        : null;
    final effectiveItem = baseItem.copyWith(
      branchId: resolvedSelectedBranchId ?? baseItem.branchId,
      branchName: selectedBranchName ?? baseItem.branchName,
      onHand: resolvedSelectedBranchId == null
          ? baseItem.onHand
          : (_selectedBranchOnHand ?? 0),
      minThreshold: resolvedSelectedBranchId == null
          ? baseItem.minThreshold
          : (_selectedBranchMinThreshold ?? baseItem.minThreshold),
    );
    final batches =
        resolvedSelectedBranchId == null
              ? <StockBatch>[]
              : inventoryState.batches
                    .where(
                      (batch) =>
                          batch.stockItemId == baseItem.id &&
                          batch.branchId == resolvedSelectedBranchId,
                    )
                    .toList()
          ..sort(compareBatches);
    final resolvedBatchId =
        _selectedBatchId != null &&
            batches.any((batch) => batch.id == _selectedBatchId)
        ? _selectedBatchId
        : (batches.isNotEmpty ? batches.first.id : null);
    final selectedBatch = resolvedBatchId == null
        ? null
        : batches.firstWhere((batch) => batch.id == resolvedBatchId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Adjust ${baseItem.name}'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(baseItem.name),
              subtitle: Text(
                '${selectedBranchName ?? 'No branch selected'} • ${_pieceLabel(effectiveItem)}',
              ),
              trailing:
                  _isBranchContextLoading && resolvedSelectedBranchId != null
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          StockQuantityFormatter(
                            baseQty: effectiveItem.onHand,
                            pieceSize: effectiveItem.pieceSize,
                            baseUnit: effectiveItem.baseUnit,
                          ).format(),
                        ),
                        Text(
                          'Min ${StockQuantityFormatter(baseQty: effectiveItem.minThreshold, pieceSize: effectiveItem.pieceSize, baseUnit: effectiveItem.baseUnit).format()}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          InventoryDropdown<String>(
            key: ValueKey(
              'adjust-branch-${resolvedSelectedBranchId ?? 'none'}',
            ),
            initialValue: resolvedSelectedBranchId,
            label: const Text('Branch'),
            hintText: 'Select branch',
            enabled: branchOptions.isNotEmpty,
            entries: branchOptions
                .map(
                  (branch) => DropdownMenuEntry<String>(
                    value: branch.id,
                    label: branch.name,
                  ),
                )
                .toList(),
            helperText: branchOptions.isEmpty
                ? 'No branches are available for adjustment.'
                : resolvedSelectedBranchId == null
                ? 'Select a branch to load branch stock and restock batches.'
                : _isBranchContextLoading
                ? 'Loading branch stock and restock batches.'
                : null,
            errorText: _branchError,
            onSelected: (value) async {
              final selected = _normalizeBranchId(value);
              setState(() {
                _selectedBranchId = selected;
                _selectedBatchId = null;
                _branchError = null;
                _submitError = null;
              });
              await _loadSelectedBranchContext(showBatchError: true);
            },
          ),
          const SizedBox(height: 16),
          SegmentedButton<_AdjustmentMode>(
            segments: const [
              ButtonSegment(
                value: _AdjustmentMode.delta,
                label: Text('Adjust by amount'),
              ),
              ButtonSegment(
                value: _AdjustmentMode.setToCount,
                label: Text('Set counted stock'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (value) => setState(() {
              _mode = value.first;
              _submitError = null;
            }),
          ),
          const SizedBox(height: 16),
          if (_mode == _AdjustmentMode.delta)
            SegmentedButton<_AdjustmentType>(
              segments: const [
                ButtonSegment(value: _AdjustmentType.add, label: Text('Add')),
                ButtonSegment(
                  value: _AdjustmentType.reduce,
                  label: Text('Remove'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (value) => setState(() {
                _type = value.first;
                _submitError = null;
              }),
            ),
          if (_mode == _AdjustmentMode.delta) const SizedBox(height: 16),
          InventoryDropdown<_RestockBatchStatus>(
            initialValue: _restockBatchStatus,
            label: const Text('Batch status'),
            entries: _RestockBatchStatus.values
                .map(
                  (status) => DropdownMenuEntry<_RestockBatchStatus>(
                    value: status,
                    label: status.label,
                  ),
                )
                .toList(),
            onSelected: (value) async {
              final selected = value ?? _RestockBatchStatus.active;
              setState(() {
                _restockBatchStatus = selected;
                _selectedBatchId = null;
                _submitError = null;
              });
              await _loadSelectedBranchContext(showBatchError: true);
            },
          ),
          const SizedBox(height: 12),
          if (resolvedSelectedBranchId != null &&
              (inventoryState.isBatchesLoading || _isBranchContextLoading) &&
              batches.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (resolvedSelectedBranchId == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Select a branch first. Adjustments and batch data apply to one branch at a time.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else if (batches.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Batch tracking is not available yet for the selected branch. Adjustments apply to the branch total on-hand quantity for this item.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Batches are shown for reference only. Inventory adjustments apply to the selected branch total, not an individual batch.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                InventoryDropdown<String>(
                  key: ValueKey('adjust-batch-${resolvedBatchId ?? 'none'}'),
                  initialValue: resolvedBatchId,
                  label: const Text('Batch'),
                  entries: batches
                      .map(
                        (batch) => DropdownMenuEntry<String>(
                          value: batch.id,
                          label:
                              '${batch.receivedDate} · ${batch.expiryDate ?? 'No expiry'}',
                        ),
                      )
                      .toList(),
                  onSelected: (value) => setState(() {
                    _selectedBatchId = value;
                    _submitError = null;
                  }),
                ),
                const SizedBox(height: 12),
                if (selectedBatch != null)
                  Text(
                    'Batch on hand: ${StockQuantityFormatter(baseQty: selectedBatch.onHand, pieceSize: effectiveItem.pieceSize, baseUnit: effectiveItem.baseUnit).format()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          const SizedBox(height: 16),
          AdjustQuantityInputs(
            item: effectiveItem,
            pcsCtrl: _pcsCtrl,
            baseCtrl: _baseUnitCtrl,
            mode: _mode == _AdjustmentMode.delta
                ? AdjustQuantityInputMode.delta
                : AdjustQuantityInputMode.setToCount,
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: Listenable.merge([_pcsCtrl, _baseUnitCtrl]),
            builder: (context, _) {
              final enteredBaseQty = _enteredBaseQuantity(effectiveItem);
              if (enteredBaseQty == null) {
                return Text(
                  'Enter non-negative whole numbers for quantity fields.',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }
              final projectedOnHand = _mode == _AdjustmentMode.setToCount
                  ? enteredBaseQty
                  : effectiveItem.onHand +
                        (_type == _AdjustmentType.add
                            ? enteredBaseQty
                            : -enteredBaseQty);
              return Text(
                _mode == _AdjustmentMode.setToCount
                    ? 'Counted total in base units: ${_formatBaseUnits(effectiveItem, enteredBaseQty)}'
                    : 'Projected on-hand after adjustment: ${_formatProjectedOnHand(effectiveItem, projectedOnHand)}',
                style: Theme.of(context).textTheme.bodySmall,
              );
            },
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
                : () => _submit(
                    effectiveItem,
                    batches,
                    resolvedBatchId,
                    selectedBranchName: selectedBranchName,
                  ),
            child: const Text('Apply adjustment'),
          ),
          if (_submitError != null) ...[
            const SizedBox(height: 12),
            Text(
              _submitError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          if (batches.isNotEmpty)
            StockBatchListCard(
              batches: batches,
              selectedId: resolvedBatchId,
              item: effectiveItem,
              onSelected: (id) => setState(() => _selectedBatchId = id),
            ),
          if (resolvedSelectedBranchId != null &&
              inventoryState.isLoadingMoreBatches)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (resolvedSelectedBranchId != null &&
              inventoryState.hasMoreRestockBatches &&
              !inventoryState.isBatchesLoading)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: OutlinedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await ref
                          .read(stockInventoryControllerProvider.notifier)
                          .loadMoreRestockBatches();
                    } catch (_) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Failed to load more restock batches'),
                        ),
                      );
                    }
                  },
                  child: const Text('Load more batches'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submit(
    StockItem item,
    List<StockBatch> batches,
    String? batchId, {
    String? selectedBranchName,
  }) async {
    final selectedBranchId = _normalizeBranchId(_selectedBranchId);
    if (selectedBranchId == null) {
      setState(() {
        _branchError = 'Please select a branch';
        _submitError = null;
      });
      return;
    }

    final totalBaseQty = _enteredBaseQuantity(item);
    if (totalBaseQty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter non-negative whole numbers for quantity'),
        ),
      );
      return;
    }
    final allowsZero = _mode == _AdjustmentMode.setToCount;
    if ((allowsZero && totalBaseQty < 0) ||
        (!allowsZero && totalBaseQty <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mode == _AdjustmentMode.setToCount
                ? 'Enter a counted quantity of 0 or more'
                : 'Enter a non-zero quantity',
          ),
        ),
      );
      return;
    }
    if (_mode == _AdjustmentMode.setToCount && totalBaseQty == item.onHand) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Count already matches current on-hand')),
      );
      return;
    }

    final effectiveBatchId =
        batchId ?? (batches.isNotEmpty ? batches.first.id : null);
    final magnitude = totalBaseQty.abs();
    final delta = _type == _AdjustmentType.add ? magnitude : -magnitude;
    final adjustmentDelta = _mode == _AdjustmentMode.setToCount
        ? totalBaseQty - item.onHand
        : delta;

    setState(() {
      _isSaving = true;
      _branchError = null;
      _submitError = null;
    });

    try {
      await ref
          .read(stockInventoryControllerProvider.notifier)
          .applyInventoryAdjustment(
            stockItemId: widget.item.id,
            branchId: selectedBranchId,
            batchId: effectiveBatchId,
            style: _mode == _AdjustmentMode.setToCount
                ? 'SET_TO_COUNT'
                : 'DELTA',
            delta: _mode == _AdjustmentMode.delta ? delta : null,
            countedOnHandInBaseUnit: _mode == _AdjustmentMode.setToCount
                ? totalBaseQty
                : null,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          );
      final actor = ref.read(loginControllerProvider).user?.name ?? 'System';
      ref
          .read(inventoryJournalControllerProvider.notifier)
          .recordEntry(
            InventoryJournalEntry(
              id: 'ja-${DateTime.now().microsecondsSinceEpoch}',
              itemId: widget.item.id,
              itemName: widget.item.name,
              branchId: selectedBranchId,
              branchName: selectedBranchName ?? selectedBranchId,
              reason: adjustmentDelta < 0
                  ? InventoryJournalReason.remove
                  : InventoryJournalReason.add,
              delta: adjustmentDelta,
              note: _noteCtrl.text.trim().isEmpty
                  ? _defaultAdjustmentNote()
                  : _noteCtrl.text.trim(),
              actor: actor,
              createdAt: DateTime.now(),
              occurredAt: DateTime.now(),
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_successMessage(magnitude, totalBaseQty))),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to adjust stock.',
      );
      if (_showInlineSubmitError(mapped.code)) {
        setState(() => _submitError = mapped.message);
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapped.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _loadSelectedBranchContext({bool showBatchError = false}) async {
    final branchId = _normalizeBranchId(_selectedBranchId);
    if (branchId == null) {
      if (!mounted) return;
      setState(() {
        _selectedBranchOnHand = null;
        _selectedBranchMinThreshold = null;
        _isBranchContextLoading = false;
      });
      return;
    }

    if (mounted) {
      setState(() => _isBranchContextLoading = true);
    }

    try {
      final onHandRecords = await ref
          .read(branchStockRepositoryProvider)
          .fetchOnHand(branchId: branchId);
      final matchingRecords = onHandRecords
          .where((record) => record.stockItemId == widget.item.id)
          .toList(growable: false);
      final matchingRecord = matchingRecords.isNotEmpty
          ? matchingRecords.first
          : null;
      if (!mounted) return;
      setState(() {
        _selectedBranchOnHand = matchingRecord?.onHand ?? 0;
        _selectedBranchMinThreshold =
            matchingRecord?.minThreshold ?? widget.item.minThreshold;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedBranchOnHand = 0;
        _selectedBranchMinThreshold = widget.item.minThreshold;
      });
    }

    try {
      await ref
          .read(stockInventoryControllerProvider.notifier)
          .loadRestockBatches(
            branchId: branchId,
            status: _restockBatchStatus.apiValue,
            stockItemId: widget.item.id,
          );
    } catch (_) {
      if (!mounted || !showBatchError) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load restock batches')),
      );
    } finally {
      if (mounted) {
        setState(() => _isBranchContextLoading = false);
      }
    }
  }

  bool _showInlineSubmitError(InventoryErrorCode code) {
    switch (code) {
      case InventoryErrorCode.stockItemInactive:
      case InventoryErrorCode.quantityInvalid:
      case InventoryErrorCode.adjustmentInvalid:
      case InventoryErrorCode.restockBatchArchived:
      case InventoryErrorCode.restockBatchNotFound:
      case InventoryErrorCode.negativeStockBlocked:
        return true;
      default:
        return isInventoryAccessErrorCode(code);
    }
  }

  String _typeLabel() =>
      _type == _AdjustmentType.add ? 'Addition' : 'Reduction';

  int? _enteredBaseQuantity(StockItem item) {
    final pcs = _parseNonNegative(_pcsCtrl.text);
    final base = _parseNonNegative(_baseUnitCtrl.text);
    if (pcs == null || base == null) return null;
    return item.pieceSize <= 1 ? base : pcs * item.pieceSize + base;
  }

  int? _parseNonNegative(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 0;
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }

  String _formatBaseUnits(StockItem item, int baseQty) {
    return StockQuantityFormatter(
      baseQty: baseQty,
      pieceSize: 1,
      baseUnit: item.baseUnit,
    ).format();
  }

  String _formatProjectedOnHand(StockItem item, int projectedOnHand) {
    if (projectedOnHand < 0) return 'Would go below zero';
    return StockQuantityFormatter(
      baseQty: projectedOnHand,
      pieceSize: item.pieceSize,
      baseUnit: item.baseUnit,
    ).format();
  }

  String _defaultAdjustmentNote() {
    if (_mode == _AdjustmentMode.setToCount) {
      return 'Counted stock correction';
    }
    return _type == _AdjustmentType.add
        ? 'Manual addition'
        : 'Manual reduction';
  }

  String _successMessage(int magnitude, int countedTotal) {
    if (_mode == _AdjustmentMode.setToCount) {
      return 'Counted stock set to ${_formatBaseUnits(widget.item, countedTotal)}';
    }
    return '${_typeLabel()} of $magnitude applied';
  }

  String? _normalizeBranchId(String? branchId) {
    final trimmed = branchId?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == 'all') return null;
    return trimmed;
  }
}

enum _AdjustmentMode { delta, setToCount }

enum _AdjustmentType { add, reduce }

enum _RestockBatchStatus {
  active('Active', 'active'),
  archived('Archived', 'archived'),
  all('All statuses', 'all');

  const _RestockBatchStatus(this.label, this.apiValue);

  final String label;
  final String apiValue;
}

String _pieceLabel(StockItem item) => pieceLabel(item);
