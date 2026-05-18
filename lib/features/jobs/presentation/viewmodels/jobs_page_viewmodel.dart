import 'package:flutter/material.dart';
import 'package:workia/models/job.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';

/// ViewModel para la pantalla de Jobs (catálogo de trabajos).
///
/// Contiene la lógica de filtros y búsqueda.
class JobsPageViewModel extends ChangeNotifier {
  final TrabajosViewModel trabajosVM;
  final ClientesViewModel clientesVM;
  final UsuariosViewModel usuariosVM;
  final String empresaId;
  final String userRole;

  JobsPageViewModel({
    required this.trabajosVM,
    required this.clientesVM,
    required this.usuariosVM,
    required this.empresaId,
    required this.userRole,
  });

  // ========== ESTADO DE FILTROS ==========

  String _searchQuery = '';
  bool _filtrosVisibles = false;
  String _statusFilter = 'Todos';
  String _clientFilter = 'Todos';
  String _techFilter = 'Todos';

  String get searchQuery => _searchQuery;
  bool get filtrosVisibles => _filtrosVisibles;
  String get statusFilter => _statusFilter;
  String get clientFilter => _clientFilter;
  String get techFilter => _techFilter;

  void setSearchQuery(String query) {
    _searchQuery = query;
    trabajosVM.buscar(query, empresaId);
    notifyListeners();
  }

  void toggleFiltrosVisibles() {
    _filtrosVisibles = !_filtrosVisibles;
    notifyListeners();
  }

  void setStatusFilter(String value) {
    _statusFilter = value;
    notifyListeners();
  }

  void setClientFilter(String value) {
    _clientFilter = value;
    notifyListeners();
  }

  void setTechFilter(String value) {
    _techFilter = value;
    notifyListeners();
  }

  // ========== OPCIONES DE FILTRO ==========

  List<String> get statusOptions => [
    'Todos',
    'En espera',
    'Iniciado',
    'Finalizado',
    'Cerrado',
  ];

  List<String> get clientOptions {
    final Set<String> names = {'Todos'};
    for (final c in clientesVM.clientes) {
      if (c.nombre.isNotEmpty) {
        names.add(c.nombre);
      }
    }
    final list = names.toList();
    list.sort((a, b) {
      if (a == 'Todos') return -1;
      if (b == 'Todos') return 1;
      return a.compareTo(b);
    });
    return list;
  }

  List<String> get techOptions {
    final Set<String> names = {'Todos'};
    for (final u in usuariosVM.usuarios) {
      if (u.nombre.isNotEmpty) {
        names.add(u.nombre);
      }
    }
    final list = names.toList();
    list.sort((a, b) {
      if (a == 'Todos') return -1;
      if (b == 'Todos') return 1;
      return a.compareTo(b);
    });
    return list;
  }

  // ========== LISTA FILTRADA ==========

  List<Trabajo> get filteredJobs {
    var jobs = trabajosVM.trabajos;

    // Filtro por estado
    if (_statusFilter != 'Todos') {
      final normalized = _statusFilter.toLowerCase();
      jobs = jobs.where((j) {
        final e = j.estado.replaceAll('_', ' ').toLowerCase();
        return e == normalized || e.contains(normalized);
      }).toList();
    }

    // Filtro por cliente
    if (_clientFilter != 'Todos') {
      jobs = jobs.where((j) {
        return j.cliente == _clientFilter ||
            j.clientesAsignados.contains(_clientFilter);
      }).toList();
    }

    // Filtro por técnico
    if (_techFilter != 'Todos') {
      jobs = jobs.where((j) {
        return j.empleadosAsignados.contains(_techFilter);
      }).toList();
    }

    // Ordenar por fecha más reciente
    jobs.sort((a, b) {
      final aDate = a.fechaInicio;
      final bDate = b.fechaInicio;
      return bDate.compareTo(aDate);
    });

    return jobs;
  }

  // ========== ACCIONES ==========

  Future<void> deleteJob(String jobId, String userId) async {
    await trabajosVM.cancelar(jobId, empresaId, userId);
    await trabajosVM.cargarTrabajos(empresaId);
  }

  Future<void> loadData() async {
    await Future.wait([
      trabajosVM.cargarTrabajos(empresaId),
      clientesVM.cargarClientes(empresaId),
      usuariosVM.cargarUsuarios(empresaId),
    ]);
  }
}
