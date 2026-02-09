import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/staff/ui/widgets/custom_cupertino_list_tile.dart';
import 'package:modular_pos/features/staff/ui/widgets/form_dropdown_field.dart';
import 'package:modular_pos/features/staff/ui/widgets/form_text_field.dart';

class StaffBasicInfoSection extends ConsumerWidget {
  const StaffBasicInfoSection({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneNumberController,
    required this.emailController,
    required this.selectedGender,
    required this.onGenderChanged,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.selectedBranchName,
    required this.selectedBranchId,
    required this.onBranchChanged,
    required this.isActive,
    required this.onActiveChanged,
    required this.isReadOnly,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneNumberController;
  final TextEditingController emailController;
  final String? selectedGender;
  final ValueChanged<String?> onGenderChanged;
  final String? selectedRole;
  final ValueChanged<String?> onRoleChanged;
  final String? selectedBranchName;
  final String? selectedBranchId;
  final ValueChanged<String?> onBranchChanged;
  final bool isActive;
  final ValueChanged<bool> onActiveChanged;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Personal and contact details of the staff member',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: _buildLeftColumnFields(context, ref),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: _buildRightColumnFields(context, ref),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLeftColumnFields(BuildContext context, WidgetRef ref) {
    return [
      FormTextField(
        label: 'First Name',
        placeholder: 'Enter first name',
        controller: firstNameController,
        readOnly: isReadOnly,
        maxLength: 50,
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
      const SizedBox(height: 12),
      FormTextField(
        label: 'Email',
        placeholder: 'e.g., user@gmail.com',
        keyboardType: TextInputType.emailAddress,
        controller: emailController,
        readOnly: isReadOnly,
        maxLength: 100,
        validator: (v) => v!.isEmpty
            ? 'Required'
            : !v.contains('@')
            ? 'Invalid email'
            : null,
      ),
      const SizedBox(height: 12),
      FormDropdownField(
        label: 'Assign Role',
        placeholder: 'Select Role',
        value: selectedRole,
        items: const ['Admin', 'Manager', 'Cashier'],
        enabled: !isReadOnly,
        onSelected: onRoleChanged,
        validator: (v) => v == null ? 'Required' : null,
      ),
      const SizedBox(height: 20),
      if (!isReadOnly)
        CustomCupertinoListTile(
          title: const Text('Set Active'),
          trailing: CupertinoSwitch(
            value: isActive,
            onChanged: onActiveChanged,
            activeTrackColor: Theme.of(context).primaryColor,
          ),
        ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _buildRightColumnFields(BuildContext context, WidgetRef ref) {
    return [
      FormTextField(
        label: 'Last Name',
        placeholder: 'Enter last name',
        controller: lastNameController,
        readOnly: isReadOnly,
        maxLength: 50,
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
      const SizedBox(height: 12),
      FormTextField(
        label: 'Contact',
        placeholder: 'e.g., 012345678',
        keyboardType: TextInputType.phone,
        controller: phoneNumberController,
        readOnly: isReadOnly,
        maxLength: 15,
        validator: (v) => v!.isEmpty
            ? 'Required'
            : v.length < 7
            ? 'Invalid phone'
            : null,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\+]'))],
      ),
      const SizedBox(height: 12),
      FormDropdownField(
        label: 'Gender',
        placeholder: 'Select Gender',
        value: selectedGender,
        items: const ['Male', 'Female'],
        enabled: !isReadOnly,
        onSelected: onGenderChanged,
        validator: (v) => v == null ? 'Required' : null,
      ),
      const SizedBox(height: 12),
      FormDropdownField(
        label: 'Assign Branch',
        placeholder: 'Select Branch',
        value: selectedBranchName,
        items:
            ref
                .watch(loginControllerProvider)
                .user
                ?.branches
                .map((b) => b.name)
                .toList() ??
            [],
        enabled: !isReadOnly,
        onSelected: onBranchChanged,
        validator: (v) => v == null ? 'Required' : null,
      ),
      const SizedBox(height: 24),
    ];
  }
}
