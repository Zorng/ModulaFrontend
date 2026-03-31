import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/ui/view/forgot_password/widgets/auth_recovery_shell.dart';
import 'package:modular_pos/features/auth/ui/view/forgot_password/widgets/forgot_password_confirm_form.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/forgot_password_controller.dart';

class ForgotPasswordConfirmPage extends ConsumerStatefulWidget {
  const ForgotPasswordConfirmPage({super.key, this.initialPhone});

  final String? initialPhone;

  @override
  ConsumerState<ForgotPasswordConfirmPage> createState() =>
      _ForgotPasswordConfirmPageState();
}

class _ForgotPasswordConfirmPageState
    extends ConsumerState<ForgotPasswordConfirmPage> {
  late final TextEditingController _phoneCtrl;
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    final phone =
        (widget.initialPhone ??
                ref.read(forgotPasswordControllerProvider).phone ??
                '')
            .trim();
    _phoneCtrl = TextEditingController(text: phone);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phoneCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;

    if (phone.isEmpty ||
        otp.isEmpty ||
        newPassword.trim().isEmpty ||
        confirmPassword.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All fields are required.')));
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password confirmation does not match.'),
        ),
      );
      return;
    }

    final success = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .confirmReset(phone: phone, otp: otp, newPassword: newPassword.trim());
    if (!success || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset successful. Please log in again.'),
      ),
    );
    context.go(AppRoute.login.path);
  }

  Future<void> _resendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is required.')),
      );
      return;
    }

    final success = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .requestResetOtp(phone: phone);
    if (!success || !mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('OTP sent again.')));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);

    return AuthRecoveryShell(
      title: 'Reset password',
      subtitle: 'Confirm the recovery OTP and choose a new password.',
      child: ForgotPasswordConfirmForm(
        state: state,
        phoneCtrl: _phoneCtrl,
        otpCtrl: _otpCtrl,
        newPasswordCtrl: _newPasswordCtrl,
        confirmPasswordCtrl: _confirmPasswordCtrl,
        obscureNewPassword: _obscureNewPassword,
        obscureConfirmPassword: _obscureConfirmPassword,
        onToggleNewPassword: () {
          setState(() {
            _obscureNewPassword = !_obscureNewPassword;
          });
        },
        onToggleConfirmPassword: () {
          setState(() {
            _obscureConfirmPassword = !_obscureConfirmPassword;
          });
        },
        onSubmit: _submit,
        onResendOtp: _resendOtp,
        onBackToLogin: () => context.go(AppRoute.login.path),
        useFramedInputs: true,
      ),
    );
  }
}
