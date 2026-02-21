import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/ui/components/menu_form_field_label.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

class EditCategorySheet extends ConsumerStatefulWidget {
  const EditCategorySheet({
    super.key,
    required this.category,
    this.startInEdit = false,
  });

  final MenuCategory category;
  final bool startInEdit;

  @override
  ConsumerState<EditCategorySheet> createState() => _EditCategorySheetState();
}

class _EditCategorySheetState extends ConsumerState<EditCategorySheet> {
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
    _isEditing = widget.startInEdit;
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

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _nameController.text = widget.category.name;
      _descriptionController.text = widget.category.description;
      _isActive = widget.category.isActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Category' : 'Category details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isEditing ? 1 : 0.65,
                child: AbsorbPointer(
                  absorbing: !_isEditing,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MenuFormFieldLabel(
                        text: 'Category Name',
                        isRequired: true,
                      ),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Coffee, Pastries',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const MenuFormFieldLabel(text: 'Description'),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          hintText: 'Enter category description',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
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
                            onChanged: (value) =>
                                setState(() => _isActive = value),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (_isEditing)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        onPressed: _cancelEdit,
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => setState(() => _isEditing = true),
                    child: const Text('Edit'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
