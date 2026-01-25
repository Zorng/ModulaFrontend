import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/widgets/display/dashed_border_painter.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/components/menu_form_field_label.dart';
import 'package:modular_pos/features/menu/ui/view/edit_modifier_group/edit_modifier_group_models.dart';
import 'package:modular_pos/features/menu/ui/view/edit_modifier_group/widgets/default_selector_button.dart';
import 'package:modular_pos/features/menu/ui/view/edit_modifier_group/widgets/edit_modifier_option_row_tile.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

class EditModifierGroupPage extends ConsumerStatefulWidget {
  const EditModifierGroupPage({super.key, required this.group});

  final ModifierGroup group;

  @override
  ConsumerState<EditModifierGroupPage> createState() =>
      _EditModifierGroupPageState();
}

class _EditModifierGroupPageState extends ConsumerState<EditModifierGroupPage> {
  late final TextEditingController _groupNameController;
  late final List<EditModifierOptionRowModel> _options;
  final _pricingBehaviors = ['Price Change', 'No Price Change'];
  final _selectionTypes = ['Single Selection', 'Multiple Selection'];

  late String? _selectedPricingBehavior;
  late String? _selectedSelectionType;
  late String _selectedDefault;

  static const _noneDefaultValue = 'none';

  bool get _isSingleSelection =>
      _selectedSelectionType != null &&
      _selectedSelectionType != 'Multiple Selection';

  bool get _requiresPriceInput => _selectedPricingBehavior != 'No Price Change';

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController(text: widget.group.name);
    _options = widget.group.options
        .map(
          (option) => EditModifierOptionRowModel(
            id: option.id,
            name: option.name,
            price: option.price,
          ),
        )
        .toList();

    _selectedPricingBehavior = _mapPricingBehavior(widget.group.pricingBehavior);
    _selectedSelectionType = widget.group.selectionType == 'multiple'
        ? _selectionTypes.last
        : _selectionTypes.first;
    _selectedDefault = widget.group.defaultOptionId ?? _noneDefaultValue;
    if (!_isSingleSelection) _selectedDefault = _noneDefaultValue;
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
      case 'addon':
        return 'Price Change';
      case 'none':
        return 'No Price Change';
      default:
        return 'Price Change';
    }
  }

  String _mapPricingBehaviorToValue(String? behavior) {
    switch (behavior) {
      case 'Price Change':
        return 'addon';
      case 'No Price Change':
      default:
        return 'none';
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
    if (mounted) context.pop();
  }

  Future<void> _tryDeleteGroup() async {
    final itemsUsingGroup = ref
        .read(menuViewModelProvider)
        .allItems
        .where((item) => item.modifierGroupIds.contains(widget.group.id))
        .toList();
    if (itemsUsingGroup.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please remove this modifier from menu items before deleting.',
            ),
          ),
        );
      }
      return;
    }
    try {
      await ref.read(menuViewModelProvider.notifier).deleteModifierGroup(widget.group.id);
      if (mounted) {
        Navigator.of(context)
          ..pop()
          ..pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please remove this modifier from menu items before deleting.',
          ),
        ),
      );
    }
  }

  void _addOption() => setState(() => _options.add(EditModifierOptionRowModel()));

  void _removeOption(EditModifierOptionRowModel option) {
    setState(() {
      _options.remove(option);
      option.dispose();
      if (_selectedDefault == option.id) _selectedDefault = _noneDefaultValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: false, title: const Text('Edit Modifier Group')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MenuFormFieldLabel(text: 'Group Name', isRequired: true),
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(hintText: 'e.g., Size, Toppings'),
            ),
            const SizedBox(height: 24),
            const MenuFormFieldLabel(text: 'Pricing Behavior'),
            DropdownMenu<String>(
              initialSelection: _selectedPricingBehavior,
              onSelected: (value) =>
                  setState(() => _selectedPricingBehavior = value),
              dropdownMenuEntries: _pricingBehaviors
                  .map((behavior) => DropdownMenuEntry(value: behavior, label: behavior))
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
                  DefaultSelectorButton(
                    isSelected: _selectedDefault == _noneDefaultValue,
                    onPressed: () =>
                        setState(() => _selectedDefault = _noneDefaultValue),
                  ),
                ],
              ),
            ..._options.map(
              (option) => EditModifierOptionRowTile(
                option: option,
                requiresPriceInput: _requiresPriceInput,
                isSingleSelection: _isSingleSelection,
                isDefaultSelected: _selectedDefault == option.id,
                onDefaultSelected: () => setState(() => _selectedDefault = option.id),
                onRemove: () => _removeOption(option),
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
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                ),
                onPressed: _tryDeleteGroup,
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
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
}
