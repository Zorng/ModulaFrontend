import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_gradient.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/ui/view/login/widgets/login_form_content.dart';
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

      final role = resolveSessionAuthRole(session);
      final route = session.requiresTenantSelection
          ? AppRoute.tenantSelection.path
          : next.requiresBranchSelection
          ? AppRoute.branchSelection.path
          : (role == AuthRole.admin || role == AuthRole.owner)
          ? AppRoute.portal.path
          : AppRoute.cashSession.path;
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

  void _goToOtpVerification() {
    final phone = _phoneCtrl.text.trim();
    final route = phone.isEmpty
        ? AppRoute.otpVerification.path
        : '${AppRoute.otpVerification.path}?phone=${Uri.encodeQueryComponent(phone)}';
    context.go(route);
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

          if (isSmall) {
            return Container(
              decoration: const BoxDecoration(
                gradient: AppGradients.backgroundGradient,
              ),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: _MobileLoginForm(
                        state: state,
                        controller: controller,
                        phoneCtrl: _phoneCtrl,
                        passwordCtrl: _passwordCtrl,
                        obscurePassword: _obscurePassword,
                        onVerifyPhone: _goToOtpVerification,
                        toggleObscure: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return _DesktopLoginForm(
            state: state,
            controller: controller,
            phoneCtrl: _phoneCtrl,
            passwordCtrl: _passwordCtrl,
            obscurePassword: _obscurePassword,
            onVerifyPhone: _goToOtpVerification,
            toggleObscure: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
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
    required this.onVerifyPhone,
  });

  final LoginState state;
  final LoginController controller;
  final TextEditingController phoneCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final VoidCallback toggleObscure;
  final VoidCallback onVerifyPhone;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/modula.svg',
                width: 88,
                height: 88,
              ),
              const SizedBox(height: 16),
              Text(
                'Login to Modula',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        LoginFormContent(
          state: state,
          phoneCtrl: phoneCtrl,
          passwordCtrl: passwordCtrl,
          obscurePassword: obscurePassword,
          onToggleObscure: toggleObscure,
          onLogin: () {
            controller.login(phoneCtrl.text.trim(), passwordCtrl.text.trim());
          },
          onSignup: () {
            context.go(AppRoute.signup.path);
          },
          onVerifyPhone: onVerifyPhone,
          useFramedInputs: true,
          phoneHintText: 'your phone number',
          passwordHintText: 'your password',
          buttonLabel: 'Log in',
          signupLabel: 'Sign up',
          signupPromptText: 'Don’t have an account ?',
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
    required this.onVerifyPhone,
  });

  final LoginState state;
  final LoginController controller;
  final TextEditingController phoneCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final VoidCallback toggleObscure;
  final VoidCallback onVerifyPhone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _DesktopBrandPanel()),
        Expanded(
          child: ColoredBox(
            color: const Color(0xFFF5F5F5),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 72,
                  vertical: 48,
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: _DesktopFormPanel(
                      state: state,
                      controller: controller,
                      phoneCtrl: phoneCtrl,
                      passwordCtrl: passwordCtrl,
                      obscurePassword: obscurePassword,
                      onVerifyPhone: onVerifyPhone,
                      toggleObscure: toggleObscure,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopBrandPanel extends StatelessWidget {
  const _DesktopBrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.loginDesktopBrandGradient,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/modula.svg',
              width: 186,
              height: 186,
            ),
            const SizedBox(height: 24),
            Text(
              'Modula',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopFormPanel extends StatelessWidget {
  const _DesktopFormPanel({
    required this.state,
    required this.controller,
    required this.phoneCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.toggleObscure,
    required this.onVerifyPhone,
  });

  final LoginState state;
  final LoginController controller;
  final TextEditingController phoneCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final VoidCallback toggleObscure;
  final VoidCallback onVerifyPhone;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Log into Modula',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: const Color(0xFF3E3E42),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 32),
        LoginFormContent(
          state: state,
          phoneCtrl: phoneCtrl,
          passwordCtrl: passwordCtrl,
          obscurePassword: obscurePassword,
          onToggleObscure: toggleObscure,
          onLogin: () {
            controller.login(phoneCtrl.text.trim(), passwordCtrl.text.trim());
          },
          onSignup: () {
            context.go(AppRoute.signup.path);
          },
          onVerifyPhone: onVerifyPhone,
          showDesktopFieldLabels: true,
          phoneHintText: 'your phone number',
          passwordHintText: 'your password',
          showForgotPasswordHint: true,
          buttonLabel: 'Log in',
          signupLabel: 'Sign up',
          signupPromptText: 'Don’t have an account ?',
        ),
      ],
    );
  }
}
