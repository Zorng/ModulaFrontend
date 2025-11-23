import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modular_pos/features/menu/ui/view/categories_management_page.dart';

/// A form for creating a new category.
class AddCategoryPage extends StatefulWidget {
  const AddCategoryPage({super.key, required this.onAdd});

  /// Callback function to pass the new category back to the previous page.
  final void Function(CategoryInfo category) onAdd;
  
  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Mock data for dropdown
  final _branches = ['All Branches', 'Main Branch', 'Downtown'];
  String? _selectedBranch;

  bool _isActive = true;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _selectedBranch = _branches.first;
    _nameController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isValid = _nameController.text.isNotEmpty;
    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Category'),
      ),
      body: SingleChildScrollView(
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
      // --- Bottom Create Button ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isFormValid
              ? () {
                  final newCategory = CategoryInfo(
                      name: _nameController.text.trim(), itemCount: 0, isActive: _isActive);
                  widget.onAdd(newCategory);
                  Navigator.pop(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Create Category'),
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