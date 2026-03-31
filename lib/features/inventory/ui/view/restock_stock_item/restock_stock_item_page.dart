import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/inventory/data/branch_stock_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_journal_entry.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/domain/utils/restock_timestamp.dart';
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
import 'package:modular_pos/features/inventory/ui/widgets/inventory_field_label.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_section_card.dart';
import 'package:modular_pos/features/inventory/ui/widgets/stock_items_required_dialog.dart';

class RestockStockItemPage extends ConsumerStatefulWidget {
  const RestockStockItemPage({super.key});

  @override
  ConsumerState<RestockStockItemPage> createState() =>
      _RestockStockItemPageState();
}

class _RestockStockItemPageState extends ConsumerState<RestockStockItemPage> {
  static const double _sectionCardElevation = 0;
  static const double _sectionRowSpacing = 16;
  final _formKey = GlobalKey<FormState>();
  String? _selectedBranchId;
  String? _selectedItemId;
  bool _isSaving = false;
  bool _isCheckingStockItems = true;
  bool _hasShownNoItemsDialog = false;
  TextEditingController? _itemCtrl;
  final _pcsCtrl = TextEditingController();
  final _extraCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  String? _submitError;
  StockItem? _selectedItemSummary;
  String? _selectedItemSummaryItemId;
  String? _selectedItemSummaryBranchId;
  bool _isSelectedItemSummaryLoading = false;
  int _selectedItemSummaryRequestId = 0;

  @override
  void initState() {
    super.initState();
    _itemCtrl = TextEditingController();
    _dateCtrl.text = formatYyyyMmDd(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(branchControllerProvider.notifier).loadInitial();
      ref
          .read(stockInventoryControllerProvider.notifier)
          .loadStockItems()
          .whenComplete(() {
            if (!mounted) return;
            setState(() => _isCheckingStockItems = false);
          });
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
    final items = inventoryState.stockItems;

    if (!_isCheckingStockItems &&
        !inventoryState.isLoading &&
        inventoryState.error == null &&
        items.isEmpty &&
        !_hasShownNoItemsDialog) {
      _hasShownNoItemsDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleEmptyInventory(context);
      });
    }

    if ((_isCheckingStockItems || inventoryState.isLoading) && items.isEmpty) {
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
    final isWide = !AppBreakpoints.isSmall(MediaQuery.of(context).size.width);
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
    final branchEntries = buildBranchEntries(
      items,
      tenantBranches: tenantBranches,
      fallbackBranches: loginState.user?.branches ?? const <UserBranch>[],
    );

    final branchItems = [...items]..sort((a, b) => a.name.compareTo(b.name));
    final hasItemSelection =
        branchItems.any((item) => item.id == _selectedItemId) &&
        _selectedItemId != null;
    final selectedItem = hasItemSelection
        ? branchItems.firstWhere((item) => item.id == _selectedItemId)
        : null;
    final selectedSummaryItem = _resolvedSelectedItemSummary(
      selectedItem,
      branchEntries,
    );
    final branchSelector = RestockBranchSelector(
      entries: branchEntries,
      selectedBranchId: _selectedBranchId,
      onChanged: (value) {
        setState(() {
          _selectedBranchId = value;
          _submitError = null;
        });
        unawaited(_refreshSelectedItemSummary(selectedItem, branchEntries));
      },
    );
    final stockItemField = RestockStockItemAutocomplete(
      items: branchItems,
      controller: _itemCtrl,
      selectedItemId: hasItemSelection ? _selectedItemId : null,
      onSelected: (item) {
        setState(() {
          _selectedItemId = item.id;
          _itemCtrl?.text = item.name;
          _pcsCtrl.clear();
          _extraCtrl.clear();
          _submitError = null;
        });
        unawaited(_refreshSelectedItemSummary(item, branchEntries));
      },
      onCleared: () => setState(() {
        _selectedItemSummaryRequestId++;
        _selectedItemId = null;
        _pcsCtrl.clear();
        _extraCtrl.clear();
        _selectedItemSummary = null;
        _selectedItemSummaryItemId = null;
        _selectedItemSummaryBranchId = null;
        _isSelectedItemSummaryLoading = false;
        _submitError = null;
      }),
      onTapEmpty: () {
        ref.read(stockInventoryControllerProvider.notifier).loadStockItems();
      },
    );
    final receivedDateField = InventoryFieldLabel(
      text: 'Received date',
      isRequired: true,
      child: TextFormField(
        controller: _dateCtrl,
        readOnly: true,
        decoration: InputDecoration(
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
    );
    final detailFields = isWide
        ? <Widget>[
            stockItemField,
            branchSelector,
            if (selectedItem != null)
              RestockQuantityInputs(
                item: selectedItem,
                pcsCtrl: _pcsCtrl,
                extraCtrl: _extraCtrl,
              ),
            if (selectedItem != null) receivedDateField,
          ]
        : <Widget>[
            stockItemField,
            branchSelector,
            if (selectedItem != null)
              RestockQuantityInputs(
                item: selectedItem,
                pcsCtrl: _pcsCtrl,
                extraCtrl: _extraCtrl,
              ),
            if (selectedItem != null) receivedDateField,
          ];

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
        children: [
          _buildSectionCard(
            title: 'Restock Details',
            children: [
              ..._buildSectionFields(isWide: isWide, fields: detailFields),
              if (selectedItem != null) ...[
                AnimatedBuilder(
                  animation: Listenable.merge([_pcsCtrl, _extraCtrl]),
                  builder: (context, _) {
                    return Text(
                      'Recorded quantity in base units: ${_formatBaseQuantity(selectedItem)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
                RestockStockSummary(
                  item: selectedSummaryItem ?? selectedItem,
                  isLoading: _isSelectedItemSummaryLoading,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Batch Information',
            children: _buildSectionFields(
              isWide: isWide,
              fields: [
                InventoryFieldLabel(
                  text: 'Supplier name',
                  isOptional: true,
                  child: TextFormField(
                    controller: _supplierCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Enter supplier name',
                    ),
                  ),
                ),
                InventoryFieldLabel(
                  text: 'Purchase cost (USD)',
                  isOptional: true,
                  child: TextFormField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
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
                ),
                InventoryFieldLabel(
                  text: 'Expiry date',
                  isOptional: true,
                  child: TextFormField(
                    controller: _expiryCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Additional Notes',
            children: [
              InventoryFieldLabel(
                text: 'Notes',
                isOptional: true,
                child: TextFormField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Add notes for this restock',
                  ),
                  maxLines: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ActionRow(
            isWide: isWide,
            isSaving: inventoryState.isLoading || _isSaving,
            onCancel: _handleCancel,
            onSave: () => _submit(selectedItem),
            saveLabel: 'Restock',
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

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return InventorySectionCard(
      title: title,
      backgroundColor: Colors.white,
      elevation: _sectionCardElevation,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _withSectionSpacing(children),
        ),
      ],
    );
  }

  List<Widget> _withSectionSpacing(List<Widget> items) {
    final spaced = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      spaced.add(items[i]);
      if (i != items.length - 1) {
        spaced.add(const SizedBox(height: _sectionRowSpacing));
      }
    }
    return spaced;
  }

  List<Widget> _buildSectionFields({
    required bool isWide,
    required List<Widget> fields,
  }) {
    if (!isWide) return fields;

    final rows = <Widget>[];
    for (var i = 0; i < fields.length; i += 2) {
      rows.add(
        _buildSectionRow(
          first: fields[i],
          second: (i + 1) < fields.length ? fields[i + 1] : null,
        ),
      );
    }
    return rows;
  }

  Widget _buildSectionRow({required Widget first, Widget? second}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        if (second != null) ...[
          const SizedBox(width: 16),
          Expanded(child: second),
        ],
      ],
    );
  }

  Future<void> _handleEmptyInventory(BuildContext context) async {
    final router = GoRouter.of(context);

    final create = await showStockItemsRequiredDialog(context);

    if (!mounted) return;

    if (create == true) {
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
    final submittedAt = DateTime.now();
    final resolvedRestockDate = _dateCtrl.text.isEmpty
        ? formatYyyyMmDd(submittedAt)
        : _dateCtrl.text;
    try {
      await ref
          .read(stockInventoryControllerProvider.notifier)
          .createRestockBatch(
            itemId: item.id,
            baseQty: baseQty,
            restockDate: resolvedRestockDate,
            expiryDate: _expiryCtrl.text.isEmpty ? null : _expiryCtrl.text,
            supplierName: _supplierCtrl.text.trim().isEmpty
                ? null
                : _supplierCtrl.text.trim(),
            purchaseCostUsd: price,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            branchId: _selectedBranchId,
          );

      final actor = ref.read(loginControllerProvider).user?.name ?? 'System';
      final occurredAt = resolveRestockOccurredAt(
        resolvedRestockDate,
        referenceTime: submittedAt,
      );
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
              createdAt: submittedAt,
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

  StockItem? _resolvedSelectedItemSummary(
    StockItem? selectedItem,
    List<MapEntry<String, String>> branchEntries,
  ) {
    if (selectedItem == null) return null;
    final branchId = (_selectedBranchId ?? '').trim();
    if (_selectedItemSummary != null &&
        _selectedItemSummaryItemId == selectedItem.id &&
        _selectedItemSummaryBranchId == branchId) {
      return _selectedItemSummary;
    }
    return _buildFallbackSummaryItem(
      item: selectedItem,
      branchEntries: branchEntries,
      branchId: branchId,
    );
  }

  Future<void> _refreshSelectedItemSummary(
    StockItem? selectedItem,
    List<MapEntry<String, String>> branchEntries,
  ) async {
    final branchId = (_selectedBranchId ?? '').trim();
    final requestId = ++_selectedItemSummaryRequestId;
    if (selectedItem == null) {
      if (!mounted) return;
      setState(() {
        _selectedItemSummary = null;
        _selectedItemSummaryItemId = null;
        _selectedItemSummaryBranchId = null;
        _isSelectedItemSummaryLoading = false;
      });
      return;
    }

    final fallback = _buildFallbackSummaryItem(
      item: selectedItem,
      branchEntries: branchEntries,
      branchId: branchId,
    );
    if (!mounted) return;
    setState(() {
      _selectedItemSummary = fallback;
      _selectedItemSummaryItemId = selectedItem.id;
      _selectedItemSummaryBranchId = branchId;
      _isSelectedItemSummaryLoading = branchId.isNotEmpty;
    });

    if (branchId.isEmpty) {
      if (!mounted || requestId != _selectedItemSummaryRequestId) return;
      setState(() => _isSelectedItemSummaryLoading = false);
      return;
    }

    try {
      final records = await ref
          .read(branchStockRepositoryProvider)
          .fetchOnHand(branchId: branchId);
      if (!mounted || requestId != _selectedItemSummaryRequestId) return;

      StockItem nextSummary = fallback;
      for (final record in records) {
        if (record.stockItemId != selectedItem.id) continue;
        nextSummary = fallback.copyWith(
          onHand: record.onHand,
          minThreshold: record.minThreshold,
        );
        break;
      }

      setState(() {
        _selectedItemSummary = nextSummary;
        _selectedItemSummaryItemId = selectedItem.id;
        _selectedItemSummaryBranchId = branchId;
        _isSelectedItemSummaryLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _selectedItemSummaryRequestId) return;
      setState(() {
        _selectedItemSummary = fallback;
        _selectedItemSummaryItemId = selectedItem.id;
        _selectedItemSummaryBranchId = branchId;
        _isSelectedItemSummaryLoading = false;
      });
    }
  }

  StockItem _buildFallbackSummaryItem({
    required StockItem item,
    required List<MapEntry<String, String>> branchEntries,
    required String branchId,
  }) {
    var branchName = item.branchName;
    for (final entry in branchEntries) {
      if (entry.key == branchId) {
        branchName = entry.value;
        break;
      }
    }

    return item.copyWith(branchId: branchId, branchName: branchName, onHand: 0);
  }

  void _handleCancel() {
    context.pop();
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

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.isWide,
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
    required this.saveLabel,
  });

  final bool isWide;
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    final cancelStyle = AppTheme.cancelActionButtonStyle;
    final saveStyle = FilledButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
    );

    if (!isWide) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 140,
            child: FilledButton(
              style: cancelStyle,
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 160,
            child: FilledButton(
              style: saveStyle,
              onPressed: isSaving ? null : onSave,
              child: Text(saveLabel),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 140,
          child: FilledButton(
            style: cancelStyle,
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 160,
          child: FilledButton(
            style: saveStyle,
            onPressed: isSaving ? null : onSave,
            child: Text(saveLabel),
          ),
        ),
      ],
    );
  }
}
