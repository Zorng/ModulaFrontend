import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/menu/domain/models/menu_branch.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/view/dashed_border_painter.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

/// A form for creating or editing a menu item.
class MenuItemFormPage extends ConsumerStatefulWidget {
  const MenuItemFormPage({
    super.key,
    this.initialItem,
  });

  final MenuItem? initialItem;

  @override
  ConsumerState<MenuItemFormPage> createState() => _MenuItemFormPageState();
}

class _MenuItemFormPageState extends ConsumerState<MenuItemFormPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  bool _isFormValid = false;
  String? _selectedCategoryId;
  final Set<String> _selectedModifierGroupIds = {};
  final Set<String> _selectedBranchIds = {};
  bool _hasInitializedBranchSelection = false;

  bool get isEditing => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialItem?.name);
    _priceController = TextEditingController(
      text: widget.initialItem?.price.toStringAsFixed(2),
    );
    _selectedCategoryId = widget.initialItem?.categoryId;
    _selectedModifierGroupIds
        .addAll(widget.initialItem?.modifierGroupIds ?? const []);
    _selectedBranchIds.addAll(widget.initialItem?.branchIds ?? const []);
    _hasInitializedBranchSelection = _selectedBranchIds.isNotEmpty;
    _nameController.addListener(_validateForm);
    _priceController.addListener(_validateForm);
    _validateForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isValid = _nameController.text.trim().isNotEmpty &&
        (_priceController.text.trim().isNotEmpty) &&
        _selectedCategoryId != null;
    if (_isFormValid != isValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  Future<void> _save() async {
    final notifier = ref.read(menuViewModelProvider.notifier);
    final allBranches = ref.read(menuViewModelProvider).branches;
    final item = MenuItem(
      id: widget.initialItem?.id ?? '',
      name: _nameController.text.trim(),
      categoryId: _selectedCategoryId!,
      price: double.tryParse(_priceController.text.trim()) ?? 0,
      imageUrl: widget.initialItem?.imageUrl,
      modifierGroupIds: _selectedModifierGroupIds.toList(),
      description: widget.initialItem?.description ?? '',
      branchIds: _selectedBranchIds.isNotEmpty
          ? _selectedBranchIds.toList()
          : allBranches.map((branch) => branch.id).toList(),
    );
    if (isEditing) {
      await notifier.updateMenuItem(item);
    } else {
      await notifier.addMenuItem(item);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(menuViewModelProvider);
    final categories = state.categories;
    final modifierGroups = state.modifierGroups;
    final branches = state.branches;

    if (categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Item' : 'Add Item'),
        ),
        body: const Center(
          child: Text('Add a category before creating menu items.'),
        ),
      );
    }

    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
      _validateForm();
    }

    if (!_hasInitializedBranchSelection &&
        _selectedBranchIds.isEmpty &&
        branches.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _selectedBranchIds.isNotEmpty) return;
        setState(() {
          _selectedBranchIds.addAll(branches.map((b) => b.id));
          _hasInitializedBranchSelection = true;
          _validateForm();
        });
      });
    }

    final branchNameLookup = {
      for (final branch in branches) branch.id: branch.name,
    };
    final modifierNameLookup = {
      for (final group in modifierGroups) group.id: group.name,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Item' : 'Add Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Item Name', isRequired: true),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Enter item name'),
            ),
            const SizedBox(height: 16),
            _buildLabel('Base price', isRequired: true),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(hintText: '0.00'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            _buildLabel('Category', isRequired: true),
            DropdownMenu<String>(
              initialSelection: _selectedCategoryId,
              onSelected: (value) {
                setState(() => _selectedCategoryId = value);
                _validateForm();
              },
              dropdownMenuEntries: categories
                  .map(
                    (category) => DropdownMenuEntry(
                      value: category.id,
                      label: category.name,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            Text('Branches', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (branches.isEmpty)
              Text(
                'No branches available.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey),
              )
            else
              _buildSelectionChips(
                context: context,
                selectedIds: _selectedBranchIds,
                addButtonLabel: '+ Select branches',
                labelResolver: (id) => branchNameLookup[id] ?? 'Unknown branch',
                onAddTap: () => _showBranchSelection(branches, context),
                onRemove: (id) =>
                    setState(() => _selectedBranchIds.remove(id)),
              ),
            const SizedBox(height: 24),
            Text('Modifier Groups',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (modifierGroups.isEmpty)
              Text(
                'No modifier groups. Add one first.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey),
              )
            else
              _buildSelectionChips(
                context: context,
                selectedIds: _selectedModifierGroupIds,
                addButtonLabel: '+ Add modifier',
                labelResolver: (id) => modifierNameLookup[id] ?? 'Unknown',
                onAddTap: () =>
                    _showModifierSelection(modifierGroups, context),
                onRemove: (id) =>
                    setState(() => _selectedModifierGroupIds.remove(id)),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isFormValid ? _save : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Text(isEditing ? 'Save Changes' : 'Create Item'),
        ),
      ),
    );
  }

  Future<void> _showModifierSelection(
    List<ModifierGroup> groups,
    BuildContext context,
  ) async {
    await _showCheckboxSelectionSheet<ModifierGroup>(
      context: context,
      title: 'Select modifier groups',
      items: groups,
      selectedValues: _selectedModifierGroupIds,
      idBuilder: (group) => group.id,
      titleBuilder: (group) => group.name,
      subtitleBuilder: (group) =>
          '${group.options.length} options • ${group.selectionType == 'single' ? 'Single' : 'Multiple'}',
      onApply: (selection) {
        setState(() {
          _selectedModifierGroupIds
            ..clear()
            ..addAll(selection);
        });
      },
    );
  }

  Future<void> _showBranchSelection(
    List<MenuBranch> branches,
    BuildContext context,
  ) async {
    await _showCheckboxSelectionSheet<MenuBranch>(
      context: context,
      title: 'Select branches',
      items: branches,
      selectedValues: _selectedBranchIds,
      idBuilder: (branch) => branch.id,
      titleBuilder: (branch) => branch.name,
      onApply: (selection) {
        setState(() {
          _selectedBranchIds
            ..clear()
            ..addAll(selection);
          _hasInitializedBranchSelection = true;
        });
      },
    );
  }

  Future<void> _showCheckboxSelectionSheet<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required Set<String> selectedValues,
    required String Function(T) idBuilder,
    required String Function(T) titleBuilder,
    String Function(T)? subtitleBuilder,
    required void Function(Set<String>) onApply,
  }) async {
    final itemIds = items.map(idBuilder).toList();
    final selections = List<bool>.generate(
      itemIds.length,
      (index) => selectedValues.contains(itemIds[index]),
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final id = itemIds[index];
                        final isSelected = selections[index];
                        final subtitleText = subtitleBuilder != null
                            ? subtitleBuilder(item)
                            : null;
                        return CheckboxListTile(
                          key: ValueKey(id),
                          value: isSelected,
                          title: Text(titleBuilder(item)),
                          subtitle:
                              subtitleText != null ? Text(subtitleText) : null,
                          onChanged: (value) {
                            setSheetState(() {
                              selections[index] = value ?? false;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () {
                        final updatedSelection = <String>{};
                        for (var i = 0; i < selections.length; i++) {
                          if (selections[i]) {
                            updatedSelection.add(itemIds[i]);
                          }
                        }
                        onApply(updatedSelection);
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSelectionChips({
    required BuildContext context,
    required Iterable<String> selectedIds,
    required String Function(String id) labelResolver,
    required String addButtonLabel,
    required VoidCallback onAddTap,
    required void Function(String id) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: selectedIds
              .map((id) => Chip(
                    label: Text(labelResolver(id)),
                    onDeleted: () => onRemove(id),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: InkWell(
            onTap: onAddTap,
            child: CustomPaint(
              foregroundPainter: DashedBorderPainter(
                color: Theme.of(context).primaryColor,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(addButtonLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          ),
        ),
      ],
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
