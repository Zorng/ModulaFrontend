import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/view/dashed_border_painter.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

/// A form for editing an existing modifier group.
class EditModifierGroupPage extends ConsumerStatefulWidget {
  const EditModifierGroupPage({super.key, required this.group});

  final ModifierGroup group;

  @override
  ConsumerState<EditModifierGroupPage> createState() =>
      _EditModifierGroupPageState();
}

class _EditModifierGroupPageState
    extends ConsumerState<EditModifierGroupPage> {
  late final TextEditingController _groupNameController;
  late final List<_OptionRow> _options;
  final _pricingBehaviors = ['Add-on (Extra)', 'Fixed (Size Based)', 'No Price Change'];
  final _selectionTypes = ['Single Selection', 'Multiple Selection'];

  late String? _selectedPricingBehavior;
  late String? _selectedSelectionType;
  late String _selectedDefault;

  static const _noneDefaultValue = 'none';
  bool get _isSingleSelection =>
      _selectedSelectionType != null &&
      _selectedSelectionType != 'Multiple Selection';
  bool get _requiresPriceInput =>
      _selectedPricingBehavior != 'No Price Change';

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController(text: widget.group.name);
    _options = widget.group.options
        .map(
          (option) => _OptionRow(
            id: option.id,
            name: option.name,
            price: option.price,
          ),
        )
        .toList();

    _selectedPricingBehavior = _mapPricingBehavior(widget.group.pricingBehavior);
    _selectedSelectionType =
        widget.group.selectionType == 'multiple' ? _selectionTypes.last : _selectionTypes.first;
    _selectedDefault = widget.group.defaultOptionId ?? _noneDefaultValue;
    if (!_isSingleSelection) {
      _selectedDefault = _noneDefaultValue;
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  String _mapPricingBehavior(String behavior) {
    switch (behavior) {
      case 'fixed':
        return 'Fixed (Size Based)';
      case 'none':
        return 'No Price Change';
      case 'addon':
      default:
        return 'Add-on (Extra)';
    }
  }

  String _mapPricingBehaviorToValue(String? behavior) {
    switch (behavior) {
      case 'Fixed (Size Based)':
        return 'fixed';
      case 'No Price Change':
        return 'none';
      case 'Add-on (Extra)':
      default:
        return 'addon';
    }
  }

  Future<void> _saveGroup() async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) return;

    final updated = widget.group.copyWith(
      name: name,
      pricingBehavior: _mapPricingBehaviorToValue(_selectedPricingBehavior),
      selectionType:
          _selectedSelectionType == 'Multiple Selection' ? 'multiple' : 'single',
      defaultOptionId: _isSingleSelection && _selectedDefault != _noneDefaultValue
          ? _selectedDefault
          : null,
      options: _options
          .map(
            (row) => ModifierOption(
              id: row.id,
              name: row.nameController.text.trim(),
              price: _requiresPriceInput
                  ? double.tryParse(row.priceController.text) ?? 0
                  : 0,
              isDefault: _isSingleSelection && _selectedDefault == row.id,
            ),
          )
          .toList(),
    );

    await ref.read(menuViewModelProvider.notifier).updateModifierGroup(updated);
    if (mounted) Navigator.pop(context);
  }

  void _addOption() {
    setState(() => _options.add(_OptionRow()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Modifier Group'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Group Name', isRequired: true),
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(hintText: 'e.g., Size, Toppings'),
            ),
            const SizedBox(height: 24),
            _buildLabel('Pricing Behavior'),
            DropdownMenu<String>(
              initialSelection: _selectedPricingBehavior,
              onSelected: (value) =>
                  setState(() => _selectedPricingBehavior = value),
              dropdownMenuEntries: _pricingBehaviors
                  .map(
                    (behavior) =>
                        DropdownMenuEntry(value: behavior, label: behavior),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            _buildLabel('Selection Type'),
            DropdownMenu<String>(
              initialSelection: _selectedSelectionType,
              onSelected: (value) {
                setState(() {
                  _selectedSelectionType = value;
                  if (!_isSingleSelection) {
                    _selectedDefault = _noneDefaultValue;
                  }
                });
              },
              dropdownMenuEntries: _selectionTypes
                  .map(
                    (type) => DropdownMenuEntry(value: type, label: type),
                  )
                  .toList(),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Options', style: Theme.of(context).textTheme.titleSmall),
                if (_isSingleSelection)
                  Text('Select as default',
                      style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const Divider(height: 16),
            if (_isSingleSelection)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('None'),
                  _DefaultSelector(
                    isSelected: _selectedDefault == _noneDefaultValue,
                    onPressed: () =>
                        setState(() => _selectedDefault = _noneDefaultValue),
                  ),
                ],
              ),
            ..._options.map(_buildOptionRow),
            const SizedBox(height: 16),
            InkWell(
              onTap: _addOption,
              child: CustomPaint(
                foregroundPainter: DashedBorderPainter(
                  color: Theme.of(context).primaryColor,
                ),
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      '+ Add another option',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _saveGroup,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Save Changes'),
        ),
      ),
    );
  }

  Widget _buildOptionRow(_OptionRow option) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: TextField(
              controller: option.nameController,
              decoration: const InputDecoration(hintText: 'Option Label'),
            ),
          ),
          if (_requiresPriceInput) ...[
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: TextField(
                controller: option.priceController,
                decoration: const InputDecoration(hintText: '+ \$0.00'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
          if (_isSingleSelection) ...[
            const SizedBox(width: 8),
            _DefaultSelector(
              isSelected: _selectedDefault == option.id,
              onPressed: () => setState(() => _selectedDefault = option.id),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text,
          style: Theme.of(context).textTheme.titleSmall,
          children: [
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow {
  _OptionRow({
    String? id,
    String? name,
    double? price,
  })  : id = id ?? UniqueKey().toString(),
        nameController = TextEditingController(text: name),
        priceController =
            TextEditingController(text: price?.toStringAsFixed(2) ?? '');

  final String id;
  final TextEditingController nameController;
  final TextEditingController priceController;

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}

class _DefaultSelector extends StatelessWidget {
  const _DefaultSelector({required this.isSelected, required this.onPressed});

  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      ),
      color: isSelected ? Theme.of(context).primaryColor : null,
      tooltip: 'Set as default',
    );
  }
}
