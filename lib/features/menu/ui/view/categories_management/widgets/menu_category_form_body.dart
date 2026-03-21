import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:modular_pos/core/theme/app_theme.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

enum MenuCategoryFormMode { create, view, edit }

class MenuCategoryFormBody extends ConsumerStatefulWidget {
  const MenuCategoryFormBody({
    super.key,
    required this.mode,
    this.category,
    this.showHeader = true,
    this.allowArchiveInViewMode = false,
    this.backgroundColor = Colors.white,
    this.useThemeCancelButtonStyle = false,
    this.onArchived,
    this.onStatusActionRequested,
    this.onClose,
  }) : assert(
         mode == MenuCategoryFormMode.create || category != null,
         'category is required for view/edit',
       );

  final MenuCategoryFormMode mode;
  final MenuCategory? category;
  final bool showHeader;
  final bool allowArchiveInViewMode;
  final Color backgroundColor;
  final bool useThemeCancelButtonStyle;
  final VoidCallback? onArchived;
  final Future<void> Function(MenuCategory category)? onStatusActionRequested;
  final VoidCallback? onClose;

  @override
  ConsumerState<MenuCategoryFormBody> createState() =>
      _MenuCategoryFormBodyState();
}

class _MenuCategoryFormBodyState extends ConsumerState<MenuCategoryFormBody> {
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  late MenuCategoryFormMode _mode;
  String? _nameError;
  String? _descriptionError;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    final category = widget.category;
    if (category != null) {
      _nameCtrl.text = category.name;
      _descriptionCtrl.text = category.description;
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
    ref.watch(menuViewModelProvider);
    final isView = _mode == MenuCategoryFormMode.view;
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
            _FieldLabel(
              text: 'Category Name',
              child: TextField(
                controller: _nameCtrl,
                enabled: !isView,
                onChanged: (_) {
                  if (_nameError == null) return;
                  setState(() => _nameError = null);
                },
                decoration: InputDecoration(
                  hintText: 'e.g., Coffee, Pastries',
                  errorText: _nameError,
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(height: 24),
            _FieldLabel(
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
    final category = _currentCategory();
    final isArchived =
        category != null && category.status.trim().toUpperCase() == 'ARCHIVED';
    if (_mode == MenuCategoryFormMode.view) {
      final showStatusAction = widget.allowArchiveInViewMode && category != null;
      if (!showStatusAction) {
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => setState(() => _mode = MenuCategoryFormMode.edit),
            child: const Text('Edit'),
          ),
        );
      }

      return Row(
        children: [
          Expanded(
            child: FilledButton(
              style: archiveButtonStyle,
              onPressed: widget.onStatusActionRequested != null
                  ? () => widget.onStatusActionRequested!(category)
                  : isArchived
                  ? _restoreCategory
                  : _archiveCategory,
              child: Text(isArchived ? 'Restore' : 'Archive'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: () => setState(() => _mode = MenuCategoryFormMode.edit),
              child: const Text('Edit'),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            style: widget.useThemeCancelButtonStyle
                ? AppTheme.cancelActionButtonStyle
                : FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor:
                        Theme.of(context).textTheme.bodyLarge?.color,
                  ),
            onPressed: widget.onClose ?? _cancelEdit,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _submit,
            child: Text(
              _mode == MenuCategoryFormMode.create ? 'Create Category' : 'Save',
            ),
          ),
        ),
      ],
    );
  }

  String _title() => switch (_mode) {
    MenuCategoryFormMode.create => 'Add category',
    MenuCategoryFormMode.view => 'Category details',
    MenuCategoryFormMode.edit => 'Edit category',
  };

  void _cancelEdit() {
    setState(() {
      _mode = MenuCategoryFormMode.view;
      _nameCtrl.text = widget.category?.name ?? '';
      _descriptionCtrl.text = widget.category?.description ?? '';
      _nameError = null;
      _descriptionError = null;
    });
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    final name = _nameCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    final descriptionValue = description.isEmpty ? '' : description;

    try {
      if (_mode == MenuCategoryFormMode.create) {
        await ref.read(menuViewModelProvider.notifier).addCategory(
          name: name,
          description: descriptionValue,
        );
      } else {
        await ref.read(menuViewModelProvider.notifier).updateCategory(
          _currentCategory()!.copyWith(
            name: name,
            description: descriptionValue,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      final state = ref.read(menuViewModelProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error ?? 'Failed to save category.')),
      );
      return;
    }

    if (!mounted) return;
    (widget.onClose ?? () => Navigator.of(context).pop())();
  }

  bool _validate() {
    final name = _nameCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    String? nameError;
    String? descriptionError;

    if (name.isEmpty) {
      nameError = 'Required';
    } else if (name.length < 2) {
      nameError = 'Must be at least 2 characters';
    } else if (name.length > 40) {
      nameError = 'Must be at most 40 characters';
    }

    if (description.length > 200) {
      descriptionError = 'Must be at most 200 characters';
    }

    setState(() {
      _nameError = nameError;
      _descriptionError = descriptionError;
    });
    return nameError == null && descriptionError == null;
  }

  Future<void> _archiveCategory() async {
    final category = _currentCategory();
    if (category == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final background = Theme.of(context).scaffoldBackgroundColor;
        return AlertDialog(
          backgroundColor: background,
          surfaceTintColor: background,
          title: const Text('Archive category?'),
          content: Text(
            '"${category.name}" will be archived and removed from active menu categories.',
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: AppTheme.cancelActionButtonStyle,
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
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    try {
      await ref
          .read(menuViewModelProvider.notifier)
          .deleteCategory(category.id);
      if (!mounted) return;
      widget.onArchived?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${category.name}" archived')),
      );
      (widget.onClose ?? () => Navigator.of(context).pop())();
    } catch (_) {
      if (!mounted) return;
      final state = ref.read(menuViewModelProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Failed to archive category.'),
        ),
      );
    }
  }

  Future<void> _restoreCategory() async {
    final category = _currentCategory();
    if (category == null) return;

    try {
      await ref.read(menuViewModelProvider.notifier).restoreCategory(category);
      if (!mounted) return;
      widget.onArchived?.call();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${category.name}" restored')));
      (widget.onClose ?? () => Navigator.of(context).pop())();
    } catch (_) {
      if (!mounted) return;
      final state = ref.read(menuViewModelProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Failed to restore category.'),
        ),
      );
    }
  }

  MenuCategory? _currentCategory() {
    final original = widget.category;
    if (original == null) return null;
    final categories = ref.read(menuViewModelProvider).categories;
    for (final category in categories) {
      if (category.id == original.id) {
        return category;
      }
    }
    return original;
  }

}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
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
