import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/components/branch_assignment.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_item_detail/stock_item_detail_utils.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_item_detail/widgets/stock_item_branch_assignment_section.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_item_detail/widgets/stock_item_image_section.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_item_detail/widgets/stock_item_info_section.dart';
import 'package:modular_pos/features/inventory/ui/view/stock_item_detail/widgets/stock_item_save_section.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';

class StockItemDetailPage extends ConsumerStatefulWidget {
  const StockItemDetailPage({super.key, required this.item});

  final StockItem item;

  @override
  ConsumerState<StockItemDetailPage> createState() =>
      _StockItemDetailPageState();
}

class _StockItemDetailPageState extends ConsumerState<StockItemDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _typeOptions = const ['Ingredient', 'Sellable'];
  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;
  Uint8List? _selectedImageBytes;

  bool _isEditing = false;
  late StockItem _editableData;
  late TextEditingController _nameCtrl;
  late TextEditingController _categoryCtrl;
  late String? _categoryId;
  late TextEditingController _pieceSizeCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _lastRestockCtrl;
  late TextEditingController _expiryCtrl;
  late Set<String> _selectedTypes;
  late String _baseUnit;
  late bool _isActive;
  final _branchAssignments = <BranchAssignment>[];

  @override
  void initState() {
    super.initState();
    _editableData = widget.item;
    _nameCtrl = TextEditingController(text: _editableData.name);
    _categoryCtrl = TextEditingController(text: _editableData.category);
    _categoryId = _editableData.categoryId;
    _pieceSizeCtrl = TextEditingController(
      text: _editableData.pieceSize.toString(),
    );
    _barcodeCtrl = TextEditingController(text: _editableData.barcode ?? '');
    _lastRestockCtrl = TextEditingController(
      text: _editableData.lastRestockDate,
    );
    _expiryCtrl = TextEditingController(text: _editableData.expiryDate);
    _selectedTypes = {..._editableData.usageTags};
    _baseUnit = _editableData.baseUnit;
    _isActive = _editableData.isActive;
    _initBranchAssignments();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _pieceSizeCtrl.dispose();
    _barcodeCtrl.dispose();
    _lastRestockCtrl.dispose();
    _expiryCtrl.dispose();
    for (final a in _branchAssignments) {
      a.thresholdCtrl.dispose();
    }
    super.dispose();
  }

  void _startEditing() => setState(() => _isEditing = true);

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _nameCtrl.text = _editableData.name;
      _categoryCtrl.text = _editableData.category;
      _categoryId = _editableData.categoryId;
      _baseUnit = _editableData.baseUnit;
      _pieceSizeCtrl.text = _editableData.pieceSize.toString();
      _barcodeCtrl.text = _editableData.barcode ?? '';
      _lastRestockCtrl.text = _editableData.lastRestockDate;
      _expiryCtrl.text = _editableData.expiryDate;
      _selectedTypes = {..._editableData.usageTags};
      _isActive = _editableData.isActive;
    });
  }

  Future<void> _saveChanges() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final pieceSize = int.tryParse(_pieceSizeCtrl.text.trim());
    if (pieceSize == null || pieceSize <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Piece size must be greater than 0')),
      );
      return;
    }

    final updated = _editableData.copyWith(
      name: _nameCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      categoryId: _categoryId,
      baseUnit: _baseUnit,
      pieceSize: pieceSize,
      barcode: _barcodeCtrl.text.trim().isEmpty
          ? null
          : _barcodeCtrl.text.trim(),
      lastRestockDate: _lastRestockCtrl.text.trim(),
      expiryDate: _expiryCtrl.text.trim(),
      usageTags: _selectedTypes.toList(),
      isActive: _isActive,
    );

    ref
        .read(stockInventoryControllerProvider.notifier)
        .updateStockItem(
          updated,
          imagePath: kIsWeb ? null : _selectedImagePath,
          imageBytes: _selectedImageBytes,
        );

    final repo = ref.read(stockItemRepositoryProvider);
    for (final assignment in _branchAssignments) {
      final branchId = assignment.branchId;
      if (branchId == null || branchId.isEmpty) continue;
      final minThreshold =
          int.tryParse(assignment.thresholdCtrl.text.trim()) ?? 0;
      await repo.assignToBranch(
        stockItemId: updated.id,
        branchId: branchId,
        minThreshold: minThreshold < 0 ? 0 : minThreshold,
      );
      ref
          .read(stockInventoryControllerProvider.notifier)
          .updateBranchAssignment(
            stockItemId: updated.id,
            branchId: branchId,
            minThreshold: minThreshold < 0 ? 0 : minThreshold,
          );
    }

    setState(() {
      _editableData =
          ref
              .read(stockInventoryControllerProvider.notifier)
              .findById(updated.id) ??
          updated;
      _isEditing = false;
      _selectedImageBytes = null;
      _selectedImagePath = null;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Stock item saved (mock)')));
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryControllerProvider);
    final userBranches =
        ref.watch(loginControllerProvider).user?.branches ??
        const <UserBranch>[];
    final categoryOptions = categoryState.categories;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editableData.name),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _isEditing ? _cancelEditing : _startEditing,
            child: Text(_isEditing ? 'Cancel' : 'Edit'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            StockItemImageSection(
              isEditing: _isEditing,
              imageBytes: _selectedImageBytes,
              imageUrl: _editableData.imageUrl,
              onPickImage: _pickImage,
              onClearImage: _selectedImageBytes != null
                  ? () => setState(() {
                      _selectedImageBytes = null;
                      _selectedImagePath = null;
                    })
                  : null,
            ),
            const SizedBox(height: 24),
            StockItemInfoSection(
              isEditing: _isEditing,
              nameController: _nameCtrl,
              categoryController: _categoryCtrl,
              categoryOptions: categoryOptions,
              selectedTypes: _selectedTypes,
              typeOptions: _typeOptions,
              pieceSizeController: _pieceSizeCtrl,
              barcodeController: _barcodeCtrl,
              isActive: _isActive,
              pieceDescription: _pieceDescription(),
              usageTags: _editableData.usageTags,
              categoryLabel: _categoryCtrl.text,
              barcodeLabel: _editableData.barcode ?? '—',
              onCategoryChanged: (categoryId, categoryName) {
                setState(() {
                  _categoryId = categoryId;
                  _categoryCtrl.text = categoryName;
                });
              },
              onToggleUsageTag: (tag, selected) {
                setState(() {
                  if (selected) {
                    _selectedTypes.add(tag);
                  } else {
                    _selectedTypes.remove(tag);
                  }
                });
              },
              onActiveChanged: (value) => setState(() => _isActive = value),
              onPieceSizeChanged: () => setState(() {}),
            ),
            const SizedBox(height: 16),
            StockItemBranchAssignmentSection(
              isEditing: _isEditing,
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
            ),
            const SizedBox(height: 16),
            if (_isEditing) StockItemSaveSection(onSave: _saveChanges),
          ],
        ),
      ),
    );
  }

  String _pieceDescription() {
    final parsed = int.tryParse(_pieceSizeCtrl.text) ?? _editableData.pieceSize;
    if (parsed <= 1) return 'Tracked in $_baseUnit';
    return '$parsed $_baseUnit per piece';
  }

  void _initBranchAssignments() {
    final branches =
        ref.read(loginControllerProvider).user?.branches ??
        const <UserBranch>[];
    if (_editableData.branchId.isNotEmpty && _editableData.branchId != 'all') {
      _branchAssignments.add(
        BranchAssignment(
          branchId: _editableData.branchId,
          minThreshold: _editableData.minThreshold,
        ),
      );
    } else if (branches.length == 1) {
      final b = branches.first;
      _branchAssignments.add(
        BranchAssignment(branchId: b.branchId.isNotEmpty ? b.branchId : b.id),
      );
    }
  }

  void _addBranchAssignment() {
    final branches =
        ref.read(loginControllerProvider).user?.branches ??
        const <UserBranch>[];
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
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _selectedImageBytes = bytes;
      _selectedImagePath = kIsWeb ? null : picked.path;
    });
  }
}
