import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_section_card.dart';

class StockItemDetailPage extends ConsumerStatefulWidget {
  const StockItemDetailPage({super.key, required this.item});

  final StockItem item;

  @override
  ConsumerState<StockItemDetailPage> createState() =>
      _StockItemDetailPageState();
}

class _StockItemDetailPageState extends ConsumerState<StockItemDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _typeOptions = const ['Ingredient', 'Sellable'];
  final _categoryOptions = const [
    'Dairy',
    'Packaging',
    'Produce',
    'Sweetener',
    'Uncategorized',
  ];

  bool _isEditing = false;
  late StockItem _editableData;
  late TextEditingController _nameCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _pieceSizeCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _lastRestockCtrl;
  late TextEditingController _expiryCtrl;
  late Set<String> _selectedTypes;
  late String _baseUnit;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _editableData = widget.item;
    _nameCtrl = TextEditingController(text: _editableData.name);
    _categoryCtrl = TextEditingController(text: _editableData.category);
    _pieceSizeCtrl = TextEditingController(
      text: _editableData.pieceSize.toString(),
    );
    _barcodeCtrl = TextEditingController(text: _editableData.barcode ?? '');
    _lastRestockCtrl = TextEditingController(
      text: _editableData.lastRestockDate,
    );
    _expiryCtrl = TextEditingController(text: _editableData.expiryDate);
    _selectedTypes = {..._editableData.usageTags};
    _baseUnit = _editableData.baseUnit;
    _isActive = _editableData.isActive;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _pieceSizeCtrl.dispose();
    _barcodeCtrl.dispose();
    _lastRestockCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _nameCtrl.text = _editableData.name;
      _categoryCtrl.text = _editableData.category;
      _baseUnit = _editableData.baseUnit;
      _pieceSizeCtrl.text = _editableData.pieceSize.toString();
      _barcodeCtrl.text = _editableData.barcode ?? '';
      _lastRestockCtrl.text = _editableData.lastRestockDate;
      _expiryCtrl.text = _editableData.expiryDate;
      _selectedTypes = {..._editableData.usageTags};
      _isActive = _editableData.isActive;
    });
  }

  void _saveChanges() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final pieceSize = int.tryParse(_pieceSizeCtrl.text.trim());
    if (pieceSize == null || pieceSize <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Piece size must be greater than 0')),
      );
      return;
    }
    final updated = _editableData.copyWith(
      name: _nameCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      baseUnit: _baseUnit,
      pieceSize: pieceSize,
      barcode: _barcodeCtrl.text.trim().isEmpty
          ? null
          : _barcodeCtrl.text.trim(),
      lastRestockDate: _lastRestockCtrl.text.trim(),
      expiryDate: _expiryCtrl.text.trim(),
      usageTags: _selectedTypes.toList(),
      isActive: _isActive,
    );
    ref
        .read(stockInventoryControllerProvider.notifier)
        .updateStockItem(updated);
    setState(() {
      _editableData = updated;
      _isEditing = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Stock item saved (mock)')));
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editableData.name),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _isEditing ? _cancelEditing : _startEditing,
            child: Text(_isEditing ? 'Cancel' : 'Edit'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: _ImagePreview(
                imageUrl: _editableData.imageUrl,
                initials: _initialsFor(_editableData.name),
              ),
            ),
            const SizedBox(height: 24),
            InventorySectionCard(
              title: 'Item information',
              children: [
                _isEditing
                    ? TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name'),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Name is required'
                            : null,
                      )
                    : InventoryDetailField(
                        label: 'Name',
                        value: _editableData.name,
                      ),
                _isEditing
                    ? SizedBox(
                        width: double.infinity,
                        child: InventoryDropdown<String>(
                          initialValue: _categoryCtrl.text,
                          label: const Text('Category'),
                          entries: _categoryOptions
                              .map(
                                (category) => DropdownMenuEntry(
                                  value: category,
                                  label: category,
                                ),
                              )
                              .toList(),
                          onSelected: (value) {
                            if (value == null) return;
                            setState(() => _categoryCtrl.text = value);
                          },
                        ),
                      )
                    : InventoryDetailField(
                        label: 'Category',
                        value: _categoryCtrl.text,
                      ),
                _isEditing
                    ? TextFormField(
                        controller: _pieceSizeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Piece size',
                          helperText: 'Number of base units per piece',
                        ),
                        onChanged: (_) => setState(() {}),
                      )
                    : InventoryDetailField(
                        label: 'Piece size',
                        value: _pieceDescription(),
                      ),
                _isEditing
                    ? TextFormField(
                        controller: _barcodeCtrl,
                        decoration: const InputDecoration(labelText: 'Barcode'),
                      )
                    : InventoryDetailField(
                        label: 'Barcode',
                        value: _editableData.barcode ?? '—',
                      ),
                _isEditing
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _typeOptions
                            .map(
                              (type) => CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(type),
                                value: _selectedTypes.contains(type),
                                onChanged: (value) {
                                  if (!_isEditing) return;
                                  setState(() {
                                    if (value ?? false) {
                                      _selectedTypes.add(type);
                                    } else {
                                      _selectedTypes.remove(type);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _editableData.usageTags
                            .map(
                              (tag) => Chip(
                                label: Text(tag),
                                backgroundColor: chipColor,
                              ),
                            )
                            .toList(),
                      ),
                _isEditing
                    ? SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Item is active'),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                      )
                    : InventoryDetailField(
                        label: 'Status',
                        value: _isActive ? 'Active' : 'Inactive',
                      ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: FilledButton(
                  onPressed: _saveChanges,
                  child: const Text('Save changes'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _pieceDescription() {
    final parsed = int.tryParse(_pieceSizeCtrl.text) ?? _editableData.pieceSize;
    if (parsed <= 1) {
      return 'Tracked in $_baseUnit';
    }
    return '$parsed $_baseUnit per piece';
  }

  String _initialsFor(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({this.imageUrl, required this.initials});

  final String? imageUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 220,
        height: 220,
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _Placeholder(initials: initials, scheme: scheme),
              )
            : _Placeholder(initials: initials, scheme: scheme),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.initials, required this.scheme});

  final String initials;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.secondaryContainer,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
