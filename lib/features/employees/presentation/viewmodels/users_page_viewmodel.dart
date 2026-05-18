import 'package:flutter/material.dart';
import 'package:workia/models/usuario.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';

class UsersPageViewModel extends ChangeNotifier {
  final UsuariosViewModel usuariosVM;
  final String currentUserId;
  final String empresaId;

  UsersPageViewModel({
    required this.usuariosVM,
    required this.currentUserId,
    required this.empresaId,
  });

  // ========== ESTADO DE FILTROS ==========
  String _searchQuery = '';
  String _statusFilter = 'Activos'; // 'Todos', 'Activos', 'Inactivos'
  String _roleFilter = 'Todos'; // 'Todos', 'PERF_ADMIN', 'PERF_FIN', 'PERF_TEC'
  bool _isLoading = false;

  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get roleFilter => _roleFilter;
  bool get isLoading => _isLoading;

  // ========== ACCIONES ==========

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase().trim();
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    if (status != null) {
      _statusFilter = status;
      notifyListeners();
    }
  }

  void setRoleFilter(String? role) {
    if (role != null) {
      _roleFilter = role;
      notifyListeners();
    }
  }

  Future<void> loadUsers() async {
    _isLoading = true;
    // notifyListeners(); // Evitar rebuilds innecesarios si ya se muestra loading en UI
    await usuariosVM.cargarUsuarios(empresaId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteUser(Usuario user) async {
    await usuariosVM.inactivar(user.id, empresaId, currentUserId);
    await loadUsers();
  }

  // ========== GETTERS COMPUTADOS ==========

  List<Usuario> get filteredUsers {
    List<Usuario> list = usuariosVM.usuarios; // Obtener lista base

    // 1. Filtro de búsqueda
    if (_searchQuery.isNotEmpty) {
      list = list.where((u) {
        return u.nombre.toLowerCase().contains(_searchQuery) ||
            u.email.toLowerCase().contains(_searchQuery) ||
            u.perfilId.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // 2. Filtro de estado
    if (_statusFilter != 'Todos') {
      list = list.where((u) {
        if (_statusFilter == 'Activos') return u.activo;
        if (_statusFilter == 'Inactivos') return !u.activo;
        return true;
      }).toList();
    }

    // 3. Filtro de rol
    if (_roleFilter != 'Todos') {
      list = list.where((u) => u.perfilId == _roleFilter).toList();
    }

    return list;
  }
}
