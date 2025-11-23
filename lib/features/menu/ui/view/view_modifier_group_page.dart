import 'package:flutter/material.dart';
import 'package:modular_pos/features/menu/ui/view/edit_modifier_group_page.dart';
import 'package:modular_pos/features/menu/ui/view/modifiers_management_page.dart';

/// A page to view the details of a modifier group.
class ViewModifierGroupPage extends StatefulWidget {
  const ViewModifierGroupPage({
    super.key,
    required this.initialGroup,
    required this.onGroupUpdated,
  });

  final ModifierGroupInfo initialGroup;
  final ValueSetter<ModifierGroupInfo> onGroupUpdated;

  @override
  State<ViewModifierGroupPage> createState() => _ViewModifierGroupPageState();
}

class _ViewModifierGroupPageState extends State<ViewModifierGroupPage> {
  late ModifierGroupInfo _currentGroup; // The current state of the group info
  late final TextEditingController _groupNameController;

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
    _currentGroup = widget.initialGroup;
    _groupNameController = TextEditingController(text: _currentGroup.name);

    // Pre-fill the form with existing data
    _selectedPricingBehavior = _pricingBehaviors.first; // Placeholder
    _selectedSelectionType = _selectionTypes.first;   // Placeholder
    _selectedDefault = _noneDefaultValue;

    // Load the actual options from the group data.
    for (final option in _currentGroup.options) {
      _options.add(ModifierOptionRow(name: option.name, price: option.price));
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View: ${_currentGroup.name}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditModifierGroupPage(
                    groupToEdit: _currentGroup,
                    onSave: (updatedGroup) {
                      setState(() {
                        _currentGroup = updatedGroup;
                        _groupNameController.text = updatedGroup.name;
                      });
                      widget.onGroupUpdated(updatedGroup);
                    },
                  ),
                ),
              );
            },
            child: const Text('Edit'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: AbsorbPointer( // This widget makes the entire form read-only
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Group Name ---
                _buildLabel('Group Name'),
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
                  onChanged: null, // Disabled
                ),
                const SizedBox(height: 24),

                // --- Selection Type Dropdown ---
                _buildLabel('Selection Type'),
                DropdownButtonFormField<String>(
                  value: _selectedSelectionType,
                  items: _selectionTypes.map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: null, // Disabled
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
                      onChanged: null, // Disabled
                    ),
                  ],
                ),

                // --- Dynamic Option Rows ---
                ..._options.map((option) => _buildOptionRow(option)),
              ],
            ),
          ),
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
          Expanded(flex: 4, child: TextField(controller: option.nameController, decoration: const InputDecoration(hintText: 'Option Label'))),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: TextField(controller: option.priceController, decoration: const InputDecoration(hintText: '+ \$0.00'), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
          const SizedBox(width: 8),
          Radio<String>(
            value: option.id,
            groupValue: _selectedDefault,
            onChanged: null, // Disabled
          ),
        ],
      ),
    );
  }

  /// Helper to build form field labels.
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}