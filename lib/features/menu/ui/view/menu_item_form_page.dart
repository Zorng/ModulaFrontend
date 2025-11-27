import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/widgets/network_image_helper_stub.dart'
    if (dart.library.html) 'package:modular_pos/core/widgets/network_image_helper_web.dart';
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
  String? _selectedImagePath;
  Uint8List? _selectedImageBytes;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();

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
      await notifier.updateMenuItem(
        item,
        imagePath: kIsWeb ? null : _selectedImagePath,
        imageBytes: _selectedImageBytes,
      );
    } else {
      await notifier.addMenuItem(
        item,
        imagePath: kIsWeb ? null : _selectedImagePath,
        imageBytes: _selectedImageBytes,
      );
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
            Center(child: _buildImagePicker(context)),
            const SizedBox(height: 16),
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
        child: isEditing
            ? Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        backgroundColor:
                            Theme.of(context).colorScheme.secondaryContainer,
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

  Widget _buildImagePicker(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.primaryColor;
    final radius = 14.0;
    final hasLocal = _selectedImagePath != null || _selectedImageBytes != null;
    final hasRemote = _existingImageUrl != null && _existingImageUrl!.isNotEmpty;

    Widget content;
    if (hasLocal) {
      content = _selectedImageBytes != null
          ? Image.memory(
              _selectedImageBytes!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          : Image.file(
              File(_selectedImagePath!),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );
    } else if (hasRemote) {
      content = buildAdaptiveNetworkImage(
        _existingImageUrl!,
        _buildUploadPlaceholder(color, radius),
      );
    } else {
      content = _buildUploadPlaceholder(color, radius);
    }

    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: double.infinity,
        child: AspectRatio(
          aspectRatio: 160 / 142,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.25),
                    BlendMode.darken,
                  ),
                  child: content,
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Tap to upload',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder(Color color, double radius) {
    return CustomPaint(
      foregroundPainter: DashedBorderPainter(
        color: color,
        strokeWidth: 1.4,
        dashWidth: 6,
        dashSpace: 4,
        borderRadius: radius,
      ),
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_upload_outlined, color: color, size: 32),
            const SizedBox(height: 6),
            Text('Upload image',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
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
    Navigator.of(context).pop();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
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
