import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/ui/components/menu_form_field_label.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

/// A page for viewing and editing a category.
class EditCategoryPage extends ConsumerStatefulWidget {
  const EditCategoryPage({super.key, required this.category});

  final MenuCategory category;

  @override
  ConsumerState<EditCategoryPage> createState() => _EditCategoryPageState();
}

class _EditCategoryPageState extends ConsumerState<EditCategoryPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late bool _isActive;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _descriptionController =
        TextEditingController(text: widget.category.description);
    _isActive = widget.category.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = widget.category.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      isActive: _isActive,
    );
    await ref.read(menuViewModelProvider.notifier).updateCategory(updated);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(_isEditing ? 'Edit Category' : widget.category.name),
        actions: [
          TextButton(
            onPressed: () => setState(() => _isEditing = !_isEditing),
            child: Text(_isEditing ? 'Cancel' : 'Edit'),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: !_isEditing,
        child: SingleChildScrollView(
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
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                  ),
                  onPressed: _isEditing
                      ? () async {
                          final navigator = Navigator.of(context);
                          await ref
                              .read(menuViewModelProvider.notifier)
                              .deleteCategory(widget.category.id);
                          if (!context.mounted) return;
                          navigator.pop();
                        }
                      : null,
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      color: _isEditing
                          ? Colors.red.shade700
                          : Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Visibility(
        visible: _isEditing,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Save Changes'),
          ),
        ),
      ),
    );
  }
}