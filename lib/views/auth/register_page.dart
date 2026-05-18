import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/presentation/viewmodels/empresa_viewmodel.dart';
import 'package:workia/models/usuario.dart';

import 'package:workia/views/auth/register_company_page.dart';
import 'package:workia/l10n/app_localizations.dart';

import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workia/providers/locale_provider.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';

/// Página de registro que permite a los usuarios crear una cuenta nueva.
/// El formulario recoge el nombre completo, correo electrónico,
/// contraseña y rol.  Los datos se almacenan en el
/// controlador global de usuarios para persistirlos durante la sesión.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.isAdminCreation = false, this.empresaId});

  final bool isAdminCreation;
  final String? empresaId;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String _role = 'PERF_ADMIN'; // Por defecto admin
  String _idioma = 'es'; // Por defecto español
  bool _isLoading = false;
  String? _error;
  String? _selectedCompanyId;

  late UsuariosViewModel _usuariosVM;

  @override
  void initState() {
    super.initState();
    // Si ya viene una empresa predefinida (creación interna), la seleccionamos
    if (widget.empresaId != null) {
      _selectedCompanyId = widget.empresaId;
    } else {
      // _loadCompanies(); // No necesario si solo registramos admins que crean empresas
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Normaliza el string de idioma seleccionado a 'es' o 'en'.
  /// Acepta variantes como 'en_US', 'en-ingles', 'english', 'es_ES',
  /// 'es-espanol', 'spanish'. Cualquier otro valor cae en espa?ol.
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

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    // Capturar Navigator y ScaffoldMessenger antes de cualquier await para evitar
    // usar BuildContext después de un posible desmontaje.
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final confirm = _confirmController.text.trim();

    // Verificar si el correo ya existe mediante el viewmodel.
    bool exists;
    try {
      exists = await _usuariosVM.emailExistente(email);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            e.message ?? AppLocalizations.of(context)!.emailVerificationError;
        _isLoading = false;
      });
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.unexpectedEmailVerificationError;
        _isLoading = false;
      });
      return;
    }

    if (!mounted) return;
    if (exists) {
      setState(() {
        _error = AppLocalizations.of(context)!.emailAlreadyRegisteredError;
        _isLoading = false;
      });
      return;
    }

    if (password != confirm) {
      setState(() {
        _error = AppLocalizations.of(context)!.passwordsDoNotMatchError;
        _isLoading = false;
      });
      return;
    }

    // Determinar el ID de empresa:
    // 1. Si viene por parámetro (creación interna), usar ese.
    // 2. Si se ingresó manualmente, usar ese.
    // 3. Si es admin público, se asignará al crear la empresa.
    final targetEmpresaId = widget.empresaId ?? _selectedCompanyId ?? '';

    // Si NO es administrador y NO es creación interna, validar que la empresa exista
    if (_role != 'PERF_ADMIN' && widget.empresaId == null) {
      if (targetEmpresaId.isEmpty) {
        setState(() {
          _error = AppLocalizations.of(context)!.requiredError;
          _isLoading = false;
        });
        return;
      }

      // Validar existencia de la empresa
      final empresaVM = context.read<EmpresaViewModel>();
      final existe = await empresaVM.existeEmpresa(targetEmpresaId);
      if (!mounted) return;
      if (!existe) {
        setState(() {
          _error = AppLocalizations.of(context)!.invalidCompanyIdError;
          _isLoading = false;
        });
        return;
      }
    }

    // Obtener ID del usuario actual si existe (para auditoría)
    String currentUserId = '';
    try {
      currentUserId = context.read<UserSessionProvider>().userId;
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

    // Si es administrador Y NO es una creación interna (es registro público),
    // navegar a la pantalla de registro de empresa.
    if (_role == 'PERF_ADMIN' && !widget.isAdminCreation) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      // Ajustar el idioma de la app antes de navegar al registro de empresa.
      context.read<LocaleProvider>().setLocale(
        Locale(_normalizeLocale(_idioma)),
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              RegisterCompanyPage(usuario: newUser, password: password),
        ),
      );
      return;
    }

    try {
      // Intentar registrar el usuario utilizando Firebase Auth y Firestore.
      await _usuariosVM.agregar(newUser, password);
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Aplicar el idioma seleccionado para la nueva sesiИn.
      context.read<LocaleProvider>().setLocale(
        Locale(_normalizeLocale(_idioma)),
      );

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.accountCreatedSuccessMessage,
          ),
        ),
      );

      // Navegación condicional basada en isAdminCreation
      if (widget.isAdminCreation) {
        Navigator.of(context).pop(); // Volver a la lista de usuarios
      } else {
        context.go('/login'); // Volver al login
      }
    } on FirebaseAuthException catch (e) {
      // Si hay un error con Firebase (p.ej. contraseña débil, correo inválido)
      if (!mounted) return;
      setState(() {
        _error =
            e.message ?? AppLocalizations.of(context)!.userRegistrationError;
        _isLoading = false;
      });
    } catch (e) {
      // Cualquier otro error se muestra de forma genérica.
      if (!mounted) return;
      setState(() {
        // Mostrar el mensaje de error inesperado incluyendo el texto original.
        _error = AppLocalizations.of(context)!.unexpectedError(e.toString());
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el viewmodel desde Provider cuando se construye la vista
    _usuariosVM = context.watch<UsuariosViewModel>();
    return Scaffold(
      appBar: AppBar(
        // Usar traducción para el título de la página de registro
        title: Text(AppLocalizations.of(context)!.registerTitle),
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
                    // Texto de encabezado para crear una nueva cuenta
                    Text(
                      AppLocalizations.of(context)!.createAccountTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.nameLabel,
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) => value != null && value.isNotEmpty
                          ? null
                          : AppLocalizations.of(context)!.requiredError,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        )!.emailFieldLabel,
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value != null && value.contains('@')
                          ? null
                          : AppLocalizations.of(context)!.invalidEmailError,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.passwordLabel,
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) => value != null && value.length >= 3
                          ? null
                          : AppLocalizations.of(
                              context,
                            )!.minimumCharactersError,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        )!.confirmPasswordLabel,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (value) => value != null && value.length >= 3
                          ? null
                          : AppLocalizations.of(
                              context,
                            )!.minimumCharactersError,
                    ),
                    const SizedBox(height: 12),

                    // Dropdown de perfil eliminado, forzado a PERF_ADMIN pero ahora lo restauramos condicionalmente
                    if (widget.isAdminCreation)
                      DropdownButtonFormField<String>(
                        initialValue: _role,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(
                            context,
                          )!.userProfileLabel,
                          prefixIcon: const Icon(Icons.badge),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'PERF_ADMIN',
                            child: Text(
                              AppLocalizations.of(context)!.administratorRole,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'PERF_FIN',
                            child: Text(
                              AppLocalizations.of(context)!.financeRole,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'PERF_TEC',
                            child: Text(
                              AppLocalizations.of(context)!.technicianRole,
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _role = val;
                            });
                          }
                        },
                      ),
                    const SizedBox(height: 12),

                    // Selector de empresa eliminado
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _idioma,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.languageLabel,
                        prefixIcon: const Icon(Icons.language),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'es',
                          child: Text(
                            AppLocalizations.of(context)!.spanishLanguage,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(
                            AppLocalizations.of(context)!.englishLanguage,
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _idioma = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _role == 'PERF_ADMIN'
                                  ? AppLocalizations.of(context)!.nextButton
                                  : AppLocalizations.of(
                                      context,
                                    )!.registerButtonLabel,
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
