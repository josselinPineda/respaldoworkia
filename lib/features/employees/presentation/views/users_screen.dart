import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/features/employees/presentation/viewmodels/users_page_viewmodel.dart';
import 'package:workia/features/employees/presentation/views/user_edit_screen.dart';
import 'package:workia/features/problems/presentation/views/problems_screen.dart';
import 'package:workia/features/settings/presentation/views/user_settings_screen.dart';
import 'package:workia/features/auth/presentation/views/register_screen.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({
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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => UsersPageViewModel(
        usuariosVM: ctx.read<UsuariosViewModel>(),
        currentUserId: userId,
        empresaId: empresaId,
      )..loadUsers(),
      child: _UsersScreenContent(
        userName: userName,
        role: role,
        empresaId: empresaId,
      ),
    );
  }
}

class _UsersScreenContent extends StatefulWidget {
  const _UsersScreenContent({
    required this.userName,
    required this.role,
    required this.empresaId,
  });

  final String userName;
  final String role;
  final String empresaId;

  @override
  State<_UsersScreenContent> createState() => _UsersScreenContentState();
}

class _UsersScreenContentState extends State<_UsersScreenContent> {
  final TextEditingController _searchController = TextEditingController();
  bool _filtrosVisibles = false;
  String? _lastRoleFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<UsersPageViewModel>().setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _roleLabel(BuildContext context, String perfilId) {
    final t = AppLocalizations.of(context)!;
    switch (perfilId) {
      case 'PERF_ADMIN':
        return t.adminRole;
      case 'PERF_FIN':
        return t.financeRole;
      case 'PERF_TEC':
        return t.technicianRole;
      default:
        return perfilId;
    }
  }

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
    final vm = context.watch<UsersPageViewModel>();
    final t = AppLocalizations.of(context)!;
    final users = vm.filteredUsers;
    final showSearch = vm.roleFilter != 'PERF_TEC';

    if (_lastRoleFilter != vm.roleFilter) {
      _lastRoleFilter = vm.roleFilter;
      if (!showSearch && _searchController.text.isNotEmpty) {
        _searchController.clear();
        vm.setSearchQuery('');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.usersTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProblemsScreen(
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
                  builder: (_) => UserSettingsScreen(
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
            // Buscador y Toggle Filtros
            Row(
              children: [
                if (showSearch) ...[
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
                ] else
                  const Spacer(),
                IconButton(
                  icon: Icon(
                    _filtrosVisibles ? Icons.filter_alt_off : Icons.filter_alt,
                  ),
                  tooltip: _filtrosVisibles
                      ? t.hideFiltersTooltip
                      : t.showFiltersTooltip,
                  onPressed: () =>
                      setState(() => _filtrosVisibles = !_filtrosVisibles),
                ),
              ],
            ),

            // Panel Filtros
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1.0,
                child: child,
              ),
              child: _filtrosVisibles
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownSearch<String>(
                              items: (f, p) => [
                                'Todos',
                                'Activos',
                                'Inactivos',
                              ],
                              selectedItem: vm.statusFilter,
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: t.statusLabel,
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              popupProps: const PopupProps.menu(
                                fit: FlexFit.loose,
                              ),
                              onChanged: vm.setStatusFilter,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownSearch<String>(
                              items: (f, p) => [
                                'Todos',
                                'PERF_ADMIN',
                                'PERF_FIN',
                                'PERF_TEC',
                              ],
                              selectedItem: vm.roleFilter,
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: t.roleLabel,
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              popupProps: const PopupProps.menu(
                                fit: FlexFit.loose,
                              ),
                              onChanged: vm.setRoleFilter,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            if (!_filtrosVisibles) const SizedBox(height: 12),

            // Lista
            Expanded(
              child: RefreshIndicator(
                onRefresh: vm.loadUsers,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
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
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(user.nombre),
                        subtitle: Text(_roleLabel(context, user.perfilId)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (canEdit)
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: t.editUserTooltip,
                                onPressed: () async {
                                  // Navegar a editar (legacy)
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          UserEditScreen(user: user),
                                    ),
                                  );
                                  vm.loadUsers();
                                },
                              ),
                            if (canDelete)
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: t.deleteUserTooltip,
                                onPressed: () async {
                                  // Confirmar eliminación (TODO: Usar UIUtils.showConfirmDialog si existiera)
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(t.deleteUserTitle),
                                      content: Text(
                                        t.deleteUserConfirmation(user.nombre),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: Text(t.cancelButton),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: Text(
                                            t.deleteButton,
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await vm.deleteUser(user);
                                  }
                                },
                              ),
                          ],
                        ),
                        onTap: canEdit
                            ? null
                            : () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => UserEditScreen(user: user),
                                  ),
                                );
                                vm.loadUsers();
                              },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RegisterScreen(
                isAdminCreation: true,
                empresaId: widget.empresaId,
              ),
            ),
          );
          vm.loadUsers();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
