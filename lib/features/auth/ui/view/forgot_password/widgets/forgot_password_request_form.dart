import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/app_buttons.dart';
import 'package:modular_pos/features/auth/ui/view/forgot_password/widgets/auth_recovery_input_decoration.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/forgot_password_controller.dart';

class ForgotPasswordRequestForm extends StatelessWidget {
  const ForgotPasswordRequestForm({
    super.key,
    required this.state,
    required this.phoneCtrl,
    required this.onSubmit,
    required this.onBackToLogin,
    this.useFramedInputs = false,
  });

  final ForgotPasswordState state;
  final TextEditingController phoneCtrl;
  final Future<void> Function() onSubmit;
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
        Text(
          'We will send a verification code to this phone number so you can set a new password.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B6B70)),
        ),
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
                : const Text('Send OTP'),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: state.isLoading ? null : onBackToLogin,
          child: const Text('Back to login'),
        ),
      ],
    );
  }
}
