import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modular_pos/core/widgets/media/product_image_picker.dart';
import 'package:modular_pos/features/tenant/ui/viewmodels/tenant_selection/tenant_selection_controller.dart';

Future<void> showCreateTenantDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 560),
          child: const CreateTenantDialogBody(),
        ),
      );
    },
  );
}

class CreateTenantDialogBody extends ConsumerStatefulWidget {
  const CreateTenantDialogBody({super.key});

  @override
  ConsumerState<CreateTenantDialogBody> createState() =>
      _CreateTenantDialogBodyState();
}

class _CreateTenantDialogBodyState
    extends ConsumerState<CreateTenantDialogBody> {
  final _tenantNameController = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _selectedImageBytes;
  String? _tenantNameError;

  @override
  void dispose() {
    _tenantNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tenantState = ref.watch(tenantSelectionControllerProvider);
    final tenantController = ref.read(
      tenantSelectionControllerProvider.notifier,
    );
    final backendError = tenantState.createTenantError;
    final isCreating = tenantState.isCreatingTenant;
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'create tenant',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: isCreating
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 20),
            _FieldLabel(
              text: 'Tenant image',
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      return ProductImagePicker(
                        size: Size(width, width * 0.83),
                        borderRadius: 14,
                        imageBytes: _selectedImageBytes,
                        placeholderLabel: 'Upload image',
                        onPickImage: _pickImage,
                        onClearLocalSelection: _selectedImageBytes == null
                            ? null
                            : () => setState(() => _selectedImageBytes = null),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _FieldLabel(
              text: 'Tenant name',
              isRequired: true,
              child: TextField(
                controller: _tenantNameController,
                textInputAction: TextInputAction.done,
                enabled: !isCreating,
                onSubmitted: (_) => _submit(),
                onChanged: (_) {
                  if (_tenantNameError != null) {
                    setState(() => _tenantNameError = null);
                  }
                  tenantController.clearCreateTenantFeedback();
                },
                decoration: InputDecoration(
                  hintText: 'Enter tenant name',
                  errorText: _tenantNameError,
                ),
              ),
            ),
            if (backendError != null && backendError.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                backendError,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isCreating
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isCreating ? null : _submit,
                    child: isCreating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImageBytes = bytes;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Image picker not available. Please fully restart the app after running flutter pub get.',
          ),
        ),
      );
    }
  }

  Future<void> _submit() async {
    final tenantName = _tenantNameController.text.trim();
    if (tenantName.isEmpty) {
      setState(() => _tenantNameError = 'Tenant name is required.');
      return;
    }

    final result = await ref
        .read(tenantSelectionControllerProvider.notifier)
        .createTenant(tenantName);
    if (!mounted) return;
    if (result != null) {
      Navigator.of(context).pop();
    }
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.text,
    required this.child,
    this.isRequired = false,
  });

  final String text;
  final Widget child;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RichText(
            text: TextSpan(
              text: text,
              style: Theme.of(context).textTheme.titleSmall,
              children: [
                if (isRequired)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
