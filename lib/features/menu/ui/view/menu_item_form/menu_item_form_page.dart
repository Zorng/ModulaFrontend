import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modular_pos/core/widgets/media/product_image_picker.dart';
import 'package:modular_pos/features/menu/domain/models/menu_branch.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/components/menu_form_field_label.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form/menu_item_form_utils.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form/widgets/selection_chips_field.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

class MenuItemFormPage extends ConsumerStatefulWidget {
  const MenuItemFormPage({super.key, this.initialItem});

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
  String? _selectedImagePath;
  Uint8List? _selectedImageBytes;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();

  bool get isEditing => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(menuViewModelProvider.notifier).loadMenu();
    });
    _nameController = TextEditingController(text: widget.initialItem?.name);
    _priceController = TextEditingController(
      text: widget.initialItem?.price.toStringAsFixed(2),
    );
    _selectedCategoryId = widget.initialItem?.categoryId;
    _selectedModifierGroupIds.addAll(
      widget.initialItem?.modifierGroupIds ?? const [],
    );
    _selectedBranchIds.addAll(widget.initialItem?.branchIds ?? const []);
    _hasInitializedBranchSelection = _selectedBranchIds.isNotEmpty;
    _existingImageUrl = widget.initialItem?.imageUrl;
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
    final isValid =
        _nameController.text.trim().isNotEmpty &&
        _priceController.text.trim().isNotEmpty &&
        _selectedCategoryId != null;
    if (_isFormValid != isValid) setState(() => _isFormValid = isValid);
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

    MenuItem saved;
    if (isEditing) {
      saved = await notifier.updateMenuItem(
        item,
        imagePath: kIsWeb ? null : _selectedImagePath,
        imageBytes: _selectedImageBytes,
      );
    } else {
      saved = await notifier.addMenuItem(
        item,
        imagePath: kIsWeb ? null : _selectedImagePath,
        imageBytes: _selectedImageBytes,
      );
    }
    await notifier.loadItemWithModifiers(saved.id);
    if (mounted) context.pop(saved);
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
          centerTitle: false,
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
        centerTitle: false,
        title: Text(isEditing ? 'Edit Item' : 'Add Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ProductImagePicker(
                imageBytes: _selectedImageBytes,
                imageUrl: _selectedImageBytes == null
                    ? _existingImageUrl
                    : null,
                onPickImage: _pickImage,
                onClearLocalSelection: _selectedImageBytes != null
                    ? () => setState(() {
                        _selectedImageBytes = null;
                        _selectedImagePath = null;
                      })
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            const MenuFormFieldLabel(text: 'Item Name', isRequired: true),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Enter item name'),
            ),
            const SizedBox(height: 16),
            const MenuFormFieldLabel(text: 'Base price', isRequired: true),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(hintText: '0.00'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            const MenuFormFieldLabel(text: 'Category', isRequired: true),
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
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              )
            else
              SelectionChipsField(
                selectedIds: _selectedBranchIds,
                addButtonLabel: '+ Select branches',
                labelResolver: (id) => branchNameLookup[id] ?? 'Unknown branch',
                onAddTap: () => _showBranchSelection(branches),
                onRemove: (id) => setState(() => _selectedBranchIds.remove(id)),
              ),
            const SizedBox(height: 24),
            Text(
              'Modifier Groups',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (modifierGroups.isEmpty)
              Text(
                'No modifier groups. Add one first.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              )
            else
              SelectionChipsField(
                selectedIds: _selectedModifierGroupIds,
                addButtonLabel: '+ Add modifier',
                labelResolver: (id) => modifierNameLookup[id] ?? 'Unknown',
                onAddTap: () => _showModifierSelection(modifierGroups),
                onRemove: (id) =>
                    setState(() => _selectedModifierGroupIds.remove(id)),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: isEditing
            ? Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                      ),
                      onPressed: _deleteItem,
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: _isFormValid ? _save : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: _isFormValid ? _save : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Create Item'),
              ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImagePath = picked.path;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Image picker not available. Please fully restart the app after running flutter pub get.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteItem() async {
    final id = widget.initialItem?.id ?? '';
    if (id.isEmpty) return;
    await ref.read(menuViewModelProvider.notifier).deleteMenuItem(id);
    if (!mounted) return;
    context.pop();
    if (context.canPop()) {
      context.pop();
    }
  }

  Future<void> _showModifierSelection(List<ModifierGroup> groups) async {
    await showCheckboxSelectionSheet<ModifierGroup>(
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

  Future<void> _showBranchSelection(List<MenuBranch> branches) async {
    await showCheckboxSelectionSheet<MenuBranch>(
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
}
