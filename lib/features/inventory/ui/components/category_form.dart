import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:modular_pos/core/theme/app_theme.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/category_controller.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';

enum CategoryFormMode { create, view, edit }

class CategoryFormBody extends ConsumerStatefulWidget {
  const CategoryFormBody({
    super.key,
    required this.mode,
    this.category,
    this.showHeader = true,
    this.allowArchiveInViewMode = false,
    this.backgroundColor = Colors.white,
    this.onArchived,
    this.onArchiveRequested,
    this.onClose,
  }) : assert(
         mode == CategoryFormMode.create || category != null,
         'category is required for view/edit',
       );

  final CategoryFormMode mode;
  final InventoryCategory? category;
  final bool showHeader;
  final bool allowArchiveInViewMode;
  final Color backgroundColor;
  final VoidCallback? onArchived;
  final Future<void> Function()? onArchiveRequested;
  final VoidCallback? onClose;

  @override
  ConsumerState<CategoryFormBody> createState() => _CategoryFormBodyState();
}

class _CategoryFormBodyState extends ConsumerState<CategoryFormBody> {
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  CategoryFormMode _mode = CategoryFormMode.create;
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
    final archiveButtonStyle = AppTheme.cancelActionButtonStyle;
    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        color: widget.backgroundColor,
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
                    onPressed:
                        widget.onClose ?? () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            if (widget.showHeader) const SizedBox(height: 16),
            _RequiredFieldLabel(
              text: 'Category Name',
              child: TextField(
                controller: _nameCtrl,
                onChanged: (_) {
                  if (_nameError == null) return;
                  setState(() => _nameError = null);
                },
                enabled: !isView,
                decoration: InputDecoration(
                  hintText: 'e.g., Coffee, Pastries',
                  errorText: _nameError,
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(height: 24),
            _RequiredFieldLabel(
              text: 'Description',
              isOptional: true,
              child: TextField(
                controller: _descriptionCtrl,
                enabled: !isView,
                decoration: InputDecoration(
                  hintText: 'Enter category description',
                  errorText: _descriptionError,
                ),
                maxLines: 3,
                maxLength: 200,
              ),
            ),
            const SizedBox(height: 24),
            _buildActions(context, archiveButtonStyle: archiveButtonStyle),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(
    BuildContext context, {
    required ButtonStyle archiveButtonStyle,
  }) {
    if (_mode == CategoryFormMode.view) {
      final canArchive =
          widget.allowArchiveInViewMode && (widget.category?.isActive ?? false);
      if (!canArchive) {
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => setState(() => _mode = CategoryFormMode.edit),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
          ),
        );
      }

      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              style: archiveButtonStyle,
              onPressed: widget.onArchiveRequested != null
                  ? () => widget.onArchiveRequested!.call()
                  : _archiveCategory,
              icon: const Icon(Icons.archive_outlined, size: 18),
              label: const Text('Archive'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => setState(() => _mode = CategoryFormMode.edit),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
            ),
          ),
        ],
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

    try {
      if (_mode == CategoryFormMode.create) {
        await ref
            .read(categoryControllerProvider.notifier)
            .addCategory(name, description: descriptionValue);
      } else {
        final current = widget.category!;
        await ref
            .read(categoryControllerProvider.notifier)
            .updateCategory(
              current.copyWith(name: name, description: descriptionValue),
            );
      }
    } catch (e) {
      if (!mounted) return;
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to save category.',
      );
      if (mapped.code == InventoryErrorCode.stockCategoryDuplicateName) {
        setState(() => _nameError = mapped.message);
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapped.message)));
      return;
    }

    if (!mounted) return;
    (widget.onClose ?? () => Navigator.of(context).pop())();
  }

  Future<void> _archiveCategory() async {
    final current = widget.category;
    if (current == null || !current.isActive) return;

    final cancelButtonStyle = AppTheme.cancelActionButtonStyle;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Archive category?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  '"${current.name}" will be archived and detached from stock items.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: cancelButtonStyle,
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Archive'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirm != true) return;

    try {
      await ref
          .read(categoryControllerProvider.notifier)
          .deleteCategory(current.id);
      if (!mounted) return;
      widget.onArchived?.call();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${current.name}" archived')));
      (widget.onClose ?? () => Navigator.of(context).pop())();
    } catch (e) {
      if (!mounted) return;
      final mapped = mapInventoryError(
        e,
        fallbackMessage: 'Failed to archive category.',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapped.message)));
    }
  }
}

class _RequiredFieldLabel extends StatelessWidget {
  const _RequiredFieldLabel({
    required this.text,
    required this.child,
    this.isOptional = false,
  });

  final String text;
  final Widget child;
  final bool isOptional;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            isOptional ? '$text (Optional)' : text,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        child,
      ],
    );
  }
}
