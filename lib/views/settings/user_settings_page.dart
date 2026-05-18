import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/widgets/language_selector.dart';
import 'package:provider/provider.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';
import 'package:workia/presentation/viewmodels/problemas_viewmodel.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/presentation/viewmodels/gastos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/features/activities/presentation/viewmodels/actividades_viewmodel.dart';

/// Page that shows the current user's information and allows
/// logging out of the application.  The user name and role
/// determine the avatar initials and the role label.  Pressing
/// the logout button will clear the navigation stack and return
/// to the login page.
class UserSettingsPage extends StatelessWidget {
  const UserSettingsPage({
    super.key,
    required this.userName,
    required this.role,
  });

  /// Display name of the current user.  For example "Admin",
  /// "Sandra Finanzas" or "Juan Pérez".
  final String userName;

  /// Internal role identifier such as PERF_ADMIN, PERF_FIN or
  /// PERF_TEC.  This is used to derive a human‑readable role
  /// label displayed on this page.
  final String role;

  /// Returns the initials of the user name by taking the first
  /// letter of the first and last words.  If there is only one
  /// word it returns the first letter of that word.
  String _initials() {
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Maps the internal role code to a human‑readable label.
  String _roleLabel(BuildContext context) {
    switch (role) {
      case 'PERF_ADMIN':
        return AppLocalizations.of(context)!.roleAdmin;
      case 'PERF_FIN':
        return AppLocalizations.of(context)!.roleFinance;
      case 'PERF_TEC':
        return AppLocalizations.of(context)!.roleTech;
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.userSettingsTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  _initials(),
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                userName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                _roleLabel(context),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(AppLocalizations.of(context)!.nameLabel),
                    subtitle: Text(userName),
                  ),
                  ListTile(
                    leading: const Icon(Icons.badge),
                    title: Text(AppLocalizations.of(context)!.roleLabel),
                    subtitle: Text(_roleLabel(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.language),
                title: Text(AppLocalizations.of(context)!.languageLabel),
                trailing: const LanguageSelector(),
              ),
            ),
            // Para roles de finanzas o técnico, el historial y registro de
            // problemas se acceden ahora desde el icono de notificaciones
            // del AppBar en lugar de un botón dedicado en esta página.
            // Si se desea ofrecer acceso rápido al historial aquí en el futuro,
            // se podría añadir un botón similar.  Por ahora no se muestra
            // ningún botón específico de problemas en esta sección.
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: Text(AppLocalizations.of(context)!.logoutButton),
                onPressed: () {
                  // Limpiar sesión
                  context.read<UserSessionProvider>().clearSession();

                  // Limpiar ViewModels
                  context.read<ProblemasViewModel>().limpiar();
                  context.read<ClientesViewModel>().limpiar();
                  context.read<TrabajosViewModel>().limpiar();
                  context.read<TrabajosAsignadosViewModel>().limpiar();
                  context.read<GastosViewModel>().limpiar();
                  context.read<UsuariosViewModel>().limpiar();
                  context.read<ActividadesViewModel>().limpiar();

                  // Navegar a la pantalla de inicio de sesión utilizando go_router.
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
