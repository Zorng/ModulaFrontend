import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/staff/ui/view/staff_form/widgets/staff_schedule_section.dart';
import 'package:modular_pos/features/staff/ui/widgets/custom_cupertino_list_tile.dart';
import 'package:modular_pos/features/staff/ui/widgets/form_dropdown_field.dart';
import 'package:modular_pos/features/staff/ui/widgets/form_text_field.dart';

class StaffMobileFormSection extends ConsumerWidget {
  const StaffMobileFormSection({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneNumberController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.selectedGender,
    required this.onGenderChanged,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.selectedBranchName,
    required this.selectedBranchId,
    required this.onBranchChanged,
    required this.isActive,
    required this.onActiveChanged,
    required this.selectedScheduleOption,
    required this.onScheduleOptionChanged,
    required this.allDays,
    required this.selectedWorkingDays,
    required this.onWorkingDaysChanged,
    required this.startTime,
    required this.onStartTimeChanged,
    required this.endTime,
    required this.onEndTimeChanged,
    required this.expandedDay,
    required this.onExpandedDayChanged,
    required this.customHours,
    required this.onCustomHoursChanged,
    required this.isReadOnly,
    required this.isCreateMode,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmPasswordVisibility,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneNumberController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String? selectedGender;
  final ValueChanged<String?> onGenderChanged;
  final String? selectedRole;
  final ValueChanged<String?> onRoleChanged;
  final String? selectedBranchName;
  final String? selectedBranchId;
  final ValueChanged<String?> onBranchChanged;
  final bool isActive;
  final ValueChanged<bool> onActiveChanged;
  final String? selectedScheduleOption;
  final ValueChanged<String?> onScheduleOptionChanged;
  final List<String> allDays;
  final Set<String> selectedWorkingDays;
  final ValueChanged<Set<String>> onWorkingDaysChanged;
  final TimeOfDay startTime;
  final ValueChanged<TimeOfDay> onStartTimeChanged;
  final TimeOfDay endTime;
  final ValueChanged<TimeOfDay> onEndTimeChanged;
  final String? expandedDay;
  final ValueChanged<String?> onExpandedDayChanged;
  final Map<String, (TimeOfDay, TimeOfDay)> customHours;
  final void Function(String day, TimeOfDay start, TimeOfDay end)
  onCustomHoursChanged;
  final bool isReadOnly;
  final bool isCreateMode;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmPasswordVisibility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
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
          label: 'Last Name',
          placeholder: 'Enter last name',
          controller: lastNameController,
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
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\+]')),
          ],
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
          label: 'Assign Role',
          placeholder: 'Select Role',
          value: selectedRole,
          items: const ['Admin', 'Manager', 'Cashier'],
          enabled: !isReadOnly,
          onSelected: onRoleChanged,
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
          onSelected: (val) {
            final branches =
                ref.read(loginControllerProvider).user?.branches ?? [];
            final match = branches.where((b) => b.name == val);
            if (match.isNotEmpty) {
              final branchId = match.first.branchId.isNotEmpty
                  ? match.first.branchId
                  : match.first.id;
              onBranchChanged(branchId);
            }
          },
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        if (!isReadOnly)
          CustomCupertinoListTile(
            title: const Text('Set Active'),
            trailing: CupertinoSwitch(
              value: isActive,
              onChanged: onActiveChanged,
              activeTrackColor: Theme.of(context).primaryColor,
            ),
          ),
        if (!isReadOnly) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          ..._buildScheduleSection(),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          if (isCreateMode) ...[
            FormTextField(
              label: 'Password',
              placeholder: 'Enter password',
              obscureText: obscurePassword,
              showVisibilityToggle: true,
              onToggleVisibility: onTogglePasswordVisibility,
              controller: passwordController,
              readOnly: isReadOnly,
              maxLength: 50,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            FormTextField(
              label: 'Confirm Password',
              placeholder: 'Re-enter password',
              obscureText: obscureConfirmPassword,
              showVisibilityToggle: true,
              onToggleVisibility: onToggleConfirmPasswordVisibility,
              controller: confirmPasswordController,
              readOnly: isReadOnly,
              maxLength: 50,
              validator: (v) {
                if (v!.isEmpty) return 'Required';
                if (v != passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
        ],
      ],
    );
  }

  List<Widget> _buildScheduleSection() {
    return [
      StaffScheduleSection(
        isMobile: true,
        selectedScheduleOption: selectedScheduleOption,
        onScheduleOptionChanged: onScheduleOptionChanged,
        allDays: allDays,
        selectedWorkingDays: selectedWorkingDays,
        onWorkingDaysChanged: onWorkingDaysChanged,
        startTime: startTime,
        onStartTimeChanged: onStartTimeChanged,
        endTime: endTime,
        onEndTimeChanged: onEndTimeChanged,
        expandedDay: expandedDay,
        onExpandedDayChanged: onExpandedDayChanged,
        customHours: customHours,
        onCustomHoursChanged: onCustomHoursChanged,
      ),
    ];
  }
}
