import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/domain/utils/stock_quantity_formatter.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';

class RestockStockItemPage extends ConsumerStatefulWidget {
  const RestockStockItemPage({super.key});

  @override
  ConsumerState<RestockStockItemPage> createState() => _RestockStockItemPageState();
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
    final items = inventoryState.items;
    final branchEntries = _buildBranchEntries(items);
    final branchItems = _itemsForSelectedBranch(items);
    final hasItemSelection =
        branchItems.any((item) => item.id == _selectedItemId) && _selectedItemId != null;
    final selectedItem =
        hasItemSelection ? branchItems.firstWhere((item) => item.id == _selectedItemId) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restock inventory'),
        centerTitle: false,
      ),
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
                      _BranchSelector(
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
                        },
                      ),
                      const SizedBox(height: 12),
                      _StockItemAutocomplete(
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
                        onCleared: () {
                          setState(() {
                            _selectedItemId = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (selectedItem != null)
                        _QuantityInputs(
                          item: selectedItem,
                          pcsCtrl: _pcsCtrl,
                          extraCtrl: _extraCtrl,
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Cost price per delivery',
                          prefixText: '\$ ',
                          hintText: 'Enter amount',
                        ),
                        validator: (value) {
                          final price = double.tryParse(value?.trim() ?? '');
                          if (price == null || price < 0) {
                            return 'Enter a valid price';
                          }
                          return null;
                        },
                      ),
                      if (selectedItem != null) ...[
                        const SizedBox(height: 12),
                        _StockSummary(item: selectedItem),
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
                                  onPressed: () {
                                    setState(() => _dateCtrl.clear());
                                  },
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
                                  onPressed: () {
                                    setState(() => _expiryCtrl.clear());
                                  },
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
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                        ),
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

  List<MapEntry<String, String>> _buildBranchEntries(List<StockItem> items) {
    final map = <String, String>{};
    for (final item in items) {
      map[item.branchId] = item.branchName;
    }
    final entries = map.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries;
  }

  List<StockItem> _itemsForSelectedBranch(List<StockItem> items) {
    if (_selectedBranchId == null) return const [];
    return items
        .where((item) => item.branchId == _selectedBranchId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  void _pickDate() async {
    final now = DateTime.now();
    final initial = _parseDate(_dateCtrl.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _dateCtrl.text = _formatDate(picked);
      });
    }
  }

  void _pickExpiry() async {
    final now = DateTime.now();
    final initial = _parseDate(_expiryCtrl.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() {
        _expiryCtrl.text = _formatDate(picked);
      });
    }
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _formatDate(DateTime date) => date.toIso8601String().split('T').first;

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
    final extra = item.pieceSize > 1 ? int.tryParse(_extraCtrl.text.trim()) ?? 0 : 0;
    final baseQty =
        item.pieceSize > 1 ? pcs * item.pieceSize + extra : pcs;
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
            restockDate: _dateCtrl.text.isEmpty ? _formatDate(DateTime.now()) : _dateCtrl.text,
            expiryDate: _expiryCtrl.text.isEmpty ? null : _expiryCtrl.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recorded ${StockQuantityFormatter(baseQty: baseQty, pieceSize: item.pieceSize, baseUnit: item.baseUnit).format()} for ${item.name} at \$${price.toStringAsFixed(2)} (${_expiryCtrl.text.isEmpty ? 'no expiry' : 'expires ${_expiryCtrl.text}'})',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record restock: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _QuantityInputs extends StatelessWidget {
  const _QuantityInputs({
    required this.item,
    required this.pcsCtrl,
    required this.extraCtrl,
  });

  final StockItem item;
  final TextEditingController pcsCtrl;
  final TextEditingController extraCtrl;

  @override
  Widget build(BuildContext context) {
    if (item.pieceSize <= 1) {
      return TextFormField(
        controller: pcsCtrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Quantity (${item.baseUnit})',
        ),
        validator: (value) {
          final parsed = int.tryParse(value ?? '');
          if (parsed == null || parsed <= 0) {
            return 'Enter a quantity greater than 0';
          }
          return null;
        },
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: pcsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Pieces'),
            validator: (value) {
              final parsed = int.tryParse(value ?? '');
              if (parsed == null || parsed < 0) {
                return 'Enter pcs (0 or more)';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: extraCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Extra (${item.baseUnit})'),
            validator: (value) {
              final parsed = int.tryParse(value ?? '');
              if (parsed == null || parsed < 0) {
                return 'Enter a value ≥ 0';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}

class _BranchSelector extends StatelessWidget {
  const _BranchSelector({
    required this.entries,
    required this.selectedBranchId,
    required this.onChanged,
  });

  final List<MapEntry<String, String>> entries;
  final String? selectedBranchId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => selectedBranchId == null ? 'Please select a branch' : null,
      builder: (state) => DropdownMenu<String>(
        initialSelection: selectedBranchId,
        requestFocusOnTap: false,
        label: const Text('Branch'),
        dropdownMenuEntries: entries
            .map(
              (entry) => DropdownMenuEntry(
                value: entry.key,
                label: entry.value,
              ),
            )
            .toList(),
        onSelected: (value) {
          state.didChange(value);
          onChanged(value);
        },
      ),
    );
  }
}

class _StockItemAutocomplete extends StatefulWidget {
  const _StockItemAutocomplete({
    required this.items,
    this.controller,
    required this.selectedItemId,
    required this.onSelected,
    required this.onCleared,
  });

  final List<StockItem> items;
  final TextEditingController? controller;
  final String? selectedItemId;
  final ValueChanged<StockItem> onSelected;
  final VoidCallback onCleared;

  @override
  State<_StockItemAutocomplete> createState() => _StockItemAutocompleteState();
}

class _StockItemAutocompleteState extends State<_StockItemAutocomplete> {
  final FocusNode _focusNode = FocusNode();
  late final TextEditingController _fallbackController = TextEditingController();

  TextEditingController get _controller =>
      widget.controller ?? _fallbackController;

  @override
  void dispose() {
    _fallbackController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return FormField<String>(
      validator: (_) =>
          widget.selectedItemId == null ? 'Select an item to restock' : null,
      builder: (state) {
        return RawAutocomplete<StockItem>(
          textEditingController: _controller,
          focusNode: _focusNode,
          displayStringForOption: (option) => option.name,
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text.trim().toLowerCase();
            if (query.isEmpty) {
              return widget.items;
            }
            return widget.items.where((item) {
              final name = item.name.toLowerCase();
              final barcode = item.barcode?.toLowerCase() ?? '';
              return name.contains(query) || barcode.contains(query);
            });
          },
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: textController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Stock item',
                hintText: widget.items.isEmpty
                    ? 'Select a branch first'
                    : 'Search stock item',
                errorText: state.errorText,
                suffixIcon: textController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear',
                        onPressed: () {
                          _controller.clear();
                          widget.onCleared();
                          state.didChange(null);
                        },
                      ),
              ),
              onChanged: (_) {
                if (widget.selectedItemId != null) {
                  widget.onCleared();
                  state.didChange(null);
                }
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            final optionList = options.toList();
            if (optionList.isEmpty) {
              return const SizedBox.shrink();
            }
            final boxWidth = width.clamp(280.0, 420.0);
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: boxWidth,
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: optionList.length,
                    itemBuilder: (context, index) {
                      final option = optionList[index];
                      return ListTile(
                        title: Text(option.name),
                        subtitle: Text(
                          '${option.category} • ${option.branchName}',
                        ),
                        onTap: () {
                          onSelected(option);
                          state.didChange(option.id);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
          onSelected: (item) {
            widget.onSelected(item);
            state.didChange(item.id);
          },
        );
      },
    );
  }
}

class _StockSummary extends StatelessWidget {
  const _StockSummary({required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current on-hand',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            StockQuantityFormatter(
              baseQty: item.onHand,
              pieceSize: item.pieceSize,
              baseUnit: item.baseUnit,
            ).format(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Min threshold: ${StockQuantityFormatter(baseQty: item.minThreshold, pieceSize: item.pieceSize, baseUnit: item.baseUnit).format()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
