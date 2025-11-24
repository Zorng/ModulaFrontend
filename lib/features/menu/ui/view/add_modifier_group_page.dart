import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/view/dashed_border_painter.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

/// A form for creating a new modifier group.
class AddModifierGroupPage extends ConsumerStatefulWidget {
  const AddModifierGroupPage({super.key});

  @override
  ConsumerState<AddModifierGroupPage> createState() =>
      _AddModifierGroupPageState();
}

class ModifierOptionRow {
  ModifierOptionRow()
      : id = UniqueKey().toString(),
        nameController = TextEditingController(),
        priceController = TextEditingController();

  final String id;
  final TextEditingController nameController;
  final TextEditingController priceController;

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}

class _AddModifierGroupPageState
    extends ConsumerState<AddModifierGroupPage> {
  final _groupNameController = TextEditingController();
  final _pricingBehaviors = [
    'Add-on (Extra)',
    'Fixed (Size Based)',
    'No Price Change'
  ];
  final _selectionTypes = ['Single Selection', 'Multiple Selection'];
  final List<ModifierOptionRow> _options = [];

  String? _selectedPricingBehavior;
  String? _selectedSelectionType;
  String _selectedDefault = _noneDefaultValue;
  bool _isFormValid = false;

  static const String _noneDefaultValue = 'none';
  bool get _isSingleSelection =>
      _selectedSelectionType != null &&
      _selectedSelectionType != 'Multiple Selection';
  bool get _requiresPriceInput =>
      _selectedPricingBehavior != 'No Price Change';
  @override
  void initState() {
    super.initState();
    _selectedPricingBehavior = _pricingBehaviors.first;
    _selectedSelectionType = _selectionTypes.first;
    _groupNameController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _groupNameController.removeListener(_validateForm);
    _groupNameController.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  void _validateForm() {
    final isValid = _groupNameController.text.trim().isNotEmpty;
    if (_isFormValid != isValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  Future<void> _saveGroup() async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) return;

    final group = ModifierGroup(
      id: '',
      name: name,
      selectionType: _selectedSelectionType == 'Multiple Selection'
          ? 'multiple'
          : 'single',
      pricingBehavior: _selectedPricingBehavior == 'Fixed (Size Based)'
          ? 'fixed'
          : _selectedPricingBehavior == 'No Price Change'
              ? 'none'
              : 'addon',
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
            ),
          )
          .toList(),
    );

    await ref.read(menuViewModelProvider.notifier).addModifierGroup(group);
    if (mounted) Navigator.pop(context);
  }

  void _addOption() {
    setState(() => _options.add(ModifierOptionRow()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Modifier Group'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Group Name', isRequired: true),
            TextField(
              controller: _groupNameController,
              decoration:
                  const InputDecoration(hintText: 'e.g., Size, Toppings'),
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
                  _buildDefaultSelector(
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
          onPressed: _isFormValid ? _saveGroup : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Create'),
        ),
      ),
    );
  }

  Widget _buildOptionRow(ModifierOptionRow option) {
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
            _buildDefaultSelector(
              isSelected: _selectedDefault == option.id,
              onPressed: () => setState(() => _selectedDefault = option.id),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultSelector({
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      ),
      color: isSelected ? Theme.of(context).primaryColor : null,
      tooltip: 'Set as default',
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
