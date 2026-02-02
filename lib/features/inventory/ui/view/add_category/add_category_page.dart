import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/features/menu/ui/components/menu_form_field_label.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_controller.dart';

class AddInventoryCategoryPage extends ConsumerStatefulWidget {
  const AddInventoryCategoryPage({super.key});

  @override
  ConsumerState<AddInventoryCategoryPage> createState() =>
      _AddInventoryCategoryPageState();
}

class _AddInventoryCategoryPageState
    extends ConsumerState<AddInventoryCategoryPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isActive = true;
  String? _nameError;

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Required');
      return;
    }
    if (name.length < 2) {
      setState(() => _nameError = 'Must be at least 2 characters');
      return;
    }
    if (name.length > 40) {
      setState(() => _nameError = 'Must be at most 40 characters');
      return;
    }

    await ref
        .read(categoryControllerProvider.notifier)
        .addCategory(
          name,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          isActive: _isActive,
        );
    if (!mounted) return;
    context.pop();
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
      appBar: AppBar(title: const Text('Add category'), centerTitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MenuFormFieldLabel(text: 'Category Name', isRequired: true),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g., Coffee, Pastries',
                errorText: _nameError,
                counterText: '',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            const MenuFormFieldLabel(text: 'Description'),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Enter category description',
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Set Active',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                CupertinoSwitch(
                  value: _isActive,
                  activeTrackColor: Theme.of(context).primaryColor,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Create Category'),
        ),
      ),
    );
  }
}
