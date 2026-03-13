import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/widgets/display/dashed_border_painter.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/components/menu_form_field_label.dart';
import 'package:modular_pos/features/menu/ui/view/add_modifier_group/add_modifier_group_models.dart';
import 'package:modular_pos/features/menu/ui/view/add_modifier_group/widgets/modifier_option_row_tile.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

class AddModifierGroupPage extends ConsumerStatefulWidget {
  const AddModifierGroupPage({super.key});

  @override
  ConsumerState<AddModifierGroupPage> createState() =>
      _AddModifierGroupPageState();
}

class _AddModifierGroupPageState extends ConsumerState<AddModifierGroupPage> {
  final _groupNameController = TextEditingController();
  final _pricingBehaviors = ['Price Change', 'No Price Change'];
  final _selectionTypes = ['Single Selection', 'Multiple Selection'];
  final List<ModifierOptionRowModel> _options = [];

  String? _selectedPricingBehavior;
  String? _selectedSelectionType;
  String _selectedDefault = _noneDefaultValue;
  bool _isFormValid = false;

  static const String _noneDefaultValue = 'none';

  bool get _isSingleSelection =>
      _selectedSelectionType != null &&
      _selectedSelectionType != 'Multiple Selection';

  bool get _requiresPriceInput => _selectedPricingBehavior != 'No Price Change';

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
    final hasGroupName = _groupNameController.text.trim().isNotEmpty;
    final allOptionLabelsFilled = _options.every(
      (opt) => opt.nameController.text.trim().isNotEmpty,
    );
    final isValid = hasGroupName && allOptionLabelsFilled;
    if (_isFormValid != isValid) setState(() => _isFormValid = isValid);
  }

  Future<void> _saveGroup() async {
    final name = _groupNameController.text.trim();
    final allOptionLabelsFilled = _options.every(
      (opt) => opt.nameController.text.trim().isNotEmpty,
    );
    if (name.isEmpty || !allOptionLabelsFilled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please input required fields.')),
        );
      }
      _validateForm();
      return;
    }

    final group = ModifierGroup(
      id: '',
      name: name,
      selectionType: _selectedSelectionType == 'Multiple Selection'
          ? 'MULTI'
          : 'SINGLE',
      pricingBehavior: _selectedPricingBehavior == 'Price Change'
          ? 'addon'
          : 'none',
      defaultOptionId:
          _isSingleSelection && _selectedDefault != _noneDefaultValue
          ? _selectedDefault
          : null,
      options: _options.map((row) {
        final double priceDelta = _requiresPriceInput
            ? double.tryParse(row.priceController.text) ?? 0.0
            : 0.0;
        return ModifierOption(
          id: row.id,
          name: row.nameController.text.trim(),
          price: priceDelta,
          priceDelta: priceDelta,
          isDefault: _isSingleSelection && _selectedDefault == row.id,
        );
      }).toList(),
    );

    await ref.read(menuViewModelProvider.notifier).addModifierGroup(group);
    if (mounted) context.pop();
  }

  void _addOption() => setState(() => _options.add(ModifierOptionRowModel()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Add Modifier Group'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MenuFormFieldLabel(text: 'Group Name', isRequired: true),
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                hintText: 'e.g., Size, Toppings',
              ),
            ),
            const SizedBox(height: 24),
            const MenuFormFieldLabel(text: 'Pricing Behavior'),
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
            const MenuFormFieldLabel(text: 'Selection Type'),
            DropdownMenu<String>(
              initialSelection: _selectedSelectionType,
              onSelected: (value) {
                setState(() {
                  _selectedSelectionType = value;
                  if (!_isSingleSelection) _selectedDefault = _noneDefaultValue;
                });
              },
              dropdownMenuEntries: _selectionTypes
                  .map((type) => DropdownMenuEntry(value: type, label: type))
                  .toList(),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Options', style: Theme.of(context).textTheme.titleSmall),
                if (_isSingleSelection)
                  Text(
                    'Select as default',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
              ],
            ),
            const Divider(height: 16),
            if (_isSingleSelection)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('None'),
                  IconButton(
                    onPressed: () =>
                        setState(() => _selectedDefault = _noneDefaultValue),
                    icon: Icon(
                      _selectedDefault == _noneDefaultValue
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    color: _selectedDefault == _noneDefaultValue
                        ? Theme.of(context).primaryColor
                        : null,
                    tooltip: 'Set as default',
                  ),
                ],
              ),
            ..._options.map(
              (option) => ModifierOptionRowTile(
                option: option,
                requiresPriceInput: _requiresPriceInput,
                isSingleSelection: _isSingleSelection,
                isDefaultSelected: _selectedDefault == option.id,
                onDefaultSelected: () =>
                    setState(() => _selectedDefault = option.id),
                onChanged: _validateForm,
                onRemove: () {
                  setState(() {
                    option.dispose();
                    _options.removeWhere((o) => o.id == option.id);
                    if (_selectedDefault == option.id) {
                      _selectedDefault = _noneDefaultValue;
                    }
                  });
                },
              ),
            ),
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
}
