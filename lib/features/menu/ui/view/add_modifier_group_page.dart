import 'package:flutter/material.dart';
import 'package:modular_pos/features/menu/ui/view/modifiers_management_page.dart';
import 'package:modular_pos/features/menu/ui/view/dashed_border_painter.dart';

/// A form for creating a new modifier group.
class AddModifierGroupPage extends StatefulWidget {
  const AddModifierGroupPage({super.key, required this.onAdd});

  /// Callback function to pass the new modifier group back to the previous page.
  final void Function(ModifierGroupInfo group) onAdd;
  
  @override
  State<AddModifierGroupPage> createState() => _AddModifierGroupPageState();
}

/// A simple data model to hold controllers for a single modifier option row.
class ModifierOptionRow {
  final String id;
  final TextEditingController nameController;
  final TextEditingController priceController;

  ModifierOptionRow()
      : id = UniqueKey().toString(),
        nameController = TextEditingController(),
        priceController = TextEditingController();
}
class _AddModifierGroupPageState extends State<AddModifierGroupPage> {
  final _groupNameController = TextEditingController();

  // Options for dropdowns
  final _pricingBehaviors = ['Add-on (Extra)', 'Fixed (Size Based)', 'No Price Change'];
  final _selectionTypes = ['Single Selection', 'Multiple Selection'];

  String? _selectedPricingBehavior;
  String? _selectedSelectionType;
  final List<ModifierOptionRow> _options = [];
  
  // Using a unique object/string to represent the "None" option for the radio group.
  static const String _noneDefaultValue = 'none';
  String _selectedDefault = _noneDefaultValue;

  @override
  void initState() {
    super.initState();
    _selectedPricingBehavior = _pricingBehaviors.first;
    _selectedSelectionType = _selectionTypes.first;
    // "None" is selected as the default initially.
    _selectedDefault = _noneDefaultValue;
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    for (final option in _options) {
      option.nameController.dispose();
      option.priceController.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _options.add(ModifierOptionRow());
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Modifier Group'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Group Name ---
            _buildLabel('Group Name', isRequired: true),
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(hintText: 'e.g., Size, Toppings'),
            ),
            const SizedBox(height: 24),

            // --- Pricing Behavior Dropdown ---
            _buildLabel('Pricing Behavior'),
            DropdownButtonFormField<String>(
              value: _selectedPricingBehavior,
              items: _pricingBehaviors.map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPricingBehavior = newValue;
                });
              },
            ),
            const SizedBox(height: 24),

            // --- Selection Type Dropdown ---
            _buildLabel('Selection Type'),
            DropdownButtonFormField<String>(
              value: _selectedSelectionType,
              items: _selectionTypes.map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSelectionType = newValue;
                });
              },
            ),
            const SizedBox(height: 32),

            // --- Options Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Options', style: Theme.of(context).textTheme.titleSmall),
                Text('Select as default', style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const Divider(height: 16),

            // --- "None" Option ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('None'),
                Radio<String>(
                  value: _noneDefaultValue,
                  groupValue: _selectedDefault,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedDefault = value!;
                    });
                  },
                ),
              ],
            ),

            // --- Dynamic Option Rows ---
            ..._options.map((option) => _buildOptionRow(option)),

            const SizedBox(height: 16),

            // --- Add Another Option Button ---
            InkWell(
              onTap: _addOption,
              child: CustomPaint(
                foregroundPainter: DashedBorderPainter(
                  color: Theme.of(context).primaryColor,
                ),
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      '+ Add another option',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // --- Bottom Create Button ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            final groupName = _groupNameController.text.trim();
            if (groupName.isNotEmpty) {
              // Create the new group info object.
              final newGroup = ModifierGroupInfo(
                name: groupName,
                options: _options.map((row) {
                  return ModifierOption(
                    name: row.nameController.text.trim(),
                    price: double.tryParse(row.priceController.text) ?? 0.0,
                  );
                }).toList(),
              );
              widget.onAdd(newGroup); // Pass the data back.
              Navigator.pop(context); // Close the page.
            }
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Create'),
        ),
      ),
    );
  }

  /// Builds a single row for a modifier option.
  Widget _buildOptionRow(ModifierOptionRow option) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: TextField(
              controller: option.nameController,
              decoration: const InputDecoration(hintText: 'Option Label'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: TextField(
              controller: option.priceController,
              decoration: const InputDecoration(hintText: '+ \$0.00'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(width: 8),
          Radio<String>(
            value: option.id,
            groupValue: _selectedDefault,
            onChanged: (String? value) {
              if (value != null) {
                setState(() {
                  _selectedDefault = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }
  /// Helper to build form field labels with an optional required star.
  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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