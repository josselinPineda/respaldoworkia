import 'package:flutter/material.dart';
import 'package:workia/models/usuario.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';
import 'package:workia/providers/locale_provider.dart';

/// Resultado del proceso de login.
class LoginResult {
  final bool success;
  final String? error;
  final Usuario? user;

  const LoginResult._({required this.success, this.error, this.user});

  factory LoginResult.success(Usuario user) =>
      LoginResult._(success: true, user: user);

  factory LoginResult.failure(String error) =>
      LoginResult._(success: false, error: error);
}

/// ViewModel para la pantalla de Login.
///
/// Contiene la lógica de autenticación, validación y configuración de sesión.
class LoginViewModel extends ChangeNotifier {
  final UsuariosViewModel usuariosVM;
  final UserSessionProvider sessionProvider;
  final LocaleProvider localeProvider;

  LoginViewModel({
    required this.usuariosVM,
    required this.sessionProvider,
    required this.localeProvider,
  });

  // ========== ESTADO ==========

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  String? get error => _error;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ========== PERMISOS POR ROL ==========

  static const Map<String, List<String>> roleScreens = {
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

  List<String> screensForRole(String role) => roleScreens[role] ?? [];

  // ========== ACCIONES ==========

  Future<LoginResult> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _error = 'credentials_error';
      notifyListeners();
      return LoginResult.failure('credentials_error');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await usuariosVM.login(email, password);

      if (user == null) {
        _isLoading = false;
        _error = 'auth_error';
        notifyListeners();
        return LoginResult.failure('auth_error');
      }

      // Configurar idioma
      final localeCode = _normalizeLocale(user.idioma);
      localeProvider.setLocale(Locale(localeCode));

      // Guardar sesión
      sessionProvider.setSession(
        empresaId: user.idEmpresa,
        userId: user.id,
        userName: user.nombre,
        userRole: user.perfilId,
      );

      _isLoading = false;
      notifyListeners();
      return LoginResult.success(user);
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return LoginResult.failure(e.toString());
    }
  }

  // ========== HELPERS ==========

  /// Normaliza un string de idioma a 'es' o 'en'.
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
