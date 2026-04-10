import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/domain/phone_input.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage({super.key, this.initialPhone});

  final String? initialPhone;

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  late final TextEditingController _phoneCtrl;
  final _otpCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final pendingPhone = ref
        .read(loginControllerProvider)
        .pendingVerificationPhone;
    _phoneCtrl = TextEditingController(
      text: (widget.initialPhone ?? pendingPhone ?? '').trim(),
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = normalizePhoneInput(_phoneCtrl.text);
    if (phone.isEmpty) return;
    await ref
        .read(loginControllerProvider.notifier)
        .sendRegistrationOtp(phone: phone);
  }

  Future<void> _verify() async {
    final phone = normalizePhoneInput(_phoneCtrl.text);
    final otp = _otpCtrl.text.trim();
    if (phone.isEmpty || otp.isEmpty) return;

    final controller = ref.read(loginControllerProvider.notifier);
    await controller.verifyRegistrationOtp(phone: phone, otp: otp);
    final state = ref.read(loginControllerProvider);
    if (state.error != null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone verified. You can login now.')),
    );
    context.go(AppRoute.login.path);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify phone')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'OTP code'),
                ),
                const SizedBox(height: 8),
                if (state.otpExpiresInMinutes != null)
                  Text(
                    'OTP expires in ${state.otpExpiresInMinutes} minutes.',
                    style: const TextStyle(color: Colors.black54),
                  ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: state.isLoading ? null : _verify,
                  child: state.isLoading
                      ? const CircularProgressIndicator(strokeWidth: 2.5)
                      : const Text('Verify OTP'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: state.isLoading ? null : _sendOtp,
                  child: const Text('Resend OTP'),
                ),
                TextButton(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          context.go(AppRoute.login.path);
                        },
                  child: const Text('Back to login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
