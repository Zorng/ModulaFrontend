import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/features/menu/ui/components/menu_form_field_label.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

/// A form for creating a new category.
class AddCategoryPage extends ConsumerStatefulWidget {
  const AddCategoryPage({super.key});

  @override
  ConsumerState<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends ConsumerState<AddCategoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Add New Category'),
      ),
      body: const AddCategoryDialogBody(
        contentPadding: EdgeInsets.all(24),
      ),
    );
  }
}

class AddCategoryDialogBody extends ConsumerStatefulWidget {
  const AddCategoryDialogBody({
    super.key,
    this.contentPadding = const EdgeInsets.fromLTRB(16, 16, 16, 24),
    this.showHeader = false,
    this.onClose,
    this.showActionBar = false,
  });

  final EdgeInsets contentPadding;
  final bool showHeader;
  final VoidCallback? onClose;
  final bool showActionBar;

  @override
  ConsumerState<AddCategoryDialogBody> createState() => _AddCategoryDialogBodyState();
}

class _AddCategoryDialogBodyState extends ConsumerState<AddCategoryDialogBody> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isActive = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(menuViewModelProvider.notifier).addCategory(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      isActive: _isActive,
    );
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: widget.contentPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showHeader)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add category',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose ?? () => context.pop(),
                  ),
                ],
              ),
            if (widget.showHeader) const SizedBox(height: 16),
            const MenuFormFieldLabel(text: 'Category Name', isRequired: true),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'e.g., Coffee, Pastries'),
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
                Text('Set Active', style: Theme.of(context).textTheme.titleMedium),
                CupertinoSwitch(
                  value: _isActive,
                  activeTrackColor: Theme.of(context).primaryColor,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (widget.showActionBar)
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      onPressed: widget.onClose ?? () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AddCategorySubmitButton(onPressed: _save),
                  ),
                ],
              )
            else
              AddCategorySubmitButton(onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class AddCategorySubmitButton extends StatelessWidget {
  const AddCategorySubmitButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
      child: const Text('Create Category'),
    );
  }
}
