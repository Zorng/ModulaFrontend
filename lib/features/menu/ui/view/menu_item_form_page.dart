import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/ui/view/modifiers_management_page.dart';
import 'package:modular_pos/features/menu/ui/view/dashed_border_painter.dart';

/// A form for creating or editing a menu item.
class MenuItemFormPage extends StatefulWidget {
  const MenuItemFormPage({
    super.key,
    this.itemId,
    this.initialItem,
    this.onAdd,
    this.onSave,
    this.categories = const [],
    this.modifierGroups = const [],
  });

  /// If provided, the form will be in 'edit' mode for this item.
  final String? itemId;
  final MenuItem? initialItem;
  final void Function(MenuItem newItem)? onAdd;
  final void Function(MenuItem updatedItem)? onSave;
  final List<String> categories;
  final List<ModifierGroupInfo> modifierGroups;

  @override
  State<MenuItemFormPage> createState() => _MenuItemFormPageState();
}

class _MenuItemFormPageState extends State<MenuItemFormPage> {
  bool get isEditing => widget.itemId != null;

  // Controllers to manage text field state and listen for changes.
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;

  bool _isActive = true;
  bool _isFormValid = false;

  // Mock data for dropdowns
  // final _categories = ['Coffee', 'Tea', 'Pastries', 'Juice']; // Now passed in
  final _branches = ['All Branches', 'Main Branch', 'Downtown'];
  String? _selectedCategory;  
  final Set<String> _selectedBranches = {};

  // To track which modifiers are selected for this item
  final Set<ModifierGroupInfo> _selectedModifiers = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialItem?.name);
    _priceController = TextEditingController(text: widget.initialItem?.price.toStringAsFixed(2));

    if (isEditing && widget.initialItem != null) {
      // Pre-fill form for editing
      _selectedCategory = widget.initialItem!.category;
      _selectedBranches.add('All Branches'); // Placeholder
      _selectedModifiers.addAll(widget.initialItem!.modifierGroups);
      _isActive = true; // Placeholder
    } else {
      // Default values for creating a new item
      final availableCategories = widget.categories.where((c) => c != 'All').toList();
      if (availableCategories.isNotEmpty) {
        _selectedCategory = availableCategories.first;
      }
    }
    
    // Add listeners to validate the form whenever the text changes.
    _nameController.addListener(_validateForm);
    _priceController.addListener(_validateForm);
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed.
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isValid = _nameController.text.isNotEmpty &&
        _priceController.text.isNotEmpty &&
        _selectedBranches.isNotEmpty;
    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _createItem() {
    if (_isFormValid) {
      final newItem = MenuItem(
        id: DateTime.now().toIso8601String(), // Unique ID
        name: _nameController.text.trim(),
        category: _selectedCategory!,
        price: double.tryParse(_priceController.text) ?? 0.0,
        imagePath: null, // No image upload for now
        modifierGroups: _selectedModifiers.toList(),
      );
      widget.onAdd?.call(newItem);
      Navigator.pop(context);
    }
  }

  void _saveChanges() {
    if (_isFormValid) {
      final updatedItem = MenuItem(
        id: widget.itemId!,
        name: _nameController.text.trim(),
        category: _selectedCategory!,
        price: double.tryParse(_priceController.text) ?? 0.0,
        imagePath: widget.initialItem?.imagePath, // Preserve original image for now
        modifierGroups: _selectedModifiers.toList(),
      );
      widget.onSave?.call(updatedItem);
      Navigator.pop(context); // Pop back to the view page
    }
  }

  void _showAddModifierSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true, // Allows the sheet to have a custom height.
      builder: (context) {
        // Use a StatefulWidget for the sheet's content to manage its own state.
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.8, // 80% of screen height
              width: double.infinity,
              child: Column(
                children: [
                  // --- Header ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Add Modifier Groups', style: Theme.of(context).textTheme.titleLarge),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // --- Body ---
                  Expanded(
                    child: widget.modifierGroups.isEmpty
                        ? Center(
                            child: Text('No Modifier Groups available', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                          )
                        : ListView.builder(
                            itemCount: widget.modifierGroups.length,
                            itemBuilder: (context, index) {
                              final group = widget.modifierGroups[index];
                              final isSelected = _selectedModifiers.contains(group);
                              return CheckboxListTile(
                                title: Text(group.name),
                                subtitle: Text('${group.options.length} options'),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setSheetState(() {
                                    if (value == true) {
                                      _selectedModifiers.add(group);
                                    } else {
                                      _selectedModifiers.remove(group);
                                    }
                                  });
                                  // Also update the main page state to reflect changes immediately
                                  setState(() {});
                                },
                              );
                            },
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

  void _showBranchSelectionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Assign to Branches', style: Theme.of(context).textTheme.titleLarge),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _branches.length,
                    itemBuilder: (context, index) {
                      final branch = _branches[index];
                      final isSelected = _selectedBranches.contains(branch);
                      return CheckboxListTile(
                        title: Text(branch),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setSheetState(() {
                            if (value == true) {
                              if (branch == 'All Branches') {
                                _selectedBranches.clear();
                                _selectedBranches.add(branch);
                              } else {
                                _selectedBranches.remove('All Branches');
                                _selectedBranches.add(branch);
                              }
                            } else {
                              _selectedBranches.remove(branch);
                            }
                          });
                          // Update the main form page UI
                          setState(() {});
                          _validateForm();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
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

  void _removeModifier(ModifierGroupInfo modifier) {
    setState(() {
      _selectedModifiers.remove(modifier);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Item' : 'Create New Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image Upload Area ---
            Center(
              child: Container(
                width: 159.69,
                height: 149,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Item Name ---
            _buildLabel('Item Name', isRequired: true),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Enter item name'),
            ),
            const SizedBox(height: 16),

            // --- Description ---
            _buildLabel('Description'),
            const TextField(
              decoration: InputDecoration(hintText: 'Enter item description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // --- Base Price ---
            _buildLabel('Base price', isRequired: true),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(hintText: '0.00'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            // --- Category Dropdown ---
            _buildLabel('Category', isRequired: true),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: widget.categories.where((c) => c != 'All').map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
            ),
            const SizedBox(height: 16),

            // --- Assign to Branch Dropdown ---
            _buildLabel('Assign to Branch', isRequired: true),
            InkWell(
              onTap: _showBranchSelectionSheet,
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                ),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _selectedBranches.isEmpty
                      ? [const Text('Select branches...', style: TextStyle(color: Colors.grey))]
                      : _selectedBranches.map((branch) {
                          return Chip(
                            label: Text(branch),
                            onDeleted: () {
                              setState(() {
                                _selectedBranches.remove(branch);
                                _validateForm();
                              });
                            },
                          );
                        }).toList(),
                ),
              ),
            ),            const SizedBox(height: 24),

            // --- Modifier Group ---
            Text('Modifier Group', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            // Display selected modifiers
            ..._selectedModifiers.map((group) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(group.name, style: textTheme.titleMedium),
                              const Divider(),
                              ...group.options.map((option) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(option.name, style: textTheme.bodyLarge),
                                      if (option.price > 0)
                                        Text(
                                          '+\$${option.price.toStringAsFixed(2)}',
                                          style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _removeModifier(group),
                      ),
                    ],
                  ),
                )),
            InkWell(onTap: _showAddModifierSheet, child: CustomPaint(
                foregroundPainter: DashedBorderPainter(
                  color: Theme.of(context).primaryColor, // Primary color for border
                ),
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer, // Light orange for background
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      '+ Add another option',
                      style: TextStyle(color: Colors.black), // Black text
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Set Active Switch ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Set Active', style: textTheme.titleMedium),
                CupertinoSwitch(
                  value: _isActive,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (bool value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      // --- Bottom Create Button ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isFormValid ? (isEditing ? _saveChanges : _createItem) : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Text(isEditing ? 'Save Changes' : 'Create Item'),
        ),
      ),
    );
  }
}