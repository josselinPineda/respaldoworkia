import 'package:flutter/material.dart';
import 'package:workia/utils/ui_utils.dart';
import 'package:provider/provider.dart';
import 'package:workia/models/usuario.dart';
import 'package:workia/views/employees/user_edit_page.dart';
import 'package:workia/views/settings/user_settings_page.dart';
import 'package:workia/views/auth/register_page.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
// Importar dropdown_search para filtros con búsqueda.
import 'package:dropdown_search/dropdown_search.dart';
import 'package:workia/views/problems/problems_page.dart';
import 'package:workia/l10n/app_localizations.dart';

/// Page listing and managing users.  This version leverages
/// [UsersController] to store and search users.  Administrators
/// can create new users via a registration form and edit or
/// delete existing users.  All data remains in memory until a
/// backend integration is added.
class UsersPage extends StatefulWidget {
  const UsersPage({
    super.key,
    required this.userName,
    required this.role,
    required this.userId,
    required this.empresaId,
  });
  final String userName;
  final String role;
  final String userId;
  final String empresaId;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController _searchController = TextEditingController();
  // Variables para filtros
  bool _filtrosVisibles = false;
  // Mostrar únicamente usuarios activos por defecto
  String _estadoFiltro = 'Activos';
  String _rolFiltro = 'Todos';
  // Almacena la lista filtrada por búsqueda.  Se combinará con los filtros de estado y rol en build().
  // List<Usuario> _filteredUsers = []; // Removed: unused

  /// Construye el panel de filtros para la página de usuarios.  Se
  /// utiliza dentro de un AnimatedSwitcher para animar su aparición
  /// y desaparición.  Incluye filtros para estado (activo/inactivo) y
  /// rol/perfil.  La primera opción de cada lista debe ser 'Todos'.
  Widget _buildFilterPanel() {
    return Row(
      children: [
        Expanded(
          child: DropdownSearch<String>(
            items: (String filter, LoadProps? loadProps) => const [
              'Todos',
              'Activos',
              'Inactivos',
            ],
            selectedItem: _estadoFiltro == 'Todos' ? null : _estadoFiltro,
            decoratorProps: DropDownDecoratorProps(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.statusLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            popupProps: const PopupProps.menu(showSearchBox: true),
            onChanged: (String? value) {
              setState(() {
                _estadoFiltro = value ?? 'Todos';
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownSearch<String>(
            items: (String filter, LoadProps? loadProps) => const [
              'Todos',
              'PERF_ADMIN',
              'PERF_FIN',
              'PERF_TEC',
            ],
            selectedItem: _rolFiltro == 'Todos' ? null : _rolFiltro,
            decoratorProps: DropDownDecoratorProps(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.roleLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            popupProps: const PopupProps.menu(showSearchBox: true),
            onChanged: (String? value) {
              setState(() {
                _rolFiltro = value ?? 'Todos';
              });
            },
          ),
        ),
      ],
    );
  }

  /// Devuelve una etiqueta legible para el perfil dado.
  String _roleLabel(String perfilId) {
    switch (perfilId) {
      case 'PERF_ADMIN':
        return AppLocalizations.of(context)!.adminRole;
      case 'PERF_FIN':
        return AppLocalizations.of(context)!.financeRole;
      case 'PERF_TEC':
        return AppLocalizations.of(context)!.technicianRole;
      default:
        return perfilId;
    }
  }

  @override
  void initState() {
    super.initState();
    // Trigger rebuild on search text change
    _searchController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsuariosViewModel>().cargarUsuarios(widget.empresaId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Se eliminó _onSearchChanged porque el filtrado ahora es reactivo en el método build().

  /// Muestra un diálogo para ver problemas y reportar nuevos.  Este método
  /// ya no se utiliza porque la navegación a los problemas se centralizó
  /// en `ProblemsPage`.  Se mantiene como referencia y se ignora la
  /// advertencia de elemento no utilizado.

  String _initials() {
    final parts = widget.userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final usuarios = context.watch<UsuariosViewModel>().usuarios;
    final t = AppLocalizations.of(context)!;

    // Filter logic moved directly to build to ensure reactivity
    List<Usuario> displayList = List<Usuario>.from(usuarios);
    final query = _searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      displayList = displayList
          .where(
            (u) =>
                u.nombre.toLowerCase().contains(query) ||
                u.email.toLowerCase().contains(query) ||
                u.perfilId.toLowerCase().contains(query),
          )
          .toList();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.usersTitle),
        actions: [
          // Icono de notificaciones para ver y reportar problemas.
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Abrir la página de problemas para este usuario.
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProblemsPage(
                    userName: widget.userName,
                    role: widget.role,
                  ),
                ),
              );
            },
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserSettingsPage(
                    userName: widget.userName,
                    role: widget.role,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  _initials(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Búsqueda y filtros
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: t.searchUserPlaceholder,
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _filtrosVisibles ? Icons.filter_alt_off : Icons.filter_alt,
                  ),
                  tooltip: _filtrosVisibles
                      ? t.hideFiltersTooltip
                      : t.showFiltersTooltip,
                  onPressed: () {
                    setState(() {
                      _filtrosVisibles = !_filtrosVisibles;
                    });
                  },
                ),
              ],
            ),
            // Panel de filtros animado: utiliza AnimatedSwitcher para
            // mostrar u ocultar suavemente los filtros de estado y rol.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1.0,
                  child: child,
                );
              },
              child: _filtrosVisibles
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                      child: _buildFilterPanel(),
                    )
                  : const SizedBox.shrink(),
            ),
            // Añadir un espacio cuando los filtros están ocultos para separar la lista
            if (!_filtrosVisibles) const SizedBox(height: 12),
            // Lista filtrada por búsqueda y filtros de estado y rol
            Expanded(
              child: Consumer<UsuariosViewModel>(
                builder: (context, usuariosVM, child) {
                  // Use the calculated displayList
                  var list = List<Usuario>.from(displayList);

                  // Aplicar filtro por estado
                  if (_estadoFiltro != 'Todos') {
                    list = list.where((u) {
                      if (_estadoFiltro == 'Activos' && !u.activo) return false;
                      if (_estadoFiltro == 'Inactivos' && u.activo)
                        return false;
                      return true;
                    }).toList();
                  }
                  // Aplicar filtro por rol
                  if (_rolFiltro != 'Todos') {
                    list = list.where((u) => u.perfilId == _rolFiltro).toList();
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      final usuariosVM = context.read<UsuariosViewModel>();
                      await usuariosVM.cargarUsuarios(widget.empresaId);
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final user = list[index];
                        final canEdit = widget.role != 'PERF_TEC';
                        final canDelete = widget.role == 'PERF_ADMIN';

                        return Card(
                          elevation: 2,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(user.nombre),
                            subtitle: Text(_roleLabel(user.perfilId)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Botón para editar
                                if (canEdit)
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: AppLocalizations.of(
                                      context,
                                    )!.editUserTooltip,
                                    onPressed: () async {
                                      final usuariosVM = context
                                          .read<UsuariosViewModel>();
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              UserEditPage(user: user),
                                        ),
                                      );
                                      await usuariosVM.cargarUsuarios(
                                        widget.empresaId,
                                      );
                                      if (!mounted) return;
                                      // Actualizar lista al volver
                                      if (!mounted) return;
                                      // Actualizar lista al volver
                                      setState(() {});
                                    },
                                  ),
                                // Boton para restablecer contraseña
                                // Botón para eliminar (solo admin)
                                if (canDelete)
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    tooltip: AppLocalizations.of(
                                      context,
                                    )!.deleteUserTooltip,
                                    onPressed: () async {
                                      final confirm = await showWorkiaBottomSheet<bool>(
                                        context: context,
                                        builder: (ctx) {
                                          final t = AppLocalizations.of(ctx)!;
                                          return Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Text(
                                                  t.deleteUserTitle,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleLarge
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  t.deleteUserConfirmation(
                                                    user.nombre,
                                                  ),
                                                ),
                                                const SizedBox(height: 24),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: OutlinedButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              ctx,
                                                              false,
                                                            ),
                                                        style: OutlinedButton.styleFrom(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 16,
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          t.cancelButton,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              ctx,
                                                              true,
                                                            ),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                          foregroundColor:
                                                              Colors.white,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 16,
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          t.deleteButton,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                      if (confirm == true) {
                                        if (!context.mounted) return;
                                        final usuariosVM = context
                                            .read<UsuariosViewModel>();
                                        await usuariosVM.inactivar(
                                          user.id,
                                          widget.empresaId,
                                          widget.userId,
                                        );
                                        // Recargar usuarios después de eliminar
                                        await usuariosVM.cargarUsuarios(
                                          widget.empresaId,
                                        );
                                        if (!mounted) return;
                                        if (!mounted) return;
                                        // Actualizar lista al volver
                                        setState(() {});
                                      }
                                    },
                                  ),
                              ],
                            ),
                            onTap: canEdit
                                ? null
                                : () async {
                                    // Técnicos no tienen botón de editar; abrir detalle
                                    final usuariosVM = context
                                        .read<UsuariosViewModel>();
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            UserEditPage(user: user),
                                      ),
                                    );
                                    await usuariosVM.cargarUsuarios(
                                      widget.empresaId,
                                    );
                                    if (!mounted) return;
                                    // Actualizar lista al volver
                                    if (!mounted) return;
                                    // Actualizar lista al volver
                                    setState(() {});
                                  },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Capturar el ViewModel antes de navegar
          final usuariosVM = context.read<UsuariosViewModel>();
          // Navega a la página de registro para agregar un nuevo usuario.
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RegisterPage(
                isAdminCreation: true,
                empresaId: widget.empresaId,
              ),
            ),
          );
          // Recargar la lista de usuarios al volver
          await usuariosVM.cargarUsuarios(widget.empresaId);
          if (!mounted) return;
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
