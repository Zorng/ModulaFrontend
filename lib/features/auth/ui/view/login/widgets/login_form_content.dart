import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/app_buttons.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

class LoginFormContent extends StatelessWidget {
  const LoginFormContent({
    super.key,
    required this.state,
    required this.phoneCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onLogin,
    required this.onSignup,
    this.onVerifyPhone,
    this.signupLabel = 'Create account',
    this.footerText,
    this.showDesktopFieldLabels = false,
    this.phoneHintText,
    this.passwordHintText,
    this.showForgotPasswordHint = false,
    this.signupPromptText,
    this.buttonLabel = 'Login',
    this.useFramedInputs = false,
  });

  final LoginState state;
  final TextEditingController phoneCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onLogin;
  final VoidCallback onSignup;
  final VoidCallback? onVerifyPhone;
  final String signupLabel;
  final String? footerText;
  final bool showDesktopFieldLabels;
  final String? phoneHintText;
  final String? passwordHintText;
  final bool showForgotPasswordHint;
  final String? signupPromptText;
  final String buttonLabel;
  final bool useFramedInputs;

  @override
  Widget build(BuildContext context) {
    final showDesktopFields = showDesktopFieldLabels;
    final framedInputDecoration = _framedInputDecoration();
    final useSharedFramedInputs = showDesktopFields || useFramedInputs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDesktopFields) ...[
          _FieldLabel(label: 'Phone Number'),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: useSharedFramedInputs
              ? framedInputDecoration.copyWith(
                  hintText: phoneHintText ?? 'your phone number',
                )
              : const InputDecoration(labelText: 'Phone number'),
        ),
        const SizedBox(height: 8),
        if (showDesktopFields) ...[
          _FieldLabel(label: 'Password'),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: passwordCtrl,
          decoration:
              (useSharedFramedInputs
                      ? framedInputDecoration.copyWith(
                          hintText: passwordHintText ?? 'your password',
                        )
                      : const InputDecoration(labelText: 'Password'))
                  .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: onToggleObscure,
                    ),
                  ),
          obscureText: obscurePassword,
        ),
        if (showForgotPasswordHint) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Forgot password?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (state.error != null)
          Text(state.error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: AppButtons.primary(context),
            onPressed: state.isLoading ? null : onLogin,
            child: state.isLoading
                ? const CircularProgressIndicator(strokeWidth: 2.5)
                : Text(buttonLabel),
          ),
        ),
        const SizedBox(height: 8),
        if (signupPromptText == null)
          TextButton(
            onPressed: state.isLoading ? null : onSignup,
            child: Text(signupLabel),
          )
        else
          Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(signupPromptText!),
                TextButton(
                  onPressed: state.isLoading ? null : onSignup,
                  child: Text(signupLabel),
                ),
              ],
            ),
          ),
        if (onVerifyPhone != null)
          Center(
            child: TextButton(
              onPressed: state.isLoading ? null : onVerifyPhone,
              child: const Text('Verify phone / resend OTP'),
            ),
          ),
        if (footerText != null) ...[
          const SizedBox(height: 8),
          Text(footerText!),
        ],
      ],
    );
  }

  InputDecoration _framedInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: Color(0xFFB8B8B8)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE2E2E2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE2E2E2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFED533C), width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: const Color(0xFF4A4A4A),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
