import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/presentation/viewmodels/empresa_viewmodel.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';
import 'package:workia/providers/locale_provider.dart';
import 'package:workia/features/auth/presentation/viewmodels/register_viewmodel.dart';
import 'package:workia/features/auth/presentation/views/register_company_screen.dart';

/// Pantalla de Registro refactorizada con MVVM.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({
    super.key,
    this.isAdminCreation = false,
    this.empresaId,
  });

  final bool isAdminCreation;
  final String? empresaId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => RegisterViewModel(
        usuariosVM: ctx.read<UsuariosViewModel>(),
        empresaVM: ctx.read<EmpresaViewModel>(),
        sessionProvider: ctx.read<UserSessionProvider>(),
        localeProvider: ctx.read<LocaleProvider>(),
      ),
      child: _RegisterContent(
        isAdminCreation: isAdminCreation,
        empresaId: empresaId,
      ),
    );
  }
}

class _RegisterContent extends StatefulWidget {
  const _RegisterContent({required this.isAdminCreation, this.empresaId});

  final bool isAdminCreation;
  final String? empresaId;

  @override
  State<_RegisterContent> createState() => _RegisterContentState();
}

class _RegisterContentState extends State<_RegisterContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<RegisterViewModel>();
    final t = AppLocalizations.of(context)!;

    final result = await vm.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      confirmPassword: _confirmController.text.trim(),
      empresaIdParam: widget.empresaId,
      isAdminCreation: widget.isAdminCreation,
    );

    if (!mounted) return;

    if (result.success) {
      if (result.requiresCompanyRegistration && result.newUser != null) {
        // Navegar a registro de empresa
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RegisterCompanyScreen(
              usuario: result.newUser!,
              password: result.password!,
            ),
          ),
        );
      } else {
        // Éxito final
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.accountCreatedSuccessMessage)));
        if (widget.isAdminCreation) {
          Navigator.of(context).pop();
        } else {
          context.go('/login');
        }
      }
    } else {
      // Manejo de errores
      String msg = result.error ?? t.unexpectedError('Unknown');
      if (result.error == 'passwords_do_not_match') {
        msg = t.passwordsDoNotMatchError;
      }
      if (result.error == 'email_already_registered') {
        msg = t.emailAlreadyRegisteredError;
      }
      if (result.error == 'required_error') {
        msg = t.requiredError;
      }
      if (result.error == 'invalid_company_id') {
        msg = t.invalidCompanyIdError;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterViewModel>();
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.registerTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.isAdminCreation) {
              Navigator.of(context).pop();
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t.createAccountTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: t.nameLabel,
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) => value != null && value.isNotEmpty
                          ? null
                          : t.requiredError,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: t.emailFieldLabel,
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value != null && value.contains('@')
                          ? null
                          : t.invalidEmailError,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: t.passwordLabel,
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) => value != null && value.length >= 3
                          ? null
                          : t.minimumCharactersError,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _confirmController,
                      decoration: InputDecoration(
                        labelText: t.confirmPasswordLabel,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (value) => value != null && value.length >= 3
                          ? null
                          : t.minimumCharactersError,
                    ),
                    const SizedBox(height: 12),

                    // Rol (Solo si es creación interna por admin)
                    if (widget.isAdminCreation)
                      DropdownButtonFormField<String>(
                        value: vm.role,
                        decoration: InputDecoration(
                          labelText: t.userProfileLabel,
                          prefixIcon: const Icon(Icons.badge),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'PERF_ADMIN',
                            child: Text(t.administratorRole),
                          ),
                          DropdownMenuItem(
                            value: 'PERF_FIN',
                            child: Text(t.financeRole),
                          ),
                          DropdownMenuItem(
                            value: 'PERF_TEC',
                            child: Text(t.technicianRole),
                          ),
                        ],
                        onChanged: vm.setRole,
                      ),

                    const SizedBox(height: 12),

                    // Idioma
                    DropdownButtonFormField<String>(
                      value: vm.idioma,
                      decoration: InputDecoration(
                        labelText: t.languageLabel,
                        prefixIcon: const Icon(Icons.language),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'es',
                          child: Text(t.spanishLanguage),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(t.englishLanguage),
                        ),
                      ],
                      onChanged: vm.setIdioma,
                    ),

                    const SizedBox(height: 16),

                    if (vm.error != null) ...[
                      Text(
                        // Si es un error raw de firebase se mostrará tal cual, idealmente mapear todos
                        vm.error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                    ],

                    ElevatedButton(
                      onPressed: vm.isLoading ? null : _register,
                      child: vm.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              vm.role == 'PERF_ADMIN' && !widget.isAdminCreation
                                  ? t.nextButton
                                  : t.registerButtonLabel,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
