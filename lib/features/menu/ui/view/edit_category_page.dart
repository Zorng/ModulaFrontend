import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modular_pos/features/menu/ui/view/categories_management_page.dart';

/// A page for viewing and editing a category.
class EditCategoryPage extends StatefulWidget {
  const EditCategoryPage({
    super.key,
    required this.category,
    required this.onSave,
  });

  final CategoryInfo category;
  final void Function(CategoryInfo updatedCategory) onSave;

  @override
  State<EditCategoryPage> createState() => _EditCategoryPageState();
}

class _EditCategoryPageState extends State<EditCategoryPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  // Mock data for dropdown
  final _branches = ['All Branches', 'Main Branch', 'Downtown'];
  String? _selectedBranch;

  late bool _isActive;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    // In a real app, you'd fetch the description. For now, it's empty.
    _descriptionController = TextEditingController();
    _isActive = widget.category.isActive;
    _selectedBranch = _branches.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Category' : widget.category.name),
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text('Edit'),
            ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: !_isEditing,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Category Name ---
              _buildLabel('Category Name', isRequired: true),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'e.g., Coffee, Pastries'),
              ),
              const SizedBox(height: 24),

              // --- Description ---
              _buildLabel('Description'),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(hintText: 'Enter category description'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // --- Assign to Branch Dropdown ---
              _buildLabel('Assign to Branch', isRequired: true),
              DropdownButtonFormField<String>(
                value: _selectedBranch,
                items: _branches.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedBranch = newValue;
                  });
                },
              ),
              const SizedBox(height: 24),

              // --- Set Active Switch ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Set Active', style: Theme.of(context).textTheme.titleMedium),
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
      ),
      // --- Bottom Save Button (only visible in edit mode) ---
      bottomNavigationBar: Visibility(
        visible: _isEditing,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              final updatedCategory = CategoryInfo(
                name: _nameController.text.trim(),
                itemCount: widget.category.itemCount, // Item count is not editable here
                isActive: _isActive,
              );
              widget.onSave(updatedCategory);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Save Changes'),
          ),
        ),
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