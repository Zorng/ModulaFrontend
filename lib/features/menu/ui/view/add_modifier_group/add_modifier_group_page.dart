import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/theme/app_theme.dart';
import 'package:modular_pos/core/widgets/display/dashed_border_painter.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_section_card.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/components/menu_form_field_label.dart';
import 'package:modular_pos/features/menu/ui/view/add_modifier_group/add_modifier_group_models.dart';
import 'package:modular_pos/features/menu/ui/view/add_modifier_group/widgets/modifier_option_row_tile.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

enum ModifierGroupFormMode { create, view, edit }

class AddModifierGroupPage extends ConsumerStatefulWidget {
  const AddModifierGroupPage({
    super.key,
    this.initialGroup,
    this.initialMode = ModifierGroupFormMode.create,
  });

  final ModifierGroup? initialGroup;
  final ModifierGroupFormMode initialMode;

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
  String? _selectedDefault;
  ModifierGroupFormMode _mode = ModifierGroupFormMode.create;

  bool get _isSingleSelection =>
      _selectedSelectionType != null &&
      _selectedSelectionType != 'Multiple Selection';

  bool get _requiresPriceInput => _selectedPricingBehavior != 'No Price Change';
  bool get _isView => _mode == ModifierGroupFormMode.view;
  bool get _isEditing => _mode != ModifierGroupFormMode.view;
  bool get _isCreate => _mode == ModifierGroupFormMode.create;

  String get _title => switch (_mode) {
    ModifierGroupFormMode.create => 'Add Modifier Group',
    ModifierGroupFormMode.view => 'Modifier group details',
    ModifierGroupFormMode.edit => 'Edit Modifier Group',
  };

  String? get _defaultOptionLabel {
    if (!_isSingleSelection || _selectedDefault == null) return null;
    for (final option in _options) {
      if (option.id == _selectedDefault) {
        final label = option.nameController.text.trim();
        if (label.isNotEmpty) return label;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _seedFromGroup(widget.initialGroup);
  }

  void _seedFromGroup(ModifierGroup? group) {
    _groupNameController.text = group?.name ?? '';
    _selectedPricingBehavior = _mapPricingBehavior(group?.pricingBehavior);
    _selectedSelectionType = group?.selectionType == 'multiple'
        ? _selectionTypes.last
        : _selectionTypes.first;
    String? resolvedDefault = group?.defaultOptionId;
    if (resolvedDefault == null && group != null) {
      for (final option in group.options) {
        if (option.isDefault) {
          resolvedDefault = option.id;
          break;
        }
      }
    }
    _selectedDefault = resolvedDefault;
    for (final option in _options) {
      option.dispose();
    }
    _options
      ..clear()
      ..addAll(
        (group?.options ?? const <ModifierOption>[]).map(
          (option) => ModifierOptionRowModel(
            id: option.id,
            name: option.name,
            price: option.price.toStringAsFixed(2),
          ),
        ),
      );
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  String _mapPricingBehavior(String? behavior) {
    switch (behavior) {
      case 'fixed':
      case 'addon':
        return 'Price Change';
      case 'none':
        return 'No Price Change';
      default:
        return _pricingBehaviors.first;
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
    final hasOptions = _options.isNotEmpty;
    final allOptionLabelsFilled = _options.every(
      (opt) => opt.nameController.text.trim().isNotEmpty,
    );
    if (name.isEmpty || !hasOptions || !allOptionLabelsFilled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please input required fields and add at least one option.'),
        ),
      );
      return;
    }
    if (_isSingleSelection && _selectedDefault == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set a default option before saving.')),
      );
      return;
    }

    final group = ModifierGroup(
      id: widget.initialGroup?.id ?? '',
      name: name,
      selectionType:
          _selectedSelectionType == 'Multiple Selection' ? 'multiple' : 'single',
      pricingBehavior: _mapPricingBehaviorToValue(_selectedPricingBehavior),
      defaultOptionId: _isSingleSelection ? _selectedDefault : null,
      options: _options.map((row) {
        final priceDelta = _requiresPriceInput
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

    if (_isCreate) {
      await ref.read(menuViewModelProvider.notifier).addModifierGroup(group);
    } else {
      await ref.read(menuViewModelProvider.notifier).updateModifierGroup(group);
    }
    if (!mounted) return;
    context.pop();
  }

  Future<void> _archiveGroup() async {
    final initialGroup = widget.initialGroup;
    if (initialGroup == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final background = Theme.of(context).scaffoldBackgroundColor;
        return AlertDialog(
          backgroundColor: background,
          surfaceTintColor: background,
          title: const Text('Archive modifier group?'),
          content: Text(
            '"${initialGroup.name}" will be archived and removed from active modifier groups.',
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: AppTheme.cancelActionButtonStyle,
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Archive'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(menuViewModelProvider.notifier)
          .archiveModifierGroup(initialGroup.id);
      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to archive modifier group.'),
        ),
      );
    }
  }

  void _addOption() => setState(() => _options.add(ModifierOptionRowModel()));

  void _removeOption(ModifierOptionRowModel option) {
    setState(() {
      _options.removeWhere((row) => row.id == option.id);
      option.dispose();
      if (_selectedDefault == option.id) {
        _selectedDefault = null;
      }
    });
  }

  void _cancel() {
    if (_isCreate) {
      context.pop();
      return;
    }
    if (_mode == ModifierGroupFormMode.edit) {
      setState(() {
        _mode = ModifierGroupFormMode.view;
        _seedFromGroup(widget.initialGroup);
      });
      return;
    }
    context.pop();
  }

  Widget _buildDropdownField({
    required String label,
    required String? initialSelection,
    required List<String> options,
    required ValueChanged<String?> onSelected,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MenuFormFieldLabel(text: label),
            DropdownMenu<String>(
              width: constraints.maxWidth,
              initialSelection: initialSelection,
              onSelected: onSelected,
              dropdownMenuEntries: options
                  .map(
                    (option) =>
                        DropdownMenuEntry(value: option, label: option),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(menuViewModelProvider);
    final defaultOptionLabel = _defaultOptionLabel;
    final currentGroup = _currentGroup();
    final isArchived =
        currentGroup != null &&
        currentGroup.status.trim().toUpperCase() == 'ARCHIVED';
    final pageBackground = Theme.of(context).scaffoldBackgroundColor;
    final isSmall = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: pageBackground,
        centerTitle: false,
        title: Text(_title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InventorySectionCard(
              title: 'Modifier details',
              backgroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              children: [
                Text(
                  'Modifier groups define reusable option structure, selection rules, and shared price deltas. Item-specific component effects are configured on each menu item.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 12),
                AbsorbPointer(
                  absorbing: !_isEditing,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MenuFormFieldLabel(
                        text: 'Group Name',
                        isRequired: true,
                      ),
                      TextField(
                        controller: _groupNameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Size, Toppings',
                        ),
                        maxLength: 20,
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 700;
                          final fieldWidth = compact
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 16) / 2;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: fieldWidth,
                                child: _buildDropdownField(
                                  label: 'Pricing Behavior',
                                  initialSelection: _selectedPricingBehavior,
                                  options: _pricingBehaviors,
                                  onSelected: (value) => setState(
                                    () => _selectedPricingBehavior = value,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: _buildDropdownField(
                                  label: 'Selection Type',
                                  initialSelection: _selectedSelectionType,
                                  options: _selectionTypes,
                                  onSelected: (value) {
                                    setState(() {
                                      _selectedSelectionType = value;
                                      if (!_isSingleSelection) {
                                        _selectedDefault = null;
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InventorySectionCard(
              title: 'Modifier Options',
              backgroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              children: [
                Text(
                  _isSingleSelection
                      ? 'Choose reusable options and set a default if needed.'
                      : 'Choose reusable options for this modifier group.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
                if (_isView && _isSingleSelection && defaultOptionLabel != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: 'Default option: ',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: defaultOptionLabel),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_isView && _isSingleSelection && defaultOptionLabel == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Default option is not available.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                AbsorbPointer(
                  absorbing: !_isEditing,
                  child: Column(
                    children: _options
                        .map(
                          (option) => ModifierOptionRowTile(
                            option: option,
                            requiresPriceInput: _requiresPriceInput,
                            isSingleSelection: _isSingleSelection,
                            isDefaultSelected: _selectedDefault == option.id,
                            onDefaultSelected: () =>
                                setState(() => _selectedDefault = option.id),
                            onChanged: () => setState(() {}),
                            onRemove: () => _removeOption(option),
                            readOnly: _isView,
                            showRemoveAction: _isEditing,
                            showDefaultSelector: _isSingleSelection,
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (_isEditing)
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
            const SizedBox(height: 16),
            if (isSmall)
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: AppTheme.cancelActionButtonStyle,
                      onPressed: _isView
                          ? (isArchived ? _restoreGroup : _archiveGroup)
                          : _cancel,
                      child: Text(
                        _isView ? (isArchived ? 'Restore' : 'Archive') : 'Cancel',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isView
                          ? () => setState(() => _mode = ModifierGroupFormMode.edit)
                          : _saveGroup,
                      child: Text(_isView ? 'Edit' : 'Save'),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 140,
                    child: FilledButton(
                      style: AppTheme.cancelActionButtonStyle,
                      onPressed: _isView
                          ? (isArchived ? _restoreGroup : _archiveGroup)
                          : _cancel,
                      child: Text(
                        _isView ? (isArchived ? 'Restore' : 'Archive') : 'Cancel',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 160,
                    child: FilledButton(
                      onPressed: _isView
                          ? () => setState(() => _mode = ModifierGroupFormMode.edit)
                          : _saveGroup,
                      child: Text(_isView ? 'Edit' : 'Save'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreGroup() async {
    final group = _currentGroup();
    if (group == null) return;
    try {
      await ref.read(menuViewModelProvider.notifier).restoreModifierGroup(
        group.id,
      );
      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to restore modifier group.'),
        ),
      );
    }
  }

  ModifierGroup? _currentGroup() {
    final original = widget.initialGroup;
    if (original == null) return null;
    final groups = ref.read(menuViewModelProvider).modifierGroups;
    for (final group in groups) {
      if (group.id == original.id) {
        return group;
      }
    }
    return original;
  }
}
