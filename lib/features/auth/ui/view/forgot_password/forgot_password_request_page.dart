import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/domain/phone_input.dart';
import 'package:modular_pos/features/auth/ui/view/forgot_password/widgets/auth_recovery_shell.dart';
import 'package:modular_pos/features/auth/ui/view/forgot_password/widgets/forgot_password_request_form.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/forgot_password_controller.dart';

class ForgotPasswordRequestPage extends ConsumerStatefulWidget {
  const ForgotPasswordRequestPage({super.key, this.initialPhone});

  final String? initialPhone;

  @override
  ConsumerState<ForgotPasswordRequestPage> createState() =>
      _ForgotPasswordRequestPageState();
}

class _ForgotPasswordRequestPageState
    extends ConsumerState<ForgotPasswordRequestPage> {
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final seededPhone =
        (widget.initialPhone ??
                ref.read(forgotPasswordControllerProvider).phone ??
                '')
            .trim();
    _phoneCtrl = TextEditingController(text: seededPhone);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = normalizePhoneInput(_phoneCtrl.text);
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

    final encodedPhone = Uri.encodeQueryComponent(phone);
    context.go('${AppRoute.forgotPasswordConfirm.path}?phone=$encodedPhone');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);

    return AuthRecoveryShell(
      title: 'Forgot password',
      subtitle: 'Send a recovery OTP to your phone number.',
      child: ForgotPasswordRequestForm(
        state: state,
        phoneCtrl: _phoneCtrl,
        onSubmit: _submit,
        onBackToLogin: () => context.go(AppRoute.login.path),
        useFramedInputs: true,
      ),
    );
  }
}
