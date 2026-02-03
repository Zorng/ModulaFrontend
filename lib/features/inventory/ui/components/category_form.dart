import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_controller.dart';
import 'package:modular_pos/features/menu/ui/components/menu_form_field_label.dart';

enum CategoryFormMode { create, view, edit }

class CategoryFormBody extends ConsumerStatefulWidget {
  const CategoryFormBody({
    super.key,
    required this.mode,
    this.category,
    this.showHeader = true,
    this.onClose,
  }) : assert(
         mode == CategoryFormMode.create || category != null,
         'category is required for view/edit',
       );

  final CategoryFormMode mode;
  final InventoryCategory? category;
  final bool showHeader;
  final VoidCallback? onClose;

  @override
  ConsumerState<CategoryFormBody> createState() => _CategoryFormBodyState();
}

class _CategoryFormBodyState extends ConsumerState<CategoryFormBody> {
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  CategoryFormMode _mode = CategoryFormMode.create;
  bool _isActive = true;
  String? _nameError;
  String? _descriptionError;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    final category = widget.category;
    if (category != null) {
      _nameCtrl.text = category.name;
      _descriptionCtrl.text = category.description ?? '';
      _isActive = category.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isView = _mode == CategoryFormMode.view;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader)
            Row(
              children: [
                Expanded(
                  child: Text(
                    _title(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                ),
              ],
            ),
          if (widget.showHeader) const SizedBox(height: 16),
          const MenuFormFieldLabel(text: 'Category Name', isRequired: true),
          TextField(
            controller: _nameCtrl,
            enabled: !isView,
            decoration: InputDecoration(
              hintText: 'e.g., Coffee, Pastries',
              errorText: _nameError,
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),
          const MenuFormFieldLabel(text: 'Description'),
          TextField(
            controller: _descriptionCtrl,
            enabled: !isView,
            decoration: InputDecoration(
              hintText: 'Enter category description',
              errorText: _descriptionError,
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
                onChanged: isView
                    ? null
                    : (value) => setState(() {
                        _isActive = value;
                      }),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (_mode == CategoryFormMode.view) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => setState(() => _mode = CategoryFormMode.edit),
          child: const Text('Edit'),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _submit,
            child: Text(
              _mode == CategoryFormMode.create ? 'Create Category' : 'Save',
            ),
          ),
        ),
      ],
    );
  }

  String _title() => switch (_mode) {
    CategoryFormMode.create => 'Add category',
    CategoryFormMode.view => 'Category details',
    CategoryFormMode.edit => 'Edit category',
  };

  bool _validate() {
    final name = _nameCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    String? nameError;
    String? descError;

    if (name.isEmpty) {
      nameError = 'Required';
    } else if (name.length < 2) {
      nameError = 'Must be at least 2 characters';
    } else if (name.length > 40) {
      nameError = 'Must be at most 40 characters';
    }

    if (description.length > 200) {
      descError = 'Must be at most 200 characters';
    }

    setState(() {
      _nameError = nameError;
      _descriptionError = descError;
    });
    return nameError == null && descError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    final name = _nameCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    final descriptionValue = description.isEmpty ? null : description;

    if (_mode == CategoryFormMode.create) {
      await ref.read(categoryControllerProvider.notifier).addCategory(
            name,
            description: descriptionValue,
            isActive: _isActive,
          );
    } else {
      final current = widget.category!;
      await ref.read(categoryControllerProvider.notifier).updateCategory(
            current.copyWith(
              name: name,
              description: descriptionValue,
              isActive: _isActive,
            ),
          );
    }

    if (!mounted) return;
    (widget.onClose ?? () => Navigator.of(context).pop())();
  }
}
