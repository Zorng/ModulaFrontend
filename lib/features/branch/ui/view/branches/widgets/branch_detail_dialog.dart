import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/theme/app_buttons.dart';
import 'package:modular_pos/features/branch/data/branch_providers.dart';
import 'package:modular_pos/features/branch/domain/models/branch.dart';
import 'package:modular_pos/features/branch/ui/viewmodels/branch_store.dart';

class BranchDetailDialog extends ConsumerStatefulWidget {
  final String branchId;

  const BranchDetailDialog({super.key, required this.branchId});

  @override
  ConsumerState<BranchDetailDialog> createState() => _BranchDetailDialogState();
}

class _BranchDetailDialogState extends ConsumerState<BranchDetailDialog> {
  bool _isEditMode = false;
  bool _isSaving = false;
  bool _isInitialized = false;

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  String? _nameError;
  String? _addressError;
  String? _phoneError;
  String? _emailError;

  // Track if fields have been touched (user has entered text)
  bool _nameTouched = false;
  bool _addressTouched = false;
  bool _phoneTouched = false;
  bool _emailTouched = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();

    _nameController.addListener(_validateName);
    _addressController.addListener(_validateAddress);
    _phoneController.addListener(_validatePhone);
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateName);
    _addressController.removeListener(_validateAddress);
    _phoneController.removeListener(_validatePhone);
    _emailController.removeListener(_validateEmail);
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _validateName() {
    if (!_isEditMode || !_nameTouched) return;
    setState(() {
      if (_nameController.text.trim().isEmpty) {
        // Don't show error for empty field until save attempt
        _nameError = null;
      } else if (_nameController.text.trim().length > 50) {
        _nameError = 'Branch name must not exceed 50 characters';
      } else {
        _nameError = null;
      }
    });
  }

  void _validateAddress() {
    if (!_isEditMode || !_addressTouched) return;
    setState(() {
      // Address has no format restrictions, only required check
      // Don't show error until save attempt
      _addressError = null;
    });
  }

  void _validatePhone() {
    if (!_isEditMode || !_phoneTouched) return;
    final phone = _phoneController.text.trim();

    setState(() {
      if (phone.isEmpty) {
        // Don't show error for empty field until save attempt
        _phoneError = null;
        return;
      }

      final phoneRegex = RegExp(r'^[\d\s\+\-\(\)]+$');
      if (!phoneRegex.hasMatch(phone)) {
        _phoneError = 'Invalid phone format';
      } else if (phone.replaceAll(RegExp(r'[\s\+\-\(\)]'), '').length < 8) {
        _phoneError = 'Phone must have at least 8 digits';
      } else {
        _phoneError = null;
      }
    });
  }

  void _validateEmail() {
    if (!_isEditMode || !_emailTouched) return;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = null);
      return;
    }

    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    setState(() {
      _emailError = emailRegex.hasMatch(email) ? null : 'Invalid email format';
    });
  }

  bool get _canSave {
    if (!_isEditMode) return false;
    if (_nameController.text.trim().isEmpty) return false;
    if (_addressController.text.trim().isEmpty) return false;
    if (_phoneController.text.trim().isEmpty) return false;
    if (_nameError != null ||
        _addressError != null ||
        _phoneError != null ||
        _emailError != null) {
      return false;
    }
    return true;
  }

  void _initializeControllers(Branch branch) {
    if (!_isInitialized) {
      _nameController.text = branch.name;
      _addressController.text = branch.address ?? '';
      _phoneController.text = branch.contactPhone ?? '';
      _emailController.text = branch.contactEmail ?? '';
      _isInitialized = true;
    }
  }

  void _toggleEditMode(Branch branch) {
    if (_isEditMode) {
      // Cancel - reset to original values
      _nameController.text = branch.name;
      _addressController.text = branch.address ?? '';
      _phoneController.text = branch.contactPhone ?? '';
      _emailController.text = branch.contactEmail ?? '';

      setState(() {
        _nameError = null;
        _addressError = null;
        _phoneError = null;
        _emailError = null;
        _nameTouched = false;
        _addressTouched = false;
        _phoneTouched = false;
        _emailTouched = false;
      });
    }
    setState(() => _isEditMode = !_isEditMode);
  }

  Future<void> _saveChanges() async {
    if (_isSaving || !_canSave) return;

    setState(() => _isSaving = true);

    try {
      await ref
          .read(branchRepositoryProvider)
          .updateBranch(
            branchId: widget.branchId,
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            contactPhone: _phoneController.text.trim(),
            contactEmail: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
          );

      await ref.read(branchStoreProvider.notifier).refresh();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Branch updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserErrorMessage.build(
              context: 'Failed to update branch',
              error: e,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchStoreProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: 750,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: branchesAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(child: Text(e.toString())),
          ),
          data: (branches) {
            final branch = branches.firstWhere((b) => b.id == widget.branchId);
            _initializeControllers(branch);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Text(
                        'Branch Detail',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DialogField(
                          label: 'Branch Name',
                          icon: Icons.store_outlined,
                          controller: _nameController,
                          enabled: _isEditMode,
                          errorText: _nameError,
                          maxLength: 50,
                          onChanged: () => setState(() => _nameTouched = true),
                        ),
                        const SizedBox(height: 16),
                        _DialogField(
                          label: 'Address',
                          icon: Icons.location_on_outlined,
                          controller: _addressController,
                          enabled: _isEditMode,
                          errorText: _addressError,
                          onChanged: () =>
                              setState(() => _addressTouched = true),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _DialogDropdownField(
                                label: 'Managed By',
                                value: branch.managedBy ?? 'Not assigned',
                                enabled: false,
                                withAvatar: false,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _DialogField(
                                label: 'Role',
                                controller: TextEditingController(
                                  text: 'Admin',
                                ),
                                enabled: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _DialogField(
                          label: 'Contact',
                          icon: Icons.phone_outlined,
                          controller: _phoneController,
                          enabled: _isEditMode,
                          keyboardType: TextInputType.phone,
                          errorText: _phoneError,
                          onChanged: () => setState(() => _phoneTouched = true),
                        ),
                        const SizedBox(height: 16),
                        _DialogDropdownField(
                          label: 'Status',
                          value: branch.status == 'FROZEN'
                              ? 'Inactive'
                              : 'Active',
                          enabled: false,
                          withAvatar: false,
                        ),
                        if (branch.isFrozen) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              border: Border.all(color: Colors.orange.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: 20,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'This branch is inactive and cannot be edited',
                                    style: TextStyle(
                                      color: Colors.orange.shade900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1),

                // Footer buttons
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!_isEditMode)
                        SizedBox(
                          width: 150,
                          child: FilledButton(
                            onPressed: branch.isFrozen
                                ? null
                                : () => _toggleEditMode(branch),
                            style: AppButtons.primary(context),
                            child: const Text('Edit Branch'),
                          ),
                        )
                      else ...[
                        SizedBox(
                          width: 120,
                          child: FilledButton(
                            onPressed: _isSaving
                                ? null
                                : () => _toggleEditMode(branch),
                            style: AppButtons.secondary(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 150,
                          child: FilledButton(
                            onPressed: _isSaving || !_canSave
                                ? null
                                : _saveChanges,
                            style: AppButtons.primary(context),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final String label;
  final IconData? icon;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? errorText;
  final int? maxLength;
  final VoidCallback? onChanged;

  const _DialogField({
    required this.label,
    this.icon,
    required this.controller,
    required this.enabled,
    this.keyboardType,
    this.errorText,
    this.maxLength,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fieldBorder = Border.all(color: Colors.grey.shade300, width: 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 48,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                border: fieldBorder,
                color: Colors.grey.shade100,
              ),
              child: Row(
                children: [
                  if (icon != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Icon(icon, size: 20, color: Colors.grey),
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: icon != null ? 8 : 16,
                        top: 14,
                        bottom: 14,
                      ),
                      child: TextField(
                        controller: controller,
                        enabled: enabled,
                        keyboardType: keyboardType,
                        maxLines: 1,
                        maxLength: maxLength,
                        onChanged: onChanged != null
                            ? (_) => onChanged!()
                            : null,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          isCollapsed: true,
                          counterText: '',
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            _DialogFloatingLabel(label),
          ],
        ),
        if (errorText != null && errorText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _DialogDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final bool enabled;
  final bool withAvatar;

  const _DialogDropdownField({
    required this.label,
    required this.value,
    required this.enabled,
    this.withAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    final fieldBorder = Border.all(color: Colors.grey.shade300, width: 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 48,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                border: fieldBorder,
                color: Colors.grey.shade100,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (withAvatar) ...[
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.orange.shade100,
                      child: Text(
                        'A',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
            _DialogFloatingLabel(label),
          ],
        ),
      ],
    );
  }
}

class _DialogFloatingLabel extends StatelessWidget {
  final String text;

  const _DialogFloatingLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      top: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        color: Colors.transparent,
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}
