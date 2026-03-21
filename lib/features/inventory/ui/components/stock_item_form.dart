import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/theme/app_theme.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/components/stock_item_form_error_mapper.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_section_card.dart';
import 'package:modular_pos/core/widgets/media/product_image_picker.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';

enum StockItemFormMode { create, view, edit }

class StockItemFormPage extends ConsumerStatefulWidget {
  const StockItemFormPage({super.key, required this.mode, this.item})
    : assert(
        mode == StockItemFormMode.create || item != null,
        'item is required for view/edit',
      );

  final StockItemFormMode mode;
  final StockItem? item;

  @override
  ConsumerState<StockItemFormPage> createState() => _StockItemFormPageState();
}

class _StockItemFormPageState extends ConsumerState<StockItemFormPage> {
  static const String _uncategorizedValue = '__uncategorized__';
  static const double _formCardElevation = 0;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _thresholdCtrl = TextEditingController(text: '0');
  final _baseUnitOptions = const ['ml', 'g', 'pcs'];
  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;
  Uint8List? _selectedImageBytes;

  StockItemFormMode _mode = StockItemFormMode.create;
  StockItem? _originalItem;
  String? _categoryId;
  String? _baseUnit;
  bool _isActive = true;
  String? _nameError;
  String? _baseUnitError;
  String? _imageError;
  bool _isSaving = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    _originalItem = widget.item;
    _bootstrapFromItem(widget.item);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryControllerProvider.notifier).loadCategories();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = !AppBreakpoints.isSmall(MediaQuery.of(context).size.width);
    final isEditing = _mode != StockItemFormMode.view;
    final categoryState = ref.watch(categoryControllerProvider);

    final categoryOptions = categoryState.categories;
    if (_mode == StockItemFormMode.create && categoryOptions.isEmpty) {
      _categoryId = null;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(_title()),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _autovalidateMode,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sectionSpacing = isWide ? 18.0 : 16.0;
            final content = <Widget>[
              _SectionSpacer(
                spacing: sectionSpacing,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;

                    if (isWide) {
                      // WIDESCREEN → ONE SECTION, SIDE BY SIDE
                      return InventorySectionCard(
                        title: 'Item',
                        description: 'Image and basic information',
                        backgroundColor: Colors.white,
                        elevation: _formCardElevation,
                        shadowColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // LEFT: Image
                              Expanded(
                                flex: 1,
                                child: _buildImagePicker(isEditing: isEditing),
                              ),

                              const SizedBox(width: 24),

                              // RIGHT: Details
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: _buildItemDetails(
                                    isWide: true,
                                    isEditing: isEditing,
                                    categoryOptions: categoryOptions,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    // MOBILE → STACKED (UNCHANGED)
                    return Column(
                      children: [
                        InventorySectionCard(
                          title: 'Item image',
                          backgroundColor: Colors.white,
                          elevation: _formCardElevation,
                          shadowColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          children: [_buildImagePicker(isEditing: isEditing)],
                        ),

                        SizedBox(height: sectionSpacing),

                        InventorySectionCard(
                          title: 'Item details',
                          description: 'Basic information about the item.',
                          backgroundColor: Colors.white,
                          elevation: _formCardElevation,
                          shadowColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          children: _buildItemDetails(
                            isWide: false,
                            isEditing: isEditing,
                            categoryOptions: categoryOptions,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: _ActionRow(
                  isWide: isWide,
                  mode: _mode,
                  isSaving: _isSaving,
                  isActive: _isActive,
                  onCancel: _handleCancel,
                  onSave: _submit,
                  onEdit: () => setState(() => _mode = StockItemFormMode.edit),
                  onArchive: _archiveItem,
                  onRestore: _restoreItem,
                ),
              ),
            ];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: content,
            );
          },
        ),
      ),
    );
  }

  String _title() => switch (_mode) {
    StockItemFormMode.create => 'Add stock item',
    StockItemFormMode.view => 'Stock item details',
    StockItemFormMode.edit => 'Edit stock item',
  };

  Widget _buildImagePicker({required bool isEditing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: ProductImagePicker(
            size: const Size(220, 220),
            borderRadius: 16,
            imageBytes: _selectedImageBytes,
            imageUrl: _selectedImageBytes == null
                ? _originalItem?.imageUrl
                : null,
            readOnly: !isEditing,
            placeholderLabel: isEditing ? 'Upload image' : 'No image',
            showTapToChangeHint: isEditing,
            onPickImage: _pickImage,
            onClearLocalSelection: isEditing ? _clearLocalImageSelection : null,
          ),
        ),
        if (_imageError != null) ...[
          const SizedBox(height: 12),
          Text(
            _imageError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  List<Widget> _buildItemDetails({
    required bool isWide,
    required bool isEditing,
    required List<InventoryCategory> categoryOptions,
  }) {
    final canEditBaseUnit = isEditing && _mode == StockItemFormMode.create;
    final fields = <Widget>[
      _RequiredFieldLabel(
        text: 'Item name',
        isRequired: true,
        child: TextFormField(
          controller: _nameCtrl,
          onChanged: (_) {
            if (_nameError == null) return;
            setState(() => _nameError = null);
          },
          maxLength: 20,
          enabled: isEditing,
          readOnly: !isEditing,
          decoration: InputDecoration(
            hintText: 'e.g., Milk 1000ml',
            errorText: isEditing ? _nameError : null,
          ),
          validator: isEditing
              ? (value) {
                  return value == null || value.trim().isEmpty
                      ? 'Required'
                      : null;
                }
              : null,
        ),
      ),
      _RequiredFieldLabel(
        text: 'Category',
        isOptional: true,
        child: AbsorbPointer(
          absorbing: !isEditing,
          child: InventoryDropdown<String>(
            initialValue: _categoryId?.isNotEmpty == true
                ? _categoryId
                : _uncategorizedValue,
            enabled: true,
            entries: [
              const DropdownMenuEntry(
                value: _uncategorizedValue,
                label: 'Uncategorized',
              ),
              ...categoryOptions.map(
                (category) =>
                    DropdownMenuEntry(value: category.id, label: category.name),
              ),
            ],
            onSelected: isEditing
                ? (value) {
                    if (value == null) return;
                    if (value == _uncategorizedValue) {
                      setState(() {
                        _categoryId = null;
                      });
                      return;
                    }
                    final selected = categoryOptions.firstWhere(
                      (c) => c.id == value,
                      orElse: () => InventoryCategory(
                        id: value,
                        name: value,
                        isActive: true,
                      ),
                    );
                    setState(() {
                      _categoryId = selected.id;
                    });
                  }
                : null,
          ),
        ),
      ),
      _RequiredFieldLabel(
        text: 'Base unit',
        isRequired: true,
        child: canEditBaseUnit
            ? InventoryDropdown<String>(
                initialValue: _baseUnit,
                helperText:
                    'ml for liquids, g for solids, pcs for countable items',
                enabled: true,
                entries: _baseUnitOptions
                    .map((unit) => DropdownMenuEntry(value: unit, label: unit))
                    .toList(),
                onSelected: (value) => setState(() {
                  _baseUnit = value;
                  _baseUnitError = null;
                }),
                errorText: _baseUnitError,
              )
            : TextFormField(
                initialValue: _baseUnit ?? '',
                enabled: false,
                decoration: const InputDecoration(
                  helperText: 'Base unit is fixed after creation.',
                ),
              ),
      ),
      _RequiredFieldLabel(
        text: 'Low stock threshold',
        isOptional: true,
        child: TextFormField(
          controller: _thresholdCtrl,
          keyboardType: TextInputType.number,
          readOnly: !isEditing,
          enabled: isEditing,
          decoration: const InputDecoration(
            helperText: 'Threshold sent as lowStockThreshold.',
          ),
          validator: isEditing
              ? (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return null;
                  final parsed = int.tryParse(text);
                  if (parsed == null) {
                    return 'Must be a number';
                  }
                  if (parsed < 0) {
                    return 'Must be 0 or greater';
                  }
                  return null;
                }
              : null,
        ),
      ),
    ];

    if (!isWide) return fields;

    return [
      _buildWideFieldRow(first: fields[0], second: fields[1]),
      _buildWideFieldRow(first: fields[2], second: fields[3]),
    ];
  }

  Widget _buildWideFieldRow({
    required Widget first,
    Widget? second,
    Widget? third,
  }) {
    final children = <Widget>[Expanded(flex: 2, child: first)];

    if (second != null) {
      children.add(const SizedBox(width: 16));
      children.add(Expanded(flex: 2, child: second));
    }

    if (third != null) {
      children.add(const SizedBox(width: 16));
      children.add(Expanded(flex: 2, child: third));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  void _bootstrapFromItem(StockItem? item) {
    if (item == null) {
      _baseUnit = _baseUnitOptions.first;
      return;
    }
    _nameCtrl.text = item.name;
    _categoryId = item.categoryId;
    _baseUnit = item.baseUnit;
    _isActive = item.isActive;
    _thresholdCtrl.text = item.minThreshold.toString();
  }

  void _cancelEditing() {
    setState(() {
      _mode = StockItemFormMode.view;
      _selectedImageBytes = null;
      _selectedImagePath = null;
      _nameError = null;
      _baseUnitError = null;
      _imageError = null;
      _autovalidateMode = AutovalidateMode.disabled;
    });
    _bootstrapFromItem(_originalItem);
  }

  void _handleCancel() {
    if (_mode == StockItemFormMode.create) {
      Navigator.of(context).pop();
      return;
    }
    _cancelEditing();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImagePath = picked.path;
        _imageError = null;
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

  void _clearLocalImageSelection() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImagePath = null;
      _imageError = null;
    });
  }

  bool _validateRequired() {
    if (_nameError != null || _baseUnitError != null || _imageError != null) {
      setState(() {
        _nameError = null;
        _baseUnitError = null;
        _imageError = null;
      });
    }
    var valid = _formKey.currentState?.validate() ?? false;
    if (_baseUnit == null || _baseUnit!.isEmpty) {
      setState(() => _baseUnitError = 'Please select a base unit');
      valid = false;
    }
    return valid;
  }

  Future<void> _submit() async {
    if (!_validateRequired()) return;
    setState(() {
      _isSaving = true;
      _imageError = null;
    });

    final minThreshold = int.tryParse(_thresholdCtrl.text.trim()) ?? 0;

    final controller = ref.read(stockInventoryControllerProvider.notifier);
    try {
      if (_mode == StockItemFormMode.create) {
        final item = StockItem(
          id: '',
          name: _nameCtrl.text.trim(),
          categoryId: _categoryId,
          baseUnit: _baseUnit ?? 'pcs',
          pieceSize: 1,
          branchId: '',
          branchName: '',
          onHand: 0,
          minThreshold: minThreshold < 0 ? 0 : minThreshold,
          isActive: true,
        );
        await controller.addStockItem(
          item,
          imagePath: kIsWeb ? null : _selectedImagePath,
          imageBytes: _selectedImageBytes,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Stock item added')));
        Navigator.of(context).pop();
      } else {
        final current = _originalItem!;
        final updated = current.copyWith(
          name: _nameCtrl.text.trim(),
          categoryId: _categoryId,
          minThreshold: minThreshold < 0 ? 0 : minThreshold,
        );
        final saved = await controller.updateStockItem(
          updated,
          imagePath: kIsWeb ? null : _selectedImagePath,
          imageBytes: _selectedImageBytes,
        );
        if (!mounted) return;
        setState(() {
          _originalItem = saved;
          _mode = StockItemFormMode.view;
          _selectedImageBytes = null;
          _selectedImagePath = null;
          _imageError = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Stock item saved')));
      }
    } catch (e) {
      if (!mounted) return;
      final mapped = mapStockItemFormSaveError(
        e,
        fallbackMessage: _mode == StockItemFormMode.create
            ? 'Failed to add stock item.'
            : 'Failed to save stock item.',
      );
      switch (mapped.field) {
        case StockItemFormErrorField.name:
          setState(() {
            _nameError = mapped.message;
            _autovalidateMode = AutovalidateMode.always;
          });
          _formKey.currentState?.validate();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(mapped.message)));
          return;
        case StockItemFormErrorField.baseUnit:
          setState(() {
            _baseUnitError = mapped.message;
            _autovalidateMode = AutovalidateMode.always;
          });
          _formKey.currentState?.validate();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(mapped.message)));
          return;
        case StockItemFormErrorField.image:
          setState(() {
            _imageError = mapped.message;
            _autovalidateMode = AutovalidateMode.always;
          });
          _formKey.currentState?.validate();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(mapped.message)));
          return;
        case StockItemFormErrorField.general:
          break;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapped.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _restoreItem() async {
    final current = _originalItem;
    if (current == null || current.id.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(stockInventoryControllerProvider.notifier)
          .restoreStockItem(current.id);
      if (!mounted) return;
      setState(() {
        _isActive = true;
        _originalItem = current.copyWith(isActive: true);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Stock item restored')));
    } catch (e) {
      if (!mounted) return;
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to restore stock item.',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapped.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _archiveItem() async {
    final current = _originalItem;
    if (current == null || current.id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Archive stock item?'),
          content: Text(
            '"${current.name}" will move to archived views until it is restored.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(stockInventoryControllerProvider.notifier)
          .archiveStockItem(current.id);
      if (!mounted) return;
      setState(() {
        _isActive = false;
        _originalItem = current.copyWith(isActive: false);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Stock item archived')));
    } catch (e) {
      if (!mounted) return;
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to archive stock item.',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapped.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _RequiredFieldLabel extends StatelessWidget {
  const _RequiredFieldLabel({
    required this.text,
    required this.child,
    this.isRequired = false,
    this.isOptional = false,
  });

  final String text;
  final Widget child;
  final bool isRequired;
  final bool isOptional;

  @override
  Widget build(BuildContext context) {
    final label = isOptional ? '$text (optional)' : text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RichText(
            text: TextSpan(
              text: label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _SectionSpacer extends StatelessWidget {
  const _SectionSpacer({required this.child, required this.spacing});

  final Widget child;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacing),
      child: child,
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.isWide,
    required this.mode,
    required this.isSaving,
    required this.isActive,
    required this.onCancel,
    required this.onSave,
    required this.onEdit,
    required this.onArchive,
    required this.onRestore,
  });

  final bool isWide;
  final StockItemFormMode mode;
  final bool isSaving;
  final bool isActive;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final cancelStyle = AppTheme.cancelActionButtonStyle;
    final saveStyle = FilledButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
    );
    final archiveStyle = OutlinedButton.styleFrom(
      foregroundColor: AppTheme.editActionColor,
      side: const BorderSide(color: AppTheme.editActionColor),
      minimumSize: const Size.fromHeight(48),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    if (mode == StockItemFormMode.view) {
      if (!isActive) {
        if (!isWide) {
          return SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSaving ? null : onRestore,
              icon: const Icon(Icons.restore_outlined, size: 18),
              label: const Text('Restore'),
            ),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 160,
              child: FilledButton.icon(
                onPressed: isSaving ? null : onRestore,
                icon: const Icon(Icons.restore_outlined, size: 18),
                label: const Text('Restore'),
              ),
            ),
          ],
        );
      }

      if (!isWide) {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: archiveStyle,
                onPressed: isSaving ? null : onArchive,
                icon: const Icon(Icons.archive_outlined, size: 18),
                label: const Text('Archive'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: AppTheme.editActionButtonStyle,
                onPressed: isSaving ? null : onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
            ),
          ],
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 160,
            child: OutlinedButton.icon(
              style: archiveStyle,
              onPressed: isSaving ? null : onArchive,
              icon: const Icon(Icons.archive_outlined, size: 18),
              label: const Text('Archive'),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: FilledButton.icon(
              style: AppTheme.editActionButtonStyle,
              onPressed: isSaving ? null : onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
            ),
          ),
        ],
      );
    }

    if (!isWide) {
      return Row(
        children: [
          Expanded(
            child: FilledButton(
              style: cancelStyle,
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              style: saveStyle,
              onPressed: isSaving ? null : onSave,
              child: Text(
                mode == StockItemFormMode.create ? 'Save item' : 'Save',
              ),
            ),
          ),
        ],
      );
    }

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
            child: Text(
              mode == StockItemFormMode.create ? 'Save item' : 'Save',
            ),
          ),
        ),
      ],
    );
  }
}
