import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/domain/utils/stock_quantity_formatter.dart';
import 'package:modular_pos/features/inventory/ui/view/restock_stock_item/restock_stock_item_utils.dart';
import 'package:modular_pos/features/inventory/ui/view/restock_stock_item/widgets/restock_branch_selector.dart';
import 'package:modular_pos/features/inventory/ui/view/restock_stock_item/widgets/restock_quantity_inputs.dart';
import 'package:modular_pos/features/inventory/ui/view/restock_stock_item/widgets/restock_stock_item_autocomplete.dart';
import 'package:modular_pos/features/inventory/ui/view/restock_stock_item/widgets/restock_stock_summary.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_journal_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_state.dart';

class RestockStockItemPage extends ConsumerStatefulWidget {
  const RestockStockItemPage({super.key});

  @override
  ConsumerState<RestockStockItemPage> createState() =>
      _RestockStockItemPageState();
}

class _RestockStockItemPageState extends ConsumerState<RestockStockItemPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedBranchId;
  String? _selectedItemId;
  bool _isSaving = false;
  bool _hasShownNoItemsDialog = false;
  TextEditingController? _itemCtrl;
  final _pcsCtrl = TextEditingController(text: '0');
  final _extraCtrl = TextEditingController(text: '0');
  final _priceCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _itemCtrl = TextEditingController();
    _dateCtrl.text = formatYyyyMmDd(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branches =
          ref.read(loginControllerProvider).user?.branches ??
          const <UserBranch>[];
      final initialBranchId = branches.length == 1
          ? (branches.first.branchId.isNotEmpty
                ? branches.first.branchId
                : branches.first.id)
          : null;
      setState(() => _selectedBranchId = initialBranchId);
      ref
          .read(stockInventoryControllerProvider.notifier)
          .loadStockItems(branchId: initialBranchId);
    });
  }

  @override
  void dispose() {
    _itemCtrl?.dispose();
    _pcsCtrl.dispose();
    _extraCtrl.dispose();
    _priceCtrl.dispose();
    _supplierCtrl.dispose();
    _noteCtrl.dispose();
    _dateCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(stockInventoryControllerProvider);
    final items = inventoryState.items;

    if (!inventoryState.isLoading && items.isEmpty && !_hasShownNoItemsDialog) {
      _hasShownNoItemsDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleEmptyInventory(context);
      });
    }

    if (inventoryState.isLoading && items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Restock inventory'),
          centerTitle: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) {
      // Dialog is scheduled above; show an empty scaffold so only the dialog is visible.
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Restock inventory'),
          centerTitle: false,
        ),
        body: const SizedBox.shrink(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Restock inventory'),
        centerTitle: false,
      ),
      body: _buildForm(context, inventoryState, items),
    );
  }

  Widget _buildForm(
    BuildContext context,
    StockInventoryState inventoryState,
    List<StockItem> items,
  ) {
    final userBranches =
        ref.watch(loginControllerProvider).user?.branches ??
        const <UserBranch>[];
    final branchEntries = buildBranchEntries(items, userBranches);
    if (_selectedBranchId == null && branchEntries.isNotEmpty) {
      _selectedBranchId = branchEntries.first.key;
    }

    final branchId = _selectedBranchId;
    final branchItems = branchId == null
        ? const <StockItem>[]
        : itemsForBranch(items, branchId);
    final hasItemSelection =
        branchItems.any((item) => item.id == _selectedItemId) &&
        _selectedItemId != null;
    final selectedItem = hasItemSelection
        ? branchItems.firstWhere((item) => item.id == _selectedItemId)
        : null;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (items.isEmpty) ...[
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'No stock items are available for restocking yet. Create a stock item first, then return here to record restock.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final router = GoRouter.of(context);
                        await router.push(AppRoute.inventoryAddItem.path);
                        if (!mounted) return;
                        ref
                            .read(stockInventoryControllerProvider.notifier)
                            .loadStockItems();
                        // After creating an item, navigate to the stock list page
                        router.go(AppRoute.inventoryStockItems.path);
                      },
                      child: const Text('Create Stock Item'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Provide the branch, item, and quantity received. Restock batches are stored in base units (quantityInBaseUnit) even when you enter pieces and extras here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          RestockBranchSelector(
            entries: branchEntries,
            selectedBranchId: _selectedBranchId,
            onChanged: (value) {
              setState(() {
                _selectedBranchId = value;
                _selectedItemId = null;
                _itemCtrl?.clear();
                _pcsCtrl.text = '0';
                _extraCtrl.text = '0';
                _submitError = null;
              });
              ref
                  .read(stockInventoryControllerProvider.notifier)
                  .loadStockItems(branchId: value == 'all' ? null : value);
            },
            enabled: branchEntries.length > 1,
          ),
          const SizedBox(height: 12),
          RestockStockItemAutocomplete(
            items: branchItems,
            controller: _itemCtrl,
            selectedItemId: hasItemSelection ? _selectedItemId : null,
            onSelected: (item) {
              setState(() {
                _selectedItemId = item.id;
                _itemCtrl?.text = item.name;
                _pcsCtrl.text = '0';
                _extraCtrl.text = '0';
                _submitError = null;
              });
            },
            onCleared: () => setState(() {
              _selectedItemId = null;
              _submitError = null;
            }),
            onTapEmpty: () {
              final fallback = userBranches.isNotEmpty
                  ? (userBranches.first.branchId.isNotEmpty
                        ? userBranches.first.branchId
                        : userBranches.first.id)
                  : null;
              ref
                  .read(stockInventoryControllerProvider.notifier)
                  .loadStockItems(branchId: fallback);
            },
          ),
          const SizedBox(height: 16),
          if (selectedItem != null)
            RestockQuantityInputs(
              item: selectedItem,
              pcsCtrl: _pcsCtrl,
              extraCtrl: _extraCtrl,
            ),
          if (selectedItem != null) ...[
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: Listenable.merge([_pcsCtrl, _extraCtrl]),
              builder: (context, _) {
                return Text(
                  'Recorded quantity in base units: ${_formatBaseQuantity(selectedItem)}',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _supplierCtrl,
            decoration: const InputDecoration(
              labelText: 'Supplier name (optional)',
              hintText: 'Enter supplier name',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Purchase cost (USD, optional)',
              prefixText: '\$ ',
              hintText: 'Enter amount',
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return null;
              final price = double.tryParse(trimmed);
              if (price == null || price < 0) {
                return 'Enter a valid purchase cost';
              }
              return null;
            },
          ),
          if (selectedItem != null) ...[
            const SizedBox(height: 12),
            RestockStockSummary(item: selectedItem),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _dateCtrl,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Received date',
              hintText: 'Select date',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_dateCtrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear date',
                      onPressed: () => setState(_dateCtrl.clear),
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: _pickDate,
                  ),
                ],
              ),
            ),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _expiryCtrl,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Expiry date (optional)',
              hintText: 'Select date',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_expiryCtrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear date',
                      onPressed: () => setState(_expiryCtrl.clear),
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: _pickExpiry,
                  ),
                ],
              ),
            ),
            onTap: _pickExpiry,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteCtrl,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: inventoryState.isLoading || _isSaving
                ? null
                : () => _submit(selectedItem),
            child: const Text('Record restock'),
          ),
          if (_submitError != null) ...[
            const SizedBox(height: 12),
            Text(
              _submitError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleEmptyInventory(BuildContext context) async {
    final router = GoRouter.of(context);

    final create = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Text('Stock items required'),
              const Spacer(),
              IconButton(
                tooltip: 'Cancel',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
          content: const Text(
            'Restock requires at least one stock item. Create a stock item first, then continue with restocking.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Create Stock Item'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (create == true) {
      await router.push(AppRoute.inventoryAddItem.path);
      if (!mounted) return;
      ref.read(stockInventoryControllerProvider.notifier).loadStockItems();
      // After creating an item, go to the stock list page
      router.go(AppRoute.inventoryStockItems.path);
    } else {
      router.pop();
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = parseYyyyMmDd(_dateCtrl.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _dateCtrl.text = formatYyyyMmDd(picked));
    }
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final initial = parseYyyyMmDd(_expiryCtrl.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() => _expiryCtrl.text = formatYyyyMmDd(picked));
    }
  }

  Future<void> _submit(StockItem? item) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (item == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an item to restock')),
      );
      return;
    }
    final priceText = _priceCtrl.text.trim();
    final price = priceText.isEmpty ? null : double.tryParse(priceText);
    if (priceText.isNotEmpty && (price == null || price < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid purchase cost')),
      );
      return;
    }

    final pcs = int.tryParse(_pcsCtrl.text.trim()) ?? 0;
    final extra = item.pieceSize > 1
        ? int.tryParse(_extraCtrl.text.trim()) ?? 0
        : 0;
    final baseQty = item.pieceSize > 1 ? pcs * item.pieceSize + extra : pcs;
    if (baseQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be greater than zero')),
      );
      return;
    }
    setState(() {
      _isSaving = true;
      _submitError = null;
    });
    try {
      await ref
          .read(stockInventoryControllerProvider.notifier)
          .createRestockBatch(
            itemId: item.id,
            baseQty: baseQty,
            restockDate: _dateCtrl.text.isEmpty
                ? formatYyyyMmDd(DateTime.now())
                : _dateCtrl.text,
            expiryDate: _expiryCtrl.text.isEmpty ? null : _expiryCtrl.text,
            supplierName: _supplierCtrl.text.trim().isEmpty
                ? null
                : _supplierCtrl.text.trim(),
            purchaseCostUsd: price,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            branchId: _selectedBranchId,
          );

      final actor = ref.read(loginControllerProvider).user?.name ?? 'System';
      final restockDate = _dateCtrl.text.isEmpty
          ? null
          : parseYyyyMmDd(_dateCtrl.text);
      final occurredAt = restockDate ?? DateTime.now();
      ref
          .read(inventoryJournalControllerProvider.notifier)
          .recordEntry(
            InventoryJournalEntry(
              id: 'jr-${DateTime.now().microsecondsSinceEpoch}',
              itemId: item.id,
              itemName: item.name,
              branchId: _selectedBranchId ?? item.branchId,
              branchName: item.branchName,
              reason: InventoryJournalReason.restock,
              delta: baseQty,
              note: _noteCtrl.text.trim().isEmpty
                  ? 'Restock recorded'
                  : _noteCtrl.text.trim(),
              actor: actor,
              createdAt: DateTime.now(),
              occurredAt: occurredAt,
            ),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_buildSuccessMessage(item, baseQty, price))),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to record restock.',
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

  bool _showInlineSubmitError(InventoryErrorCode code) {
    switch (code) {
      case InventoryErrorCode.stockItemInactive:
      case InventoryErrorCode.quantityInvalid:
      case InventoryErrorCode.adjustmentInvalid:
      case InventoryErrorCode.restockBatchArchived:
      case InventoryErrorCode.restockBatchNotFound:
        return true;
      default:
        return isInventoryAccessErrorCode(code);
    }
  }

  String _formatBaseQuantity(StockItem item) {
    final pcs = int.tryParse(_pcsCtrl.text.trim()) ?? 0;
    final extra = item.pieceSize > 1
        ? int.tryParse(_extraCtrl.text.trim()) ?? 0
        : 0;
    final baseQty = item.pieceSize > 1 ? pcs * item.pieceSize + extra : pcs;
    return StockQuantityFormatter(
      baseQty: baseQty,
      pieceSize: 1,
      baseUnit: item.baseUnit,
    ).format();
  }

  String _buildSuccessMessage(StockItem item, int baseQty, double? price) {
    final quantity = StockQuantityFormatter(
      baseQty: baseQty,
      pieceSize: item.pieceSize,
      baseUnit: item.baseUnit,
    ).format();
    final details = <String>[
      if (price != null) 'purchase cost \$${price.toStringAsFixed(2)}',
      _expiryCtrl.text.isEmpty ? 'no expiry' : 'expires ${_expiryCtrl.text}',
    ];
    return 'Recorded $quantity for ${item.name} (${details.join(', ')})';
  }
}
