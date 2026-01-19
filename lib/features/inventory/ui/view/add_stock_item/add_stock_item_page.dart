import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/components/branch_assignment.dart';
import 'package:modular_pos/features/inventory/ui/components/branch_assignment_card.dart';
import 'package:modular_pos/features/inventory/ui/view/add_stock_item/widgets/upload_image_tile.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_section_card.dart';

class AddStockItemPage extends ConsumerStatefulWidget {
  const AddStockItemPage({super.key});

  @override
  ConsumerState<AddStockItemPage> createState() => _AddStockItemPageState();
}

class _AddStockItemPageState extends ConsumerState<AddStockItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _pieceSizeCtrl = TextEditingController(text: '1');
  final _baseUnits = const ['ml', 'g', 'pcs'];
  final _baseUnitFieldKey = GlobalKey<FormFieldState<String>>();
  final _categoryFieldKey = GlobalKey<FormFieldState<String>>();
  final _typeOptions = const ['Ingredient', 'Sellable'];
  final _branchAssignments = <BranchAssignment>[];
  String? _category;
  String? _categoryId;
  String? _baseUnit;
  final _selectedTypes = <String>{};
  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryControllerProvider.notifier).loadCategories();
      _bootstrapBranchAssignments();
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
    final userBranches =
        ref.watch(loginControllerProvider).user?.branches ??
        const <UserBranch>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Add stock item'), centerTitle: false),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: UploadImageTile(
                imageBytes: _selectedImageBytes,
                onPressed: _pickImage,
                onClearLocalSelection: () => setState(() {
                  _selectedImageBytes = null;
                  _selectedImagePath = null;
                }),
              ),
            ),
            const SizedBox(height: 24),
            InventorySectionCard(
              title: 'Item details',
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Item name',
                    hintText: 'e.g., Milk 1000ml',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                FormField<String>(
                  key: _baseUnitFieldKey,
                  validator: (_) =>
                      _baseUnit == null ? 'Please select a base unit' : null,
                  builder: (state) {
                    final textTheme = Theme.of(context).textTheme;
                    final hintColor = Theme.of(context).hintColor;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showBaseUnitSelector,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Base unit',
                          helperText:
                              'ml for liquids, g for solids, pcs for countable items',
                          errorText: state.errorText,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _baseUnit ?? 'Select base unit',
                                style: _baseUnit == null
                                    ? textTheme.bodyMedium?.copyWith(
                                        color: hintColor,
                                      )
                                    : textTheme.bodyMedium,
                              ),
                            ),
                            const Icon(Icons.expand_more),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                TextFormField(
                  controller: _pieceSizeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Piece size',
                    helperText: 'How many base units equal 1 piece',
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a piece size greater than 0';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _barcodeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Barcode (optional)',
                  ),
                ),
                FormField<String>(
                  key: _categoryFieldKey,
                  validator: (_) => null,
                  builder: (state) {
                    final textTheme = Theme.of(context).textTheme;
                    final hintColor = Theme.of(context).hintColor;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showCategorySelector,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _category ?? 'Select category',
                              style: _category == null
                                  ? textTheme.bodyMedium?.copyWith(
                                      color: hintColor,
                                    )
                                  : textTheme.bodyMedium,
                            ),
                            const Icon(Icons.expand_more),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            InventorySectionCard(
              title: 'Item usage',
              children: [
                ..._typeOptions.map(
                  (type) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(type),
                    value: _selectedTypes.contains(type),
                    onChanged: (value) {
                      setState(() {
                        if (value ?? false) {
                          _selectedTypes.add(type);
                        } else {
                          _selectedTypes.remove(type);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InventorySectionCard(
              title: 'Branch assignment',
              children: [
                if (userBranches.isEmpty)
                  const Text(
                    'No branches available. Add branches to assign this item.',
                  )
                else ...[
                  ..._branchAssignments.map(
                    (assignment) => BranchAssignmentCard(
                      assignment: assignment,
                      branches: userBranches,
                      usedBranchIds: _usedBranchIds(assignment),
                      onChanged: () => setState(() {}),
                      onRemove: () {
                        setState(() {
                          assignment.thresholdCtrl.dispose();
                          _branchAssignments.remove(assignment);
                        });
                      },
                    ),
                  ),
                  if (_branchAssignments.length < userBranches.length)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(_addBranchAssignment),
                        icon: const Icon(Icons.add),
                        label: const Text('Assign to branch'),
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _submit, child: const Text('Save item')),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final branches =
        ref.read(loginControllerProvider).user?.branches ??
        const <UserBranch>[];
    if (branches.isNotEmpty && _branchAssignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assign this item to at least one branch.'),
        ),
      );
      return;
    }
    for (final assignment in _branchAssignments) {
      if (assignment.branchId == null || assignment.branchId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a branch for each assignment.')),
        );
        return;
      }
    }

    final controller = ref.read(stockInventoryControllerProvider.notifier);
    final pieceSize = int.tryParse(_pieceSizeCtrl.text.trim()) ?? 1;
    final usageTags = _selectedTypes.isEmpty
        ? <String>['Ingredient']
        : _selectedTypes.toList();

    final item = StockItem(
      id: '',
      name: _nameCtrl.text.trim(),
      category: _category ?? 'Uncategorized',
      categoryId: _categoryId,
      baseUnit: _baseUnit ?? 'pcs',
      pieceSize: pieceSize <= 0 ? 1 : pieceSize,
      branchId: '',
      branchName: '',
      onHand: 0,
      minThreshold: 0,
      isActive: true,
      barcode: _barcodeCtrl.text.trim().isEmpty
          ? null
          : _barcodeCtrl.text.trim(),
      lastRestockDate: '-',
      expiryDate: '-',
      usageTags: usageTags,
    );

    final created = await controller.addStockItem(
      item,
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
        stockItemId: created.id,
        branchId: branchId,
        minThreshold: minThreshold < 0 ? 0 : minThreshold,
      );
      ref
          .read(stockInventoryControllerProvider.notifier)
          .updateBranchAssignment(
            stockItemId: created.id,
            branchId: branchId,
            minThreshold: minThreshold < 0 ? 0 : minThreshold,
          );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Stock item added')));
    Navigator.of(context).pop();
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

  Future<void> _showBaseUnitSelector() async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _baseUnits.length,
          itemBuilder: (context, index) {
            final unit = _baseUnits[index];
            final selected = unit == _baseUnit;
            return ListTile(
              title: Text(unit),
              trailing: selected ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(unit),
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
        ),
      ),
    );

    if (selection != null) {
      setState(() {
        _baseUnit = selection;
        _baseUnitFieldKey.currentState?.didChange(selection);
      });
    }
  }

  Future<void> _showCategorySelector() async {
    final categoryState = ref.read(categoryControllerProvider);
    final categories = categoryState.categories;
    if (categories.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No categories available. Please create one first.'),
        ),
      );
      return;
    }
    final selection = await showModalBottomSheet<InventoryCategory>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final selected = category.id == _categoryId;
            return ListTile(
              title: Text(category.name),
              trailing: selected ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(category),
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
        ),
      ),
    );

    if (selection != null) {
      setState(() {
        _category = selection.name;
        _categoryId = selection.id;
        _categoryFieldKey.currentState?.didChange(selection.id);
      });
    }
  }

  void _bootstrapBranchAssignments() {
    final branches =
        ref.read(loginControllerProvider).user?.branches ??
        const <UserBranch>[];
    if (branches.length == 1) {
      _branchAssignments.add(
        BranchAssignment(
          branchId: branches.first.branchId.isNotEmpty
              ? branches.first.branchId
              : branches.first.id,
        ),
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
    String? nextBranchId;
    for (final b in branches) {
      final id = b.branchId.isNotEmpty ? b.branchId : b.id;
      if (!used.contains(id)) {
        nextBranchId = id;
        break;
      }
    }
    _branchAssignments.add(BranchAssignment(branchId: nextBranchId));
  }

  Set<String> _usedBranchIds(BranchAssignment current) {
    return _branchAssignments
        .where((a) => a != current)
        .map((a) => a.branchId)
        .whereType<String>()
        .toSet();
  }
}
