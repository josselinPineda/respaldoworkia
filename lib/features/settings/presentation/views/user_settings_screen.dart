import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';
import 'package:workia/features/activities/presentation/viewmodels/actividades_viewmodel.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/gastos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/problemas_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/widgets/language_selector.dart';

class UserSettingsScreen extends StatelessWidget {
  const UserSettingsScreen({
    super.key,
    required this.userName,
    required this.role,
  });

  final String userName;
  final String role;

  String _initials() {
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

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

  void _logout(BuildContext context) {
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

    // Navegar a Login
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.userSettingsTitle)),
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
                    title: Text(t.nameLabel),
                    subtitle: Text(userName),
                  ),
                  ListTile(
                    leading: const Icon(Icons.badge),
                    title: Text(t.roleLabel),
                    subtitle: Text(_roleLabel(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.language),
                title: Text(t.languageLabel),
                trailing: const LanguageSelector(),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: Text(t.logoutButton),
                onPressed: () => _logout(context),
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
