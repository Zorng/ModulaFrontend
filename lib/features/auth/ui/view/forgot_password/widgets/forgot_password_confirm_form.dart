import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/app_buttons.dart';
import 'package:modular_pos/features/auth/ui/view/forgot_password/widgets/auth_recovery_input_decoration.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/forgot_password_controller.dart';

class ForgotPasswordConfirmForm extends StatelessWidget {
  const ForgotPasswordConfirmForm({
    super.key,
    required this.state,
    required this.phoneCtrl,
    required this.otpCtrl,
    required this.newPasswordCtrl,
    required this.confirmPasswordCtrl,
    required this.obscureNewPassword,
    required this.obscureConfirmPassword,
    required this.onToggleNewPassword,
    required this.onToggleConfirmPassword,
    required this.onSubmit,
    required this.onResendOtp,
    required this.onBackToLogin,
    this.useFramedInputs = false,
  });

  final ForgotPasswordState state;
  final TextEditingController phoneCtrl;
  final TextEditingController otpCtrl;
  final TextEditingController newPasswordCtrl;
  final TextEditingController confirmPasswordCtrl;
  final bool obscureNewPassword;
  final bool obscureConfirmPassword;
  final VoidCallback onToggleNewPassword;
  final VoidCallback onToggleConfirmPassword;
  final Future<void> Function() onSubmit;
  final Future<void> Function() onResendOtp;
  final VoidCallback onBackToLogin;
  final bool useFramedInputs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: authRecoveryInputDecoration(
            labelText: 'Phone number',
            hintText: 'your phone number',
            useFramedInputs: useFramedInputs,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: otpCtrl,
          keyboardType: TextInputType.number,
          decoration: authRecoveryInputDecoration(
            labelText: 'OTP code',
            hintText: '6-digit verification code',
            useFramedInputs: useFramedInputs,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: newPasswordCtrl,
          obscureText: obscureNewPassword,
          decoration: authRecoveryInputDecoration(
            labelText: 'New password',
            hintText: 'your new password',
            useFramedInputs: useFramedInputs,
            suffixIcon: IconButton(
              onPressed: onToggleNewPassword,
              icon: Icon(
                obscureNewPassword ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: confirmPasswordCtrl,
          obscureText: obscureConfirmPassword,
          decoration: authRecoveryInputDecoration(
            labelText: 'Confirm new password',
            hintText: 'confirm your new password',
            useFramedInputs: useFramedInputs,
            suffixIcon: IconButton(
              onPressed: onToggleConfirmPassword,
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
            ),
          ),
        ),
        if (state.otpExpiresInMinutes != null) ...[
          const SizedBox(height: 8),
          Text(
            'OTP expires in ${state.otpExpiresInMinutes} minutes.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B6B70)),
          ),
        ],
        if (state.error != null) ...[
          const SizedBox(height: 12),
          Text(
            state.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: AppButtons.primary(context),
            onPressed: state.isLoading
                ? null
                : () {
                    onSubmit();
                  },
            child: state.isLoading
                ? const CircularProgressIndicator(strokeWidth: 2.5)
                : const Text('Reset password'),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: state.isLoading
              ? null
              : () {
                  onResendOtp();
                },
          child: const Text('Resend OTP'),
        ),
        TextButton(
          onPressed: state.isLoading ? null : onBackToLogin,
          child: const Text('Back to login'),
        ),
      ],
    );
  }
}
