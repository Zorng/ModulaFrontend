import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
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
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';

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
  TextEditingController? _itemCtrl;
  final _pcsCtrl = TextEditingController(text: '0');
  final _extraCtrl = TextEditingController(text: '0');
  final _priceCtrl = TextEditingController(text: '0');
  final _noteCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _itemCtrl = TextEditingController();
    _dateCtrl.text = formatYyyyMmDd(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branches =
          ref.read(loginControllerProvider).user?.branches ?? const <UserBranch>[];
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
    _noteCtrl.dispose();
    _dateCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(stockInventoryControllerProvider);
    final userBranches =
        ref.watch(loginControllerProvider).user?.branches ?? const <UserBranch>[];
    final items = inventoryState.items;

    final branchEntries = buildBranchEntries(items, userBranches);
    if (_selectedBranchId == null && branchEntries.isNotEmpty) {
      _selectedBranchId = branchEntries.first.key;
    }

    final branchId = _selectedBranchId;
    final branchItems = branchId == null ? const <StockItem>[] : itemsForBranch(items, branchId);
    final hasItemSelection =
        branchItems.any((item) => item.id == _selectedItemId) && _selectedItemId != null;
    final selectedItem = hasItemSelection
        ? branchItems.firstWhere((item) => item.id == _selectedItemId)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Restock inventory'), centerTitle: false),
      body: inventoryState.isLoading && items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text('No stock items have been created yet.'))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Provide the branch, item, and quantity received. We keep track using base units (ml/g/pcs) behind the scenes.',
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
                          });
                          ref.read(stockInventoryControllerProvider.notifier).loadStockItems(
                                branchId: value == 'all' ? null : value,
                              );
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
                          });
                        },
                        onCleared: () => setState(() => _selectedItemId = null),
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
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Cost price per delivery',
                          prefixText: '\$ ',
                          hintText: 'Enter amount',
                        ),
                        validator: (value) {
                          final price = double.tryParse(value?.trim() ?? '');
                          if (price == null || price < 0) return 'Enter a valid price';
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
                          labelText: 'Restock date',
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
                    ],
                  ),
                ),
    );
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
    if (picked != null) setState(() => _dateCtrl.text = formatYyyyMmDd(picked));
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
    if (picked != null) setState(() => _expiryCtrl.text = formatYyyyMmDd(picked));
  }

  Future<void> _submit(StockItem? item) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (item == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an item to restock')),
      );
      return;
    }
    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid price')),
      );
      return;
    }
    setState(() => _isSaving = true);

    final pcs = int.tryParse(_pcsCtrl.text.trim()) ?? 0;
    final extra =
        item.pieceSize > 1 ? int.tryParse(_extraCtrl.text.trim()) ?? 0 : 0;
    final baseQty = item.pieceSize > 1 ? pcs * item.pieceSize + extra : pcs;
    if (baseQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be greater than zero')),
      );
      return;
    }
    try {
      await ref.read(stockInventoryControllerProvider.notifier).restockItem(
            itemId: item.id,
            baseQty: baseQty,
            restockDate: _dateCtrl.text.isEmpty
                ? formatYyyyMmDd(DateTime.now())
                : _dateCtrl.text,
            expiryDate: _expiryCtrl.text.isEmpty ? null : _expiryCtrl.text,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            branchId: _selectedBranchId,
          );

      final actor = ref.read(loginControllerProvider).user?.name ?? 'System';
      final restockDate = _dateCtrl.text.isEmpty ? null : parseYyyyMmDd(_dateCtrl.text);
      final occurredAt = restockDate ?? DateTime.now();
      ref.read(inventoryJournalControllerProvider.notifier).recordEntry(
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
        SnackBar(
          content: Text(
            'Recorded ${StockQuantityFormatter(baseQty: baseQty, pieceSize: item.pieceSize, baseUnit: item.baseUnit).format()} for ${item.name} at \$${price.toStringAsFixed(2)} (${_expiryCtrl.text.isEmpty ? 'no expiry' : 'expires ${_expiryCtrl.text}'})',
          ),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserErrorMessage.build(
              context: 'Failed to record restock',
              error: e,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
