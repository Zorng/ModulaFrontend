import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:modular_pos/features/menu/ui/components/menu_form_field_label.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

/// A form for creating a new category.
class AddCategoryPage extends ConsumerStatefulWidget {
  const AddCategoryPage({super.key});

  @override
  ConsumerState<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends ConsumerState<AddCategoryPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _save() async {
    await ref.read(menuViewModelProvider.notifier).addCategory(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          isActive: _isActive,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Add New Category'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MenuFormFieldLabel(text: 'Category Name', isRequired: true),
            TextField(
              controller: _nameController,
              decoration:
                  const InputDecoration(hintText: 'e.g., Coffee, Pastries'),
            ),
            const SizedBox(height: 24),
            const MenuFormFieldLabel(text: 'Description'),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Enter category description',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Set Active',
                    style: Theme.of(context).textTheme.titleMedium),
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
