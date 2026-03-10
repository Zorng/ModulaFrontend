import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_buttons.dart';
import 'package:modular_pos/core/theme/app_gradient.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _dateOfBirthCtrl = TextEditingController();
  bool _obscurePassword = true;
  String? _selectedGender;
  static final RegExp _e164PhonePattern = RegExp(r'^\+[1-9]\d{7,14}$');

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _dateOfBirthCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = ref.read(loginControllerProvider.notifier);
    final phone = _normalizePhone(_phoneCtrl.text);
    final password = _passwordCtrl.text.trim();
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final dateOfBirth = _dateOfBirthCtrl.text.trim();
    final gender = (_selectedGender ?? '').trim();
    if (phone.isEmpty ||
        password.isEmpty ||
        firstName.isEmpty ||
        lastName.isEmpty ||
        gender.isEmpty ||
        dateOfBirth.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Phone, password, full name, gender, and date of birth are required.',
          ),
        ),
      );
      return;
    }
    if (!_e164PhonePattern.hasMatch(phone)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Phone must be in E.164 format, for example +85512345678.',
          ),
        ),
      );
      return;
    }

    await controller.registerAccount(
      phone: phone,
      password: password,
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      dateOfBirth: dateOfBirth,
    );
    var state = ref.read(loginControllerProvider);
    if (state.error != null) return;

    await controller.sendRegistrationOtp(phone: phone);
    state = ref.read(loginControllerProvider);
    if (state.error != null) return;

    if (!mounted) return;
    context.go(
      '${AppRoute.otpVerification.path}?phone=${Uri.encodeQueryComponent(phone)}',
    );
  }

  String _normalizePhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate =
        DateTime.tryParse(_dateOfBirthCtrl.text.trim()) ??
        DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _dateOfBirthCtrl.text =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = AppBreakpoints.isSmall(constraints.maxWidth);

        if (isSmall) {
          return Scaffold(
            appBar: AppBar(title: const Text('Create account')),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _SignupFormContent(
                    state: state,
                    phoneCtrl: _phoneCtrl,
                    passwordCtrl: _passwordCtrl,
                    firstNameCtrl: _firstNameCtrl,
                    lastNameCtrl: _lastNameCtrl,
                    dateOfBirthCtrl: _dateOfBirthCtrl,
                    selectedGender: _selectedGender,
                    obscurePassword: _obscurePassword,
                    onToggleObscure: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    onGenderChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                    onPickDateOfBirth: _pickDateOfBirth,
                    onSubmit: _submit,
                    onBackToLogin: () {
                      context.go(AppRoute.login.path);
                    },
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.loginDesktopBrandGradient,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Card(
                    color: Colors.white,
                    elevation: 12,
                    shadowColor: Colors.black.withValues(alpha: 0.10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(30, 22, 30, 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Create account',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(
                                            color: const Color(0xFF3E3E42),
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Set up your account to continue with Modula.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: const Color(0xFF6B6B70),
                                          ),
                                    ),
                                  ],
                                ),
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
                          const SizedBox(height: 28),
                          _SignupFormContent(
                            state: state,
                            phoneCtrl: _phoneCtrl,
                            passwordCtrl: _passwordCtrl,
                            firstNameCtrl: _firstNameCtrl,
                            lastNameCtrl: _lastNameCtrl,
                            dateOfBirthCtrl: _dateOfBirthCtrl,
                            selectedGender: _selectedGender,
                            obscurePassword: _obscurePassword,
                            useFramedInputs: true,
                            showBackToLogin: false,
                            onToggleObscure: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            onGenderChanged: (value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                            onPickDateOfBirth: _pickDateOfBirth,
                            onSubmit: _submit,
                            onBackToLogin: () {
                              context.go(AppRoute.login.path);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SignupFormContent extends StatelessWidget {
  const _SignupFormContent({
    required this.state,
    required this.phoneCtrl,
    required this.passwordCtrl,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.dateOfBirthCtrl,
    required this.selectedGender,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onGenderChanged,
    required this.onPickDateOfBirth,
    required this.onSubmit,
    required this.onBackToLogin,
    this.useFramedInputs = false,
    this.showBackToLogin = true,
  });

  final LoginState state;
  final TextEditingController phoneCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController dateOfBirthCtrl;
  final String? selectedGender;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final ValueChanged<String?> onGenderChanged;
  final Future<void> Function() onPickDateOfBirth;
  final Future<void> Function() onSubmit;
  final VoidCallback onBackToLogin;
  final bool useFramedInputs;
  final bool showBackToLogin;

  @override
  Widget build(BuildContext context) {
    final inputDecoration = _inputDecoration(useFramedInputs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: inputDecoration.copyWith(
            labelText: useFramedInputs ? null : 'Phone number',
            hintText: useFramedInputs ? 'your phone number' : null,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordCtrl,
          obscureText: obscurePassword,
          decoration: inputDecoration.copyWith(
            labelText: useFramedInputs ? null : 'Password',
            hintText: useFramedInputs ? 'your password' : null,
            suffixIcon: IconButton(
              onPressed: onToggleObscure,
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: firstNameCtrl,
          decoration: inputDecoration.copyWith(
            labelText: useFramedInputs ? null : 'First name',
            hintText: useFramedInputs ? 'your first name' : null,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: lastNameCtrl,
          decoration: inputDecoration.copyWith(
            labelText: useFramedInputs ? null : 'Last name',
            hintText: useFramedInputs ? 'your last name' : null,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: selectedGender,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 15,
            color: const Color(0xFF3E3E42),
          ),
          decoration: inputDecoration.copyWith(
            labelText: useFramedInputs ? null : 'Gender',
            hintText: useFramedInputs ? 'select gender' : null,
          ),
          items: const [
            DropdownMenuItem(value: 'MALE', child: Text('Male')),
            DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
            DropdownMenuItem(value: 'OTHER', child: Text('Other')),
          ],
          onChanged: state.isLoading ? null : onGenderChanged,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: dateOfBirthCtrl,
          readOnly: true,
          onTap: state.isLoading ? null : onPickDateOfBirth,
          decoration: inputDecoration.copyWith(
            labelText: useFramedInputs ? null : 'Date of birth',
            hintText: useFramedInputs ? 'YYYY-MM-DD' : null,
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
        ),
        const SizedBox(height: 16),
        if (state.error != null)
          Text(state.error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: AppButtons.primary(context),
            onPressed: state.isLoading ? null : onSubmit,
            child: state.isLoading
                ? const CircularProgressIndicator(strokeWidth: 2.5)
                : const Text('Create account and send OTP'),
          ),
        ),
        if (showBackToLogin) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: state.isLoading ? null : onBackToLogin,
              child: const Text('Back to login'),
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration(bool useFramedInputs) {
    if (!useFramedInputs) {
      return const InputDecoration();
    }

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
