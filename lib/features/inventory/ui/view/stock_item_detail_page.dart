import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/data/stock_item_repository.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_section_card.dart';

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
  final _branchAssignments = <_BranchAssignmentDetail>[];

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

  void _startEditing() {
    setState(() => _isEditing = true);
  }

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
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
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
        .updateStockItem(updated);
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
      ref.read(stockInventoryControllerProvider.notifier).updateBranchAssignment(
            stockItemId: updated.id,
            branchId: branchId,
            minThreshold: minThreshold < 0 ? 0 : minThreshold,
          );
    }
    setState(() {
      _editableData = updated;
      _isEditing = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Stock item saved (mock)')));
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final categoryState = ref.watch(categoryControllerProvider);
    final userBranches = ref.watch(loginControllerProvider).user?.branches ?? const <UserBranch>[];
    final categoryOptions =
        categoryState.categories;
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
          children: [
            Center(
              child: _ImagePreview(
                imageUrl: _editableData.imageUrl,
                initials: _initialsFor(_editableData.name),
              ),
            ),
            const SizedBox(height: 24),
            InventorySectionCard(
              title: 'Item information',
              children: [
                _isEditing
                    ? TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name'),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Name is required'
                            : null,
                      )
                    : InventoryDetailField(
                        label: 'Name',
                        value: _editableData.name,
                      ),
                _isEditing
                    ? SizedBox(
                        width: double.infinity,
                        child: InventoryDropdown<String>(
                          initialValue: _categoryCtrl.text,
                          label: const Text('Category'),
                          entries: categoryOptions
                              .map(
                                (category) => DropdownMenuEntry(
                                  value: category.id,
                                  label: category.name,
                                ),
                              )
                              .toList(),
                          onSelected: (value) {
                            if (value == null) return;
                            final selected = categoryOptions.firstWhere(
                              (c) => c.id == value,
                              orElse: () => InventoryCategory(id: value, name: value, isActive: true),
                            );
                            setState(() {
                              _categoryId = selected.id;
                              _categoryCtrl.text = selected.name;
                            });
                          },
                        ),
                      )
                    : InventoryDetailField(
                        label: 'Category',
                        value: _categoryCtrl.text,
                      ),
                _isEditing
                    ? TextFormField(
                        controller: _pieceSizeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Piece size',
                          helperText: 'Number of base units per piece',
                        ),
                        onChanged: (_) => setState(() {}),
                      )
                    : InventoryDetailField(
                        label: 'Piece size',
                        value: _pieceDescription(),
                      ),
                _isEditing
                    ? TextFormField(
                        controller: _barcodeCtrl,
                        decoration: const InputDecoration(labelText: 'Barcode'),
                      )
                    : InventoryDetailField(
                        label: 'Barcode',
                        value: _editableData.barcode ?? '—',
                      ),
                _isEditing
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _typeOptions
                            .map(
                              (type) => CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(type),
                                value: _selectedTypes.contains(type),
                                onChanged: (value) {
                                  if (!_isEditing) return;
                                  setState(() {
                                    if (value ?? false) {
                                      _selectedTypes.add(type);
                                    } else {
                                      _selectedTypes.remove(type);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _editableData.usageTags
                            .map(
                              (tag) => Chip(
                                label: Text(tag),
                                backgroundColor: chipColor,
                              ),
                            )
                            .toList(),
                      ),
                _isEditing
                    ? SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Item is active'),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                      )
                    : InventoryDetailField(
                        label: 'Status',
                        value: _isActive ? 'Active' : 'Inactive',
                      ),
              ],
            ),
            const SizedBox(height: 16),
            InventorySectionCard(
              title: 'Branch assignment',
              children: [
                if (userBranches.isEmpty)
                  const Text('No branches available.')
                else if (_isEditing) ...[
                  ..._branchAssignments.map(
                    (assignment) => _BranchAssignmentCard(
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
                ] else ...[
                  if (_branchAssignments.isEmpty)
                    const Text('Not assigned to any branch.')
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _branchAssignments
                          .map(
                            (assignment) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _branchName(
                                        assignment.branchId,
                                        userBranches,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge,
                                    ),
                                  ),
                                  Text(
                                    'Min ${assignment.thresholdCtrl.text}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: FilledButton(
                  onPressed: _saveChanges,
                  child: const Text('Save changes'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _pieceDescription() {
    final parsed = int.tryParse(_pieceSizeCtrl.text) ?? _editableData.pieceSize;
    if (parsed <= 1) {
      return 'Tracked in $_baseUnit';
    }
    return '$parsed $_baseUnit per piece';
  }

  String _initialsFor(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  void _initBranchAssignments() {
    final branches =
        ref.read(loginControllerProvider).user?.branches ?? const <UserBranch>[];
    if (_editableData.branchId.isNotEmpty &&
        _editableData.branchId != 'all') {
      _branchAssignments.add(
        _BranchAssignmentDetail(
          branchId: _editableData.branchId,
          minThreshold: _editableData.minThreshold,
        ),
      );
    } else if (branches.length == 1) {
      final b = branches.first;
      _branchAssignments.add(
        _BranchAssignmentDetail(
          branchId: b.branchId.isNotEmpty ? b.branchId : b.id,
        ),
      );
    }
  }

  void _addBranchAssignment() {
    final branches =
        ref.read(loginControllerProvider).user?.branches ?? const <UserBranch>[];
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
    _branchAssignments.add(_BranchAssignmentDetail(branchId: next));
  }

  Set<String> _usedBranchIds(_BranchAssignmentDetail current) {
    return _branchAssignments
        .where((a) => a != current)
        .map((a) => a.branchId)
        .whereType<String>()
        .toSet();
  }

  String _branchName(String? id, List<UserBranch> branches) {
    if (id == null) return 'Unknown';
    final match = branches.firstWhere(
      (b) => (b.branchId.isNotEmpty ? b.branchId : b.id) == id,
      orElse: () => UserBranch(id: id, name: 'Branch $id', role: '', active: true),
    );
    return match.name;
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({this.imageUrl, required this.initials});

  final String? imageUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 220,
        height: 220,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _Placeholder(initials: initials, scheme: scheme),
              )
            : _Placeholder(initials: initials, scheme: scheme),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.initials, required this.scheme});

  final String initials;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.surface,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _BranchAssignmentDetail {
  _BranchAssignmentDetail({this.branchId, int minThreshold = 0})
      : thresholdCtrl = TextEditingController(text: minThreshold.toString());

  String? branchId;
  final TextEditingController thresholdCtrl;
}

class _BranchAssignmentCard extends StatelessWidget {
  const _BranchAssignmentCard({
    required this.assignment,
    required this.branches,
    required this.usedBranchIds,
    required this.onChanged,
    required this.onRemove,
  });

  final _BranchAssignmentDetail assignment;
  final List<UserBranch> branches;
  final Set<String> usedBranchIds;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final available = branches.where((b) {
      final id = b.branchId.isNotEmpty ? b.branchId : b.id;
      return !usedBranchIds.contains(id) || assignment.branchId == id;
    }).toList();
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InventoryDropdown<String>(
                    initialValue: assignment.branchId,
                    label: const Text('Branch'),
                    entries: available
                        .map(
                          (b) => DropdownMenuEntry(
                            value: b.branchId.isNotEmpty ? b.branchId : b.id,
                            label: b.name,
                          ),
                        )
                        .toList(),
                    onSelected: (value) {
                      assignment.branchId = value;
                      onChanged();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Remove',
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: assignment.thresholdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minimum threshold',
                helperText: 'Alert when stock falls below this amount',
              ),
              onChanged: (_) => onChanged(),
            ),
          ],
        ),
      ),
    );
  }
}
