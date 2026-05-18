import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/widgets/language_selector.dart';
import 'package:workia/utils/ui_utils.dart';

import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/presentation/viewmodels/empresa_viewmodel.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/presentation/viewmodels/gastos_viewmodel.dart';
import 'package:workia/providers/locale_provider.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';

/// A simple login page that demonstrates roleâ€‘based navigation.
///
/// Users enter an email and password.  Based on the text of the
/// email (containing 'admin', 'fin' or 'tec') a role is assigned.
/// After logging in the app navigates to [MainApp] and only shows
/// the pages permitted for that role.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;
  String? _error;
  bool _isLoading = false;

  // Referencia al ViewModel de usuarios.  Se obtendra en
  // initState mediante Provider.  No se inicializa aqui­ porque
  // depende del contexto de Flutter.
  late UsuariosViewModel _usuariosVM;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Obtener el viewmodel de usuarios tan pronto exista el Provider.
    _usuariosVM = context.read<UsuariosViewModel>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Maps each role to a list of permitted page keys.
  final Map<String, List<String>> roleScreens = {
    'PERF_ADMIN': [
      'agenda',
      'clientes',
      'mis_trabajos',
      'gastos',
      'balance',
      'usuarios',
      'configuracion',
    ],
    'PERF_FIN': ['gastos', 'balance'],
    'PERF_TEC': ['agenda', 'mis_trabajos'],
  };

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (_isLoading) return;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.credentialsError);
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Autenticamos utilizando el viewmodel. Esperamos el resultado y
      // verificamos que el widget siga montado antes de usar el contexto.
      final user = await _usuariosVM.login(email, password);
      if (!mounted) return;
      if (user == null) {
        setState(() => _error = AppLocalizations.of(context)!.authError);
        return;
      }

      final role = user.perfilId;
      final userName = user.nombre;
      final empresaId = user.idEmpresa;

      // Ajustar el idioma de la app segun el valor guardado en Firebase.
      final localeCode = _normalizeLocale(user.idioma);
      context.read<LocaleProvider>().setLocale(Locale(localeCode));

      // Actualizamos el provider en memoria para uso inmediato
      context.read<UserSessionProvider>().setSession(
        empresaId: empresaId,
        userId: user.id,
        userName: userName,
        userRole: role,
      );

      // Precargar datos basicos en segundo plano para que al entrar a modulos
      // como Balance/Agenda ya estan listos (sin bloquear la navegacion).
      Future.microtask(() {
        if (!mounted) return;
        // ignore: unawaited_futures
        context.read<EmpresaViewModel>().cargarEmpresa(empresaId);
        // ignore: unawaited_futures
        context.read<UsuariosViewModel>().cargarUsuarios(empresaId);
        // ignore: unawaited_futures
        context.read<ClientesViewModel>().cargarClientes(empresaId);
        // ignore: unawaited_futures
        context.read<TrabajosViewModel>().cargarTrabajos(empresaId);
        // ignore: unawaited_futures
        context.read<TrabajosAsignadosViewModel>().cargarTrabajosAsignados(
              empresaId,
            );
        // ignore: unawaited_futures
        context.read<GastosViewModel>().cargarTipos(empresaId);
      });

      // Navegar a home pasando credenciales como 'extra'
      context.go(
        '/home',
        extra: {
          'role': role,
          'userName': userName,
          'userId': user.id,
          'empresaId': empresaId,
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  // Display the Workia logo above the login heading.
                  Image.asset(
                    'assets/images/workia_logo.png',
                    width:
                        MediaQuery.of(context).size.width *
                        0.6, // 60% del ancho
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.loginTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.emailLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.passwordLabel,

                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscure = !_obscure);
                        },
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(AppLocalizations.of(context)!.loginButton),
                  ),

                  const SizedBox(height: 12),
                  // Registration link
                  TextButton(
                    onPressed: () {
                      // Navegar a la pÃ¡gina de registro utilizando go_router
                      context.go('/register');
                    },
                    child: Text(AppLocalizations.of(context)!.registerLink),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(top: 40, left: 16, child: LanguageSelector()),
        ],
      ),
    );
  }

  /// Normaliza un string de idioma proveniente de Firebase a 'es' o 'en'.
  /// Soporta variantes como 'en', 'en_US', 'en-ingles', 'english', 'es',
  /// 'es_ES', 'es-espanol', 'spanish'. Cualquier otro valor cae en español.
  String _normalizeLocale(String raw) {
    final code = raw.trim().toLowerCase();
    if (code.isEmpty) return 'es';
    if (code.startsWith('en') || code.contains('ingl')) return 'en';
    if (code.startsWith('es') ||
        code.contains('spanish') ||
        code.contains('espa')) {
      return 'es';
    }
    return 'es';
  }
}
