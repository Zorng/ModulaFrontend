import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_gradient.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  ProviderSubscription<LoginState>? _loginSub;
  String? _lastRoute;

  @override
  void initState() {
    super.initState();
    _loginSub = ref.listenManual<LoginState>(
      loginControllerProvider,
      (previous, next) {
        final user = next.user;
        if (!mounted || user == null) return;
        final route = switch (user.role.toLowerCase()) {
          'admin' => AppRoute.adminPortal.path,
          'cashier' => AppRoute.cashierPortal.path,
          _ => AppRoute.adminPortal.path,
        };
        if (_lastRoute == route) return;
        _lastRoute = route;
        context.go(route);
      },
    );
  }

  @override
  void dispose() {
    _loginSub?.close();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.backgroundGradient,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppGradients.textGradient.createShader(bounds),
              child: Text(
                "Modula",
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Colors.white),
                textAlign: TextAlign.left,
              ),
            ),
            Text(
              "Login to Modula",
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 28,),
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordCtrl,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility, 
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 16),
            if (state.error != null)
              Text(
                state.error!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: state.isLoading
                  ? null
                  : () {
                      controller.login(
                        _usernameCtrl.text.trim(),
                        _passwordCtrl.text.trim(),
                      );
                    },
              child: state.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
            ),
            Consumer(builder: (context, ref, _) {
              if(state.user != null) {
                return Text("Welcome ${state.user?.name}"); 
              }
                return Text("login to continue");}
              )
          ],
          ),
        ),
      ),
    );
  }
}
