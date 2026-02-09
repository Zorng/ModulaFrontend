import 'package:flutter/material.dart';
import 'package:modular_pos/features/staff/ui/widgets/form_text_field.dart';

class StaffAuthenticationSection extends StatelessWidget {
  const StaffAuthenticationSection({
    super.key,
    required this.phoneNumberController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isCreateMode,
    required this.isReadOnly,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmPasswordVisibility,
  });

  final TextEditingController phoneNumberController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isCreateMode;
  final bool isReadOnly;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmPasswordVisibility;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Authentication',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Login credentials and access control',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          FormTextField(
            label: 'Phone Number',
            placeholder: '+123456789',
            controller: phoneNumberController,
            readOnly: true,
            helperText: 'Phone number is set from Contact Information section',
          ),
          const SizedBox(height: 16),
          if (isCreateMode)
            Row(
              children: [
                Expanded(
                  child: FormTextField(
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
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormTextField(
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
                ),
              ],
            ),
        ],
      ),
    );
  }
}
