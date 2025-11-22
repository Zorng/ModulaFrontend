import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/domain/models/category_defaults.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_section_card.dart';

/// Simple placeholder form for adding a stock item.
///
/// Actual submission logic will be wired once the inventory module
/// connects to the backend. For now we validate basic fields and show
/// a scaffold message to communicate the action.
class AddStockItemPage extends ConsumerStatefulWidget {
  const AddStockItemPage({super.key});

  @override
  ConsumerState<AddStockItemPage> createState() => _AddStockItemPageState();
}

class _AddStockItemPageState extends ConsumerState<AddStockItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '0');
  final _minThresholdCtrl = TextEditingController(text: '0');
  final _pieceSizeCtrl = TextEditingController(text: '1');
  final _lastRestockCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _baseUnits = const ['ml', 'g', 'pcs'];
  final _baseUnitFieldKey = GlobalKey<FormFieldState<String>>();
  final _categoryFieldKey = GlobalKey<FormFieldState<String>>();
  final _branchFieldKey = GlobalKey<FormFieldState<String>>();
  final _typeOptions = const ['Ingredient', 'Sellable'];
  String? _category;
  String? _baseUnit;
  String? _branchId;
  String? _branchName;
  final _selectedTypes = <String>{};

  final _branches = const [
    {'id': 'main', 'name': 'Main Branch'},
    {'id': 'downtown', 'name': 'Downtown'},
    {'id': 'airport', 'name': 'Airport'},
  ];

  @override
  void initState() {
    super.initState();
    _branchId = _branches.first['id'];
    _branchName = _branches.first['name'];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _quantityCtrl.dispose();
    _minThresholdCtrl.dispose();
    _pieceSizeCtrl.dispose();
    _lastRestockCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add stock item'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: _UploadImageTile(
                onPressed: () => _showComingSoonDialog(context),
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
                          helperText: 'ml for liquids, g for solids, pcs for countable items',
                          errorText: state.errorText,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _baseUnit ?? 'Select base unit',
                                style: _baseUnit == null
                                    ? textTheme.bodyMedium
                                        ?.copyWith(color: hintColor)
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
                                  ? textTheme.bodyMedium
                                      ?.copyWith(color: hintColor)
                                  : textTheme.bodyMedium,
                            ),
                            const Icon(Icons.expand_more),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                FormField<String>(
                  key: _branchFieldKey,
                  validator: (_) => null,
                  builder: (state) {
                    final textTheme = Theme.of(context).textTheme;
                    final hintColor = Theme.of(context).hintColor;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showBranchSelector,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Branch',
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _branchName ?? 'Select branch',
                              style: _branchName == null
                                  ? textTheme.bodyMedium
                                      ?.copyWith(color: hintColor)
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
              title: 'Stock status',
              children: [
                TextFormField(
                  controller: _quantityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Starting quantity'),
                ),
                TextFormField(
                  controller: _minThresholdCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Min threshold'),
                ),
                TextFormField(
                  controller: _lastRestockCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Last restock date (optional)',
                    hintText: 'Select date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      onPressed: () => _pickDate(_lastRestockCtrl),
                    ),
                  ),
                  onTap: () => _pickDate(_lastRestockCtrl),
                ),
                TextFormField(
                  controller: _expiryCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Expiry date (optional)',
                    hintText: 'Select date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      onPressed: () => _pickDate(_expiryCtrl),
                    ),
                  ),
                  onTap: () => _pickDate(_expiryCtrl),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: const Text('Save item'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    final controller = ref.read(stockInventoryControllerProvider.notifier);
    final quantity = int.tryParse(_quantityCtrl.text.trim()) ?? 0;
    final minThreshold = int.tryParse(_minThresholdCtrl.text.trim()) ?? 0;
    final pieceSize = int.tryParse(_pieceSizeCtrl.text.trim()) ?? 1;
    final usageTags =
        _selectedTypes.isEmpty ? <String>['Ingredient'] : _selectedTypes.toList();
    final branch = _branchId == null
        ? _branches.first
        : _branches.firstWhere((b) => b['id'] == _branchId, orElse: () => _branches.first);
    final item = StockItem(
      id: '',
      name: _nameCtrl.text.trim(),
      category: _category ?? 'Uncategorized',
      baseUnit: _baseUnit ?? 'pcs',
      pieceSize: pieceSize <= 0 ? 1 : pieceSize,
      branchId: branch['id']!,
      branchName: branch['name']!,
      onHand: quantity,
      minThreshold: minThreshold,
      isActive: true,
      barcode: _barcodeCtrl.text.trim().isEmpty
          ? null
          : _barcodeCtrl.text.trim(),
      lastRestockDate: _lastRestockCtrl.text.trim().isEmpty
          ? '-'
          : _lastRestockCtrl.text.trim(),
      expiryDate: _expiryCtrl.text.trim().isEmpty
          ? '-'
          : _expiryCtrl.text.trim(),
      usageTags: usageTags,
    );

    controller.addStockItem(item).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock item added')),
      );
      Navigator.of(context).pop();
    });
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming soon'),
        content: const Text(
          'Media upload will be available once the inventory module is connected to the backend.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
    final categories = categoryState.categories.isEmpty
        ? defaultInventoryCategories
        : (categoryState.categories.map((c) => c.name).toList()..sort());
    final selection = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final selected = category == _category;
            return ListTile(
              title: Text(category),
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
        _category = selection;
        _categoryFieldKey.currentState?.didChange(selection);
      });
    }
  }

  Future<void> _showBranchSelector() async {
    final selection = await showModalBottomSheet<Map<String, String>>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _branches.length,
          itemBuilder: (context, index) {
            final branch = _branches[index];
            final selected = branch['id'] == _branchId;
            return ListTile(
              title: Text(branch['name']!),
              trailing: selected ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(branch),
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
        ),
      ),
    );

    if (selection != null) {
      setState(() {
        _branchId = selection['id'];
        _branchName = selection['name'];
        _branchFieldKey.currentState?.didChange(_branchName);
      });
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final initialDate = _parseDate(controller.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        controller.text = _formatDate(picked);
      });
    }
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty || value == '-') return null;
    final parts = value.split(' ');
    if (parts.length != 3) return null;
    final month =
        _monthNames.indexWhere((name) => name.toLowerCase() == parts[0].toLowerCase()) + 1;
    if (month <= 0) return null;
    final day = int.tryParse(parts[1].replaceAll(',', ''));
    final year = int.tryParse(parts[2]);
    if (day == null || year == null) return null;
    return DateTime(year, month, day);
  }

  String _formatDate(DateTime date) {
    final month = _monthNames[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    return '$month $day, ${date.year}';
  }
}

class _UploadImageTile extends StatelessWidget {
  const _UploadImageTile({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onPressed,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: scheme.outline,
        ),
        child: SizedBox(
          width: 220,
          height: 220,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_outlined, size: 40, color: scheme.primary),
                const SizedBox(height: 12),
                Text(
                  'Add item image',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'PNG or JPG, up to 2MB',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const List<String> _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;
  static const double strokeWidth = 1.5;
  static const double radius = 16;
  static const double dashLength = 8;
  static const double gapLength = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect =
        RRect.fromRectAndRadius(rect, Radius.circular(_DashedBorderPainter.radius));

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _DashedBorderPainter.strokeWidth;

    final dashedPath = _createDashedPath(
      Path()..addRRect(rrect),
      _DashedBorderPainter.dashLength,
      _DashedBorderPainter.gapLength,
    );

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

Path _createDashedPath(Path source, double dashLength, double gapLength) {
  final dashedPath = Path();
  for (final metric in source.computeMetrics()) {
    double distance = 0;
    while (distance < metric.length) {
      final double end = math.min(distance + dashLength, metric.length);
      dashedPath.addPath(metric.extractPath(distance, end), Offset.zero);
      distance += dashLength + gapLength;
    }
  }
  return dashedPath;
}
