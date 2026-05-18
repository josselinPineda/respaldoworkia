import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/widgets/language_selector.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';
import 'package:workia/providers/locale_provider.dart';
// Importamos el nuevo viewModel
import 'package:workia/features/auth/presentation/viewmodels/login_viewmodel.dart';

/// Pantalla de Login refactorizada siguiendo MVVM.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => LoginViewModel(
        usuariosVM: ctx.read<UsuariosViewModel>(),
        sessionProvider: ctx.read<UserSessionProvider>(),
        localeProvider: ctx.read<LocaleProvider>(),
      ),
      child: const _LoginContent(),
    );
  }
}

class _LoginContent extends StatefulWidget {
  const _LoginContent();

  @override
  State<_LoginContent> createState() => _LoginContentState();
}

class _LoginContentState extends State<_LoginContent> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final vm = context.read<LoginViewModel>();
    final t = AppLocalizations.of(context)!;

    // Validar campos vacíos localmente para feedback inmediato si se desea,
    // aunque el VM también valida.
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.credentialsError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await vm.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (result.success && result.user != null) {
      final user = result.user!;
      // Navegar a home
      context.go(
        '/home',
        extra: {
          'role': user.perfilId,
          'userName': user.nombre,
          'userId': user.id,
          'empresaId': user.idEmpresa,
        },
      );
    } else {
      String msg = t.authError;
      if (result.error == 'credentials_error') msg = t.credentialsError;
      // Mostrar error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/workia_logo.png',
                    width: MediaQuery.of(context).size.width * 0.6,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),

                  // Título
                  Text(
                    t.loginTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: t.emailLabel,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Password
                  TextField(
                    controller: _passwordController,
                    obscureText: vm.obscurePassword,
                    decoration: InputDecoration(
                      labelText: t.passwordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          vm.obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: vm.togglePasswordVisibility,
                      ),
                    ),
                    onSubmitted: (_) => _login(),
                  ),

                  const SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
                    onPressed: vm.isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: vm.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(t.loginButton),
                  ),

                  const SizedBox(height: 12),

                  // Register Link
                  TextButton(
                    onPressed: () {
                      context.go('/register');
                    },
                    child: Text(t.registerLink),
                  ),
                ],
              ),
            ),
          ),

          // Language Selector
          const Positioned(top: 40, left: 16, child: LanguageSelector()),
        ],
      ),
    );
  }
}
