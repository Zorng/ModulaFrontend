import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_buttons.dart';
import 'package:modular_pos/core/theme/app_gradient.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  ProviderSubscription<LoginState>? _loginSub;
  String? _lastRoute;

  @override
  void initState() {
    super.initState();
    _loginSub = ref.listenManual<LoginState>(loginControllerProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;

      final pendingPhone = (next.pendingVerificationPhone ?? '').trim();
      if (_requiresPhoneVerification(next) && pendingPhone.isNotEmpty) {
        final route =
            '${AppRoute.otpVerification.path}?phone=${Uri.encodeQueryComponent(pendingPhone)}';
        if (_lastRoute == route) return;
        _lastRoute = route;
        context.go(route);
        return;
      }

      final session = next.session;
      final user = next.user;
      if (session == null || user == null) return;

      final route = session.requiresTenantSelection
          ? AppRoute.tenantSelection.path
          : next.requiresBranchSelection
          ? AppRoute.branchSelection.path
          : AppRoute.portal.path;
      if (_lastRoute == route) return;
      _lastRoute = route;
      context.go(route);
    });
  }

  bool _requiresPhoneVerification(LoginState state) {
    if (state.errorStatusCode != 403) return false;
    final code = (state.errorCode ?? '').trim().toUpperCase();
    final message = (state.error ?? '').trim().toUpperCase();
    return code.contains('PHONE_NOT_VERIFIED') ||
        code.contains('PHONE_UNVERIFIED') ||
        message.contains('PHONE NOT VERIFIED') ||
        message.contains('NOT VERIFIED');
  }

  @override
  void dispose() {
    _loginSub?.close();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = AppBreakpoints.isSmall(constraints.maxWidth);

          return Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.backgroundGradient,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: isSmall
                    ? _MobileLoginForm(
                        state: state,
                        controller: controller,
                        phoneCtrl: _phoneCtrl,
                        passwordCtrl: _passwordCtrl,
                        obscurePassword: _obscurePassword,
                        toggleObscure: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      )
                    : _DesktopLoginForm(
                        state: state,
                        controller: controller,
                        phoneCtrl: _phoneCtrl,
                        passwordCtrl: _passwordCtrl,
                        obscurePassword: _obscurePassword,
                        toggleObscure: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MobileLoginForm extends StatelessWidget {
  const _MobileLoginForm({
    required this.state,
    required this.controller,
    required this.phoneCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.toggleObscure,
  });

  final LoginState state;
  final LoginController controller;
  final TextEditingController phoneCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final VoidCallback toggleObscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) =>
              AppGradients.textGradient.createShader(bounds),
          child: Text(
            'Modula',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.white),
            textAlign: TextAlign.left,
          ),
        ),
        Text(
          'Login to Modula',
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 28),
        TextField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone number'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: passwordCtrl,
          decoration: InputDecoration(
            labelText: 'Password',
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: toggleObscure,
            ),
          ),
          obscureText: obscurePassword,
        ),
        const SizedBox(height: 16),
        if (state.error != null)
          Text(state.error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 8),
        FilledButton(
          style: AppButtons.primary(context),
          onPressed: state.isLoading
              ? null
              : () {
                  controller.login(
                    phoneCtrl.text.trim(),
                    passwordCtrl.text.trim(),
                  );
                },
          child: state.isLoading
              ? const CircularProgressIndicator(strokeWidth: 2.5)
              : const Text('Login'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: state.isLoading
              ? null
              : () {
                  context.go(AppRoute.signup.path);
                },
          child: const Text('Create account'),
        ),
        const SizedBox(height: 8),
        Text(
          state.user != null
              ? 'Welcome ${state.user!.name}'
              : 'login to continue',
        ),
      ],
    );
  }
}

class _DesktopLoginForm extends StatelessWidget {
  const _DesktopLoginForm({
    required this.state,
    required this.controller,
    required this.phoneCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.toggleObscure,
  });

  final LoginState state;
  final LoginController controller;
  final TextEditingController phoneCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final VoidCallback toggleObscure;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _MobileLoginForm(
            state: state,
            controller: controller,
            phoneCtrl: phoneCtrl,
            passwordCtrl: passwordCtrl,
            obscurePassword: obscurePassword,
            toggleObscure: toggleObscure,
          ),
        ),
      ),
    );
  }
}
