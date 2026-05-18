import 'package:flutter/material.dart';
import 'package:workia/models/usuario.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/presentation/viewmodels/empresa_viewmodel.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';
import 'package:workia/providers/locale_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Resultado del proceso de registro.
class RegisterResult {
  final bool success;
  final String? error;
  final bool requiresCompanyRegistration;
  final Usuario? newUser;
  final String? password; // Necesario para login automático o paso siguiente

  const RegisterResult._({
    required this.success,
    this.error,
    this.requiresCompanyRegistration = false,
    this.newUser,
    this.password,
  });

  factory RegisterResult.success({
    required Usuario user,
    required String password,
    bool requiresCompanyRegistration = false,
  }) => RegisterResult._(
    success: true,
    newUser: user,
    password: password,
    requiresCompanyRegistration: requiresCompanyRegistration,
  );

  factory RegisterResult.failure(String error) =>
      RegisterResult._(success: false, error: error);
}

/// ViewModel para la pantalla de Registro.
class RegisterViewModel extends ChangeNotifier {
  final UsuariosViewModel usuariosVM;
  final EmpresaViewModel empresaVM;
  final UserSessionProvider sessionProvider;
  final LocaleProvider localeProvider;

  RegisterViewModel({
    required this.usuariosVM,
    required this.empresaVM,
    required this.sessionProvider,
    required this.localeProvider,
  });

  // ========== ESTADO ==========

  bool _isLoading = false;
  String? _error;
  String _role = 'PERF_ADMIN';
  String _idioma = 'es';

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get role => _role;
  String get idioma => _idioma;

  void setRole(String? value) {
    if (value != null) {
      _role = value;
      notifyListeners();
    }
  }

  void setIdioma(String? value) {
    if (value != null) {
      _idioma = value;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ========== ACCIONES ==========

  Future<RegisterResult> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String? empresaIdParam, // ID empresa si viene por parámetro
    required bool isAdminCreation, // Si es creación interna
  }) async {
    if (password != confirmPassword) {
      return RegisterResult.failure('passwords_do_not_match');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Verificar si el correo existe
      final exists = await usuariosVM.emailExistente(email);
      if (exists) {
        _isLoading = false;
        return RegisterResult.failure('email_already_registered');
      }

      // 2. Determinar ID Empresa
      // Si es admin público (no creación interna), el ID se asigna al crear empresa después.
      String targetEmpresaId = empresaIdParam ?? '';

      // Si NO es admin y NO es creación interna... (caso raro en registro público salvo invitación)
      // En la lógica original valida existencia de empresa si no es admin.
      if (_role != 'PERF_ADMIN' && empresaIdParam == null) {
        // En registro público simplificado asumimos que si no es admin, no puede registrarse
        // sin un ID de empresa, pero mantendremos la lógica original.
        if (targetEmpresaId.isEmpty) {
          _isLoading = false;
          return RegisterResult.failure('required_error');
        }

        final existe = await empresaVM.existeEmpresa(targetEmpresaId);
        if (!existe) {
          _isLoading = false;
          return RegisterResult.failure('invalid_company_id');
        }
      }

      // 3. Crear objeto Usuario
      String currentUserId = '';
      try {
        currentUserId = sessionProvider.userId;
      } catch (_) {}

      final newUser = Usuario(
        nombre: name,
        email: email,
        idEmpresa: targetEmpresaId,
        perfilId: _role,
        idioma: _idioma,
        creadoPor: currentUserId,
        actualizadoPor: currentUserId,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
      );

      // 4. Lógica condicional
      // Si es ADMIN y es registro público -> Ir a registrar empresa
      if (_role == 'PERF_ADMIN' && !isAdminCreation) {
        _isLoading = false;
        notifyListeners();
        // Ajustar locale antes de continuar
        localeProvider.setLocale(Locale(_normalizeLocale(_idioma)));

        return RegisterResult.success(
          user: newUser,
          password: password,
          requiresCompanyRegistration: true,
        );
      }

      // 5. Registrar en Firebase/Firestore
      await usuariosVM.agregar(newUser, password);

      _isLoading = false;
      notifyListeners();

      // Ajustar locale
      localeProvider.setLocale(Locale(_normalizeLocale(_idioma)));

      return RegisterResult.success(
        user: newUser,
        password: password,
        requiresCompanyRegistration: false,
      );
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = e.message;
      notifyListeners();
      return RegisterResult.failure(e.message ?? 'user_registration_error');
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return RegisterResult.failure(e.toString());
    }
  }

  // ========== HELPERS ==========

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
