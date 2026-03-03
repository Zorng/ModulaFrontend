import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modular_pos/core/theme/app_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/media/product_image_picker.dart';
import 'package:modular_pos/features/menu/domain/models/menu_branch.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/components/menu_form_field_label.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form/menu_item_form_error_mapper.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form/menu_item_form_utils.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form/widgets/selection_chips_field.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

class MenuItemFormPage extends ConsumerStatefulWidget {
  const MenuItemFormPage({super.key, this.initialItem});

  final MenuItem? initialItem;

  @override
  ConsumerState<MenuItemFormPage> createState() => _MenuItemFormPageState();
}

enum _MenuItemFormMode { create, view, edit }

class _MenuItemFormPageState extends ConsumerState<MenuItemFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;

  String? _selectedCategoryId;
  final Set<String> _selectedModifierGroupIds = {};
  final Set<String> _selectedBranchIds = {};
  bool _hasInitializedBranchSelection = false;

  String? _selectedImagePath;
  Uint8List? _selectedImageBytes;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();
  _MenuItemFormMode _mode = _MenuItemFormMode.create;

  bool _isSaving = false;
  bool _isActive = true;

  bool get isCreate => _mode == _MenuItemFormMode.create;
  bool get isView => _mode == _MenuItemFormMode.view;
  bool get isEditing => _mode != _MenuItemFormMode.view;

  String get _title => switch (_mode) {
    _MenuItemFormMode.create => 'Add menu item',
    _MenuItemFormMode.view => 'Menu item details',
    _MenuItemFormMode.edit => 'Edit menu item',
  };

  @override
  void initState() {
    super.initState();
    _mode = widget.initialItem == null
        ? _MenuItemFormMode.create
        : _MenuItemFormMode.view;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(menuViewModelProvider.notifier).loadMenu();
    });

    _nameController = TextEditingController(
      text: widget.initialItem?.name ?? '',
    );
    _priceController = TextEditingController(
      text: widget.initialItem?.price.toStringAsFixed(2) ?? '',
    );

    _selectedCategoryId = widget.initialItem?.categoryId;
    _selectedModifierGroupIds.addAll(
      widget.initialItem?.modifierGroupIds ?? const [],
    );
    _selectedBranchIds.addAll(widget.initialItem?.branchIds ?? const []);
    _hasInitializedBranchSelection = _selectedBranchIds.isNotEmpty;
    _existingImageUrl = widget.initialItem?.imageUrl;
    _isActive = widget.initialItem?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(menuViewModelProvider);
    final categories = state.categories;
    final modifierGroups = state.modifierGroups;
    final branches = state.branches;
    final isWide = !AppBreakpoints.isSmall(MediaQuery.of(context).size.width);

    if (!_hasInitializedBranchSelection &&
        _selectedBranchIds.isEmpty &&
        branches.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _selectedBranchIds.isNotEmpty) return;
        setState(() {
          _selectedBranchIds.addAll(branches.map((b) => b.id));
          _hasInitializedBranchSelection = true;
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: false,
        title: Text(_title),
        actions: [
          if (isView)
            _ViewActionBar(
              isWide: isWide,
              isActive: _isActive,
              isBusy: _isSaving,
              onEdit: () => setState(() => _mode = _MenuItemFormMode.edit),
              onToggleActive: _toggleActiveState,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionSpacer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wideSection = constraints.maxWidth >= 900;
                  if (wideSection) {
                    return _MenuSectionCard(
                      title: 'Item',
                      description: 'Image and basic information',
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: ProductImagePicker(
                                  size: const Size(220, 220),
                                  borderRadius: 16,
                                  imageBytes: _selectedImageBytes,
                                  imageUrl: _selectedImageBytes == null
                                      ? _existingImageUrl
                                      : null,
                                  readOnly: !isEditing,
                                  onPickImage: _pickImage,
                                  onClearLocalSelection:
                                      _selectedImageBytes != null
                                      ? isEditing
                                            ? () => setState(() {
                                                _selectedImageBytes = null;
                                                _selectedImagePath = null;
                                              })
                                            : null
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: _buildItemDetailFields(
                                  categories,
                                  isWide: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      _MenuSectionCard(
                        title: 'Item image',
                        children: [
                          Center(
                            child: ProductImagePicker(
                              size: const Size(220, 220),
                              borderRadius: 16,
                              imageBytes: _selectedImageBytes,
                              imageUrl: _selectedImageBytes == null
                                  ? _existingImageUrl
                                  : null,
                              readOnly: !isEditing,
                              onPickImage: _pickImage,
                              onClearLocalSelection: _selectedImageBytes != null
                                  ? isEditing
                                        ? () => setState(() {
                                            _selectedImageBytes = null;
                                            _selectedImagePath = null;
                                          })
                                        : null
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _MenuSectionCard(
                        title: 'Item details',
                        description: 'Basic information about the menu item.',
                        children: _buildItemDetailFields(
                          categories,
                          isWide: false,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            _SectionSpacer(
              child: _MenuSectionCard(
                title: 'Assign branch',
                description: 'Select which branches provide this item.',
                children: [
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
                      addButtonLabel: 'Select branches',
                      labelResolver: (id) =>
                          branchNameLookup[id] ?? 'Unknown branch',
                      onAddTap: () => _showBranchSelection(branches),
                      onRemove: (id) =>
                          setState(() => _selectedBranchIds.remove(id)),
                      editable: isEditing,
                    ),
                ],
              ),
            ),
            _SectionSpacer(
              child: _MenuSectionCard(
                title: 'Modifier groups',
                description: 'Assign modifier groups for this item.',
                children: [
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
                      addButtonLabel: 'Add modifier',
                      labelResolver: (id) =>
                          modifierNameLookup[id] ?? 'Unknown',
                      onAddTap: () => _showModifierSelection(modifierGroups),
                      onRemove: (id) =>
                          setState(() => _selectedModifierGroupIds.remove(id)),
                      editable: isEditing,
                    ),
                ],
              ),
            ),
            if (isEditing)
              _SectionSpacer(
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _MenuActionRow(
                      isSaving: _isSaving,
                      isCreate: isCreate,
                      onCancel: _handleCancel,
                      onSave: _save,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItemDetailFields(
    List<MenuCategory> categories, {
    required bool isWide,
  }) {
    final isSmallScreen = AppBreakpoints.isSmall(
      MediaQuery.of(context).size.width,
    );
    final nameField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MenuFormFieldLabel(text: 'Item name', isRequired: true),
        TextFormField(
          controller: _nameController,
          maxLength: 20,
          readOnly: !isEditing,
          enabled: isEditing,
          decoration: const InputDecoration(hintText: 'Enter item name'),
          validator: (value) {
            final text = (value ?? '').trim();
            if (text.isEmpty) return 'Required';
            return null;
          },
        ),
      ],
    );
    final priceField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MenuFormFieldLabel(text: 'Base price', isRequired: true),
        TextFormField(
          controller: _priceController,
          readOnly: !isEditing,
          enabled: isEditing,
          decoration: const InputDecoration(hintText: '0.00'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            _TwoDecimalTextInputFormatter(),
          ],
          validator: (value) {
            final text = (value ?? '').trim();
            if (text.isEmpty) return 'Required';
            final parsed = double.tryParse(text);
            if (parsed == null) return 'Invalid price';
            if (parsed < 0) return 'Must be >= 0';
            return null;
          },
        ),
      ],
    );
    final categoryField = LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MenuFormFieldLabel(text: 'Category'),
            DropdownMenu<String>(
              width: constraints.maxWidth,
              initialSelection: _selectedCategoryId ?? '',
              enabled: isEditing,
              onSelected: isEditing
                  ? (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    }
                  : null,
              dropdownMenuEntries: [
                const DropdownMenuEntry<String>(
                  value: '',
                  label: 'Uncategorized',
                ),
                ...categories.map<DropdownMenuEntry<String>>(
                  (category) => DropdownMenuEntry<String>(
                    value: category.id,
                    label: category.name,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    return [
      if (isSmallScreen && isCreate) ...[
        nameField,
        const SizedBox(height: 16),
        priceField,
      ] else
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: isWide ? 2 : 1, child: nameField),
            const SizedBox(width: 16),
            Expanded(flex: 1, child: priceField),
          ],
        ),
      const SizedBox(height: 16),
      categoryField,
    ];
  }

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final availableBranches = ref.read(menuViewModelProvider).branches;
    if (availableBranches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No branch options are available. Please reload and try again.',
          ),
        ),
      );
      return;
    }

    if (_selectedBranchIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one branch before saving.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(menuViewModelProvider.notifier);
      final item = MenuItem(
        id: widget.initialItem?.id ?? '',
        name: _nameController.text.trim(),
        categoryId: _selectedCategoryId ?? '',
        price: double.parse(_priceController.text.trim()),
        imageUrl: widget.initialItem?.imageUrl,
        modifierGroupIds: _selectedModifierGroupIds.toList(),
        description: widget.initialItem?.description ?? '',
        branchIds: _selectedBranchIds.toList(growable: false),
        isActive: _isActive,
      );

      MenuItem saved;
      if (_mode == _MenuItemFormMode.edit) {
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
    } catch (e) {
      if (!mounted) return;
      final message = mapMenuItemSaveErrorMessage(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

  void _handleCancel() {
    if (_mode == _MenuItemFormMode.create) {
      Navigator.of(context).maybePop();
      return;
    }
    if (_mode == _MenuItemFormMode.edit) {
      setState(_resetToView);
    }
  }

  void _resetToView() {
    _mode = _MenuItemFormMode.view;
    _isSaving = false;
    _selectedImageBytes = null;
    _selectedImagePath = null;
    _nameController.text = widget.initialItem?.name ?? '';
    _priceController.text = widget.initialItem?.price.toStringAsFixed(2) ?? '';
    _selectedCategoryId = widget.initialItem?.categoryId;
    _selectedModifierGroupIds
      ..clear()
      ..addAll(widget.initialItem?.modifierGroupIds ?? const []);
    _selectedBranchIds
      ..clear()
      ..addAll(widget.initialItem?.branchIds ?? const []);
    _existingImageUrl = widget.initialItem?.imageUrl;
    _isActive = widget.initialItem?.isActive ?? true;
  }

  Future<void> _toggleActiveState() async {
    final current = widget.initialItem;
    if (current == null) return;
    if (_isActive) {
      final confirmed = await _confirmArchive();
      if (!confirmed) return;
    }
    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(menuViewModelProvider.notifier);
      if (_isActive) {
        await notifier.archiveMenuItem(current.id);
      } else {
        await notifier.restoreMenuItem(current.id);
      }
      if (!mounted) return;
      setState(() => _isActive = !_isActive);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isActive ? 'Menu item restored' : 'Menu item archived',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update item status: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _confirmArchive() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 44,
                  color: Colors.orange,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Archive this item?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want to archive this item? You can restore it later.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
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
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
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
          '${group.options.length} options - ${group.selectionType == 'single' ? 'Single' : 'Multiple'}',
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

class _ViewActionBar extends StatelessWidget {
  const _ViewActionBar({
    required this.isWide,
    required this.isActive,
    required this.isBusy,
    required this.onEdit,
    required this.onToggleActive,
  });

  final bool isWide;
  final bool isActive;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return PopupMenuButton<_ViewAction>(
        enabled: !isBusy,
        onSelected: (value) {
          if (value == _ViewAction.edit) {
            onEdit();
            return;
          }
          onToggleActive();
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: _ViewAction.edit, child: Text('Edit')),
          PopupMenuItem(
            value: _ViewAction.toggleActive,
            child: Text(isActive ? 'Archive' : 'Restore'),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            SizedBox(
              width: 120,
              child: FilledButton.icon(
                onPressed: isBusy ? null : onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
            )
          else
            SizedBox(
              width: 120,
              child: FilledButton(
                onPressed: isBusy ? null : onToggleActive,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restore, size: 18),
                    SizedBox(width: 6),
                    Text('Restore'),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.secondaryContainer,
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onSecondaryContainer,
              ),
              onPressed: isBusy ? null : (isActive ? onToggleActive : onEdit),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? Icons.archive_outlined : Icons.edit_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(isActive ? 'Archive' : 'Edit'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ViewAction { edit, toggleActive }

class _MenuSectionCard extends StatelessWidget {
  const _MenuSectionCard({
    required this.title,
    this.description,
    required this.children,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(description!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SectionSpacer extends StatelessWidget {
  const _SectionSpacer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: child);
  }
}

class _MenuActionRow extends StatelessWidget {
  const _MenuActionRow({
    required this.isSaving,
    required this.isCreate,
    required this.onCancel,
    required this.onSave,
  });

  final bool isSaving;
  final bool isCreate;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final cancelStyle = AppTheme.cancelActionButtonStyle;
    final saveStyle = FilledButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 140,
          child: FilledButton(
            style: cancelStyle,
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 160,
          child: FilledButton(
            style: saveStyle,
            onPressed: isSaving ? null : onSave,
            child: Text(isCreate ? 'Save item' : 'Save'),
          ),
        ),
      ],
    );
  }
}

class _TwoDecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (text.indexOf('.') != text.lastIndexOf('.')) {
      return oldValue;
    }
    if (text.contains('.')) {
      final parts = text.split('.');
      if (parts.length > 2) return oldValue;
      if (parts[1].length > 2) return oldValue;
    }
    return newValue;
  }
}
