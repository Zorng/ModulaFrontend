import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/theme/app_theme.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/inventory/data/branch_stock_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/components/branch_assignment.dart';
import 'package:modular_pos/features/inventory/ui/components/stock_item_form_error_mapper.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_section_card.dart';
import 'package:modular_pos/core/widgets/media/product_image_picker.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_item_detail/stock_item_detail_utils.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_item_detail/widgets/stock_item_branch_assignment_section.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _pieceSizeCtrl = TextEditingController(text: '1');
  final _baseUnitOptions = const ['ml', 'g', 'pcs'];
  final _typeOptions = const ['Ingredient', 'Sellable'];
  final _branchAssignments = <BranchAssignment>[];
  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;
  Uint8List? _selectedImageBytes;

  StockItemFormMode _mode = StockItemFormMode.create;
  StockItem? _originalItem;
  String? _categoryId;
  String? _baseUnit;
  bool _isActive = true;
  final _selectedTypes = <String>{};
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
      if (_mode == StockItemFormMode.create) {
        _bootstrapBranchAssignments();
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _pieceSizeCtrl.dispose();
    for (final assignment in _branchAssignments) {
      assignment.thresholdCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = !AppBreakpoints.isSmall(MediaQuery.of(context).size.width);
    final isEditing = _mode != StockItemFormMode.view;
    final categoryState = ref.watch(categoryControllerProvider);
    final loginState = ref.watch(loginControllerProvider);
    final userBranches = _resolveAvailableBranches(loginState);

    final categoryOptions = categoryState.categories;
    if (_mode == StockItemFormMode.create && categoryOptions.isEmpty) {
      _categoryId = null;
    }
    if (_mode == StockItemFormMode.create &&
        _branchAssignments.isEmpty &&
        userBranches.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            _mode != StockItemFormMode.create ||
            _branchAssignments.isNotEmpty) {
          return;
        }
        setState(() => _bootstrapBranchAssignments(userBranches));
      });
    }
    final usageTags = _selectedTypes.isEmpty
        ? const <String>[]
        : _selectedTypes.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(_title()),
        centerTitle: false,
        actions: [
          if (_mode == StockItemFormMode.view && _isActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextButton.icon(
                onPressed: _isSaving ? null : _archiveItem,
                icon: const Icon(Icons.archive_outlined, size: 18),
                label: const Text('Archive'),
              ),
            ),
          if (_mode == StockItemFormMode.view && !_isActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextButton.icon(
                onPressed: _isSaving ? null : _restoreItem,
                icon: const Icon(Icons.restore_outlined, size: 18),
                label: const Text('Restore'),
              ),
            ),
          if (_mode == StockItemFormMode.view && _isActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: isWide
                  ? SizedBox(
                      width: 120,
                      child: FilledButton.icon(
                        style: AppTheme.editActionButtonStyle,
                        onPressed: _isSaving
                            ? null
                            : () => setState(
                                () => _mode = StockItemFormMode.edit,
                              ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                    )
                  : TextButton(
                      onPressed: _isSaving
                          ? null
                          : () =>
                                setState(() => _mode = StockItemFormMode.edit),
                      child: const Text('Edit'),
                    ),
            ),
        ],
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
                          children: [_buildImagePicker(isEditing: isEditing)],
                        ),

                        SizedBox(height: sectionSpacing),

                        InventorySectionCard(
                          title: 'Item details',
                          description: 'Basic information about the item.',
                          backgroundColor: Colors.white,
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

              _SectionSpacer(
                spacing: sectionSpacing,
                child: InventorySectionCard(
                  title: 'Item usage',
                  description: 'How this item is used in your inventory.',
                  backgroundColor: Colors.white,
                  children: [
                    _UsageRow(
                      isEditing: isEditing,
                      isWide: isWide,
                      options: _typeOptions,
                      selected: _selectedTypes,
                      onToggle: (type, selected) {
                        setState(() {
                          if (selected) {
                            _selectedTypes.add(type);
                          } else {
                            _selectedTypes.remove(type);
                          }
                        });
                      },
                      fallbackTags: usageTags,
                    ),
                  ],
                ),
              ),
              _SectionSpacer(
                spacing: sectionSpacing,
                child: InventorySectionCard(
                  title: 'Assign branch',
                  description: 'Select which branches stock this item.',
                  backgroundColor: Colors.white,
                  children: [
                    StockItemBranchAssignmentSection(
                      isEditing: isEditing,
                      userBranches: userBranches,
                      branchAssignments: _branchAssignments,
                      branchNameResolver: (branchId) =>
                          branchName(branchId, userBranches),
                      usedBranchIds: _usedBranchIds,
                      onAddAssignment: () => setState(_addBranchAssignment),
                      onAssignmentChanged: () => setState(() {}),
                      onRemoveAssignment: (assignment) {
                        setState(() {
                          assignment.thresholdCtrl.dispose();
                          _branchAssignments.remove(assignment);
                        });
                      },
                      showCard: false,
                    ),
                  ],
                ),
              ),
              if (isEditing)
                _SectionSpacer(
                  spacing: sectionSpacing,
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _ActionRow(
                        isWide: isWide,
                        isSaving: _isSaving,
                        isCreate: _mode == StockItemFormMode.create,
                        onCancel: _handleCancel,
                        onSave: _submit,
                      ),
                    ),
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
    final statusField = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Status', style: Theme.of(context).textTheme.titleSmall),
        Text(
          _isActive ? 'Active' : 'Archived',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: _isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

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
        child: AbsorbPointer(
          absorbing: !isEditing,
          child: InventoryDropdown<String>(
            initialValue: _baseUnit,
            helperText: 'ml for liquids, g for solids, pcs for countable items',
            enabled: true,
            entries: _baseUnitOptions
                .map((unit) => DropdownMenuEntry(value: unit, label: unit))
                .toList(),
            onSelected: isEditing
                ? (value) => setState(() {
                    _baseUnit = value;
                    _baseUnitError = null;
                  })
                : null,
            errorText: isEditing ? _baseUnitError : null,
          ),
        ),
      ),
      _RequiredFieldLabel(
        text: 'Piece size',
        isRequired: true,
        child: TextFormField(
          controller: _pieceSizeCtrl,
          keyboardType: TextInputType.number,
          readOnly: !isEditing,
          enabled: isEditing,
          decoration: const InputDecoration(
            helperText:
                'How many base units equal 1 piece. e.g., 1 box = 24 units',
            helperMaxLines: 2,
          ),
          validator: isEditing
              ? (value) {
                  final text = (value ?? '').trim();
                  final parsed = int.tryParse(text);
                  if (parsed == null) {
                    return 'Must be a number';
                  }
                  if (parsed <= 0) {
                    return 'Must be >0';
                  }
                  return null;
                }
              : null,
        ),
      ),
      _RequiredFieldLabel(
        text: 'Barcode',
        child: TextFormField(
          controller: _barcodeCtrl,
          readOnly: !isEditing,
          enabled: isEditing,
          decoration: const InputDecoration(hintText: 'Optional'),
        ),
      ),
    ];

    if (!isWide) return [...fields, statusField];

    final rows = <Widget>[];
    for (var i = 0; i < fields.length; i += 3) {
      final first = fields[i];
      final second = (i + 1) < fields.length ? fields[i + 1] : null;
      final third = (i + 2) < fields.length ? fields[i + 2] : null;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: first),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: second ?? const SizedBox.shrink()),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: third ?? const SizedBox.shrink()),
          ],
        ),
      );
    }
    rows.add(statusField);
    return rows;
  }

  void _bootstrapFromItem(StockItem? item) {
    if (item == null) {
      _baseUnit = _baseUnitOptions.first;
      return;
    }
    _nameCtrl.text = item.name;
    _barcodeCtrl.text = '';
    _pieceSizeCtrl.text = item.pieceSize.toString();
    _categoryId = item.categoryId;
    _baseUnit = item.baseUnit;
    _isActive = item.isActive;
    _selectedTypes
      ..clear()
      ..add('Ingredient');
    _initBranchAssignments(item);
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

  List<UserBranch> _readAvailableBranches() {
    return _resolveAvailableBranches(ref.read(loginControllerProvider));
  }

  List<UserBranch> _resolveAvailableBranches(LoginState loginState) {
    final sessionBranches = loginState.session?.user.branches ?? const [];
    final branchMap = <String, UserBranch>{};

    for (final branch in sessionBranches) {
      final id = branch.branchId.isNotEmpty ? branch.branchId : branch.id;
      if (id.isEmpty) continue;
      branchMap[id] = branch;
    }
    if (branchMap.isNotEmpty) {
      return branchMap.values.toList(growable: false);
    }

    for (final option in loginState.branchOptions) {
      final id = option.branchId.trim();
      if (id.isEmpty) continue;
      branchMap[id] = UserBranch(
        id: id,
        branchId: id,
        name: option.branchName,
        role: '',
        active: true,
      );
    }
    return branchMap.values.toList(growable: false);
  }

  void _initBranchAssignments(StockItem item) {
    final branches = _readAvailableBranches();
    _branchAssignments.clear();
    if (item.branchId.isNotEmpty && item.branchId != 'all') {
      _branchAssignments.add(
        BranchAssignment(
          branchId: item.branchId,
          minThreshold: item.minThreshold,
        ),
      );
    } else if (branches.length == 1) {
      final b = branches.first;
      _branchAssignments.add(
        BranchAssignment(branchId: b.branchId.isNotEmpty ? b.branchId : b.id),
      );
    }
  }

  void _bootstrapBranchAssignments([List<UserBranch>? availableBranches]) {
    final branches = availableBranches ?? _readAvailableBranches();
    if (branches.isEmpty || _branchAssignments.isNotEmpty) return;
    if (branches.length == 1) {
      _branchAssignments.add(
        BranchAssignment(
          branchId: branches.first.branchId.isNotEmpty
              ? branches.first.branchId
              : branches.first.id,
        ),
      );
      return;
    }
    _branchAssignments.add(BranchAssignment());
  }

  void _addBranchAssignment() {
    final branches = _readAvailableBranches();
    if (branches.isEmpty) return;
    final used = _branchAssignments
        .map((e) => e.branchId)
        .whereType<String>()
        .toSet();
    String? next;
    for (final b in branches) {
      final id = b.branchId.isNotEmpty ? b.branchId : b.id;
      if (!used.contains(id)) {
        next = id;
        break;
      }
    }
    _branchAssignments.add(BranchAssignment(branchId: next));
  }

  Set<String> _usedBranchIds(BranchAssignment current) {
    return _branchAssignments
        .where((a) => a != current)
        .map((a) => a.branchId)
        .whereType<String>()
        .toSet();
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

    final branches = _readAvailableBranches();
    if (branches.isNotEmpty && _branchAssignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assign this item to at least one branch.'),
        ),
      );
      if (mounted) setState(() => _isSaving = false);
      return;
    }
    for (final assignment in _branchAssignments) {
      if (assignment.branchId == null || assignment.branchId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a branch for each assignment.')),
        );
        if (mounted) setState(() => _isSaving = false);
        return;
      }
    }

    final pieceSize = int.tryParse(_pieceSizeCtrl.text.trim()) ?? 1;

    final controller = ref.read(stockInventoryControllerProvider.notifier);
    try {
      if (_mode == StockItemFormMode.create) {
        final item = StockItem(
          id: '',
          name: _nameCtrl.text.trim(),
          categoryId: _categoryId,
          baseUnit: _baseUnit ?? 'pcs',
          pieceSize: pieceSize <= 0 ? 1 : pieceSize,
          branchId: '',
          branchName: '',
          onHand: 0,
          minThreshold: 0,
          isActive: true,
        );
        final created = await controller.addStockItem(
          item,
          imagePath: kIsWeb ? null : _selectedImagePath,
          imageBytes: _selectedImageBytes,
        );
        final assignmentWarning = await _syncBranchAssignments(
          stockItemId: created.id,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(assignmentWarning ?? 'Stock item added'),
          ),
        );
        Navigator.of(context).pop();
      } else {
        final current = _originalItem!;
        final updated = current.copyWith(
          name: _nameCtrl.text.trim(),
          categoryId: _categoryId,
          baseUnit: _baseUnit ?? current.baseUnit,
          pieceSize: pieceSize <= 0 ? current.pieceSize : pieceSize,
        );
        final saved = await controller.updateStockItem(
          updated,
          imagePath: kIsWeb ? null : _selectedImagePath,
          imageBytes: _selectedImageBytes,
        );
        final assignmentWarning = await _syncBranchAssignments(
          stockItemId: saved.id,
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
        ).showSnackBar(
          SnackBar(
            content: Text(assignmentWarning ?? 'Stock item saved'),
          ),
        );
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

  Future<String?> _syncBranchAssignments({required String stockItemId}) async {
    final repo = ref.read(branchStockRepositoryProvider);
    for (final assignment in _branchAssignments) {
      final branchId = assignment.branchId;
      if (branchId == null || branchId.isEmpty) continue;
      final minThreshold =
          int.tryParse(assignment.thresholdCtrl.text.trim()) ?? 0;
      try {
        await repo.assignToBranch(
          stockItemId: stockItemId,
          branchId: branchId,
          minThreshold: minThreshold < 0 ? 0 : minThreshold,
        );
        ref
            .read(stockInventoryControllerProvider.notifier)
            .updateBranchAssignment(
              stockItemId: stockItemId,
              branchId: branchId,
              minThreshold: minThreshold < 0 ? 0 : minThreshold,
            );
      } catch (error) {
        return _branchAssignmentWarningMessage(error);
      }
    }
    return null;
  }

  String _branchAssignmentWarningMessage(Object error) {
    final mapped = mapInventoryError(
      error,
      fallbackMessage: 'Stock item was saved, but branch assignment failed.',
    );
    final serverText = error.toString().toLowerCase();
    if (serverText.contains('not register to route') ||
        serverText.contains('not registered')) {
      return 'Stock item was saved, but branch assignment is not available in the current API.';
    }
    return 'Stock item was saved, but branch assignment failed: ${mapped.message}';
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
  });

  final String text;
  final Widget child;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
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
        ),
        child,
      ],
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({
    required this.isEditing,
    required this.isWide,
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.fallbackTags,
  });

  final bool isEditing;
  final bool isWide;
  final List<String> options;
  final Set<String> selected;
  final void Function(String type, bool selected) onToggle;
  final List<String> fallbackTags;

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return Row(
        children: options
            .map(
              (type) => Expanded(
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(type),
                  value: selected.contains(type),
                  onChanged: isEditing
                      ? (value) => onToggle(type, value ?? false)
                      : null,
                ),
              ),
            )
            .toList(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options
          .map(
            (type) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(type),
              value: selected.contains(type),
              onChanged: isEditing
                  ? (value) => onToggle(type, value ?? false)
                  : null,
            ),
          )
          .toList(),
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
    required this.isSaving,
    required this.isCreate,
    required this.onCancel,
    required this.onSave,
  });

  final bool isWide;
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

    if (!isWide) {
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
