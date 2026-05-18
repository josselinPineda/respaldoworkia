import 'package:flutter/material.dart';
import 'package:workia/models/cliente.dart';
import 'package:workia/models/job.dart';
import 'package:workia/models/trabajo_asignado.dart';
import 'package:workia/models/usuario.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';

/// ViewModel para la pantalla "Mis Trabajos".
///
/// Contiene TODA la lógica de negocio: filtros, merge de trabajos
/// con asignaciones, agrupación por estado y búsqueda.
class MisTrabajosViewModel extends ChangeNotifier {
  // Dependencias
  final ClientesViewModel clientesVM;
  final TrabajosAsignadosViewModel asignadosVM;
  final UsuariosViewModel usuariosVM;
  final TrabajosViewModel trabajosVM;
  final String userRole;
  final String userId;
  final String empresaId;

  MisTrabajosViewModel({
    required this.clientesVM,
    required this.asignadosVM,
    required this.usuariosVM,
    required this.trabajosVM,
    required this.userRole,
    required this.userId,
    required this.empresaId,
  });

  // ========== ESTADO DE FILTROS ==========

  String _searchQuery = '';
  String _filtroCliente = 'Todos';
  String _filtroTecnico = 'Todos';
  bool _filtrosVisibles = false;

  String get searchQuery => _searchQuery;
  String get filtroCliente => _filtroCliente;
  String get filtroTecnico => _filtroTecnico;
  bool get filtrosVisibles => _filtrosVisibles;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFiltroCliente(String value) {
    _filtroCliente = value;
    notifyListeners();
  }

  void setFiltroTecnico(String value) {
    _filtroTecnico = value;
    notifyListeners();
  }

  void toggleFiltrosVisibles() {
    _filtrosVisibles = !_filtrosVisibles;
    notifyListeners();
  }

  // ========== OPCIONES DE FILTRO ==========

  /// Lista de nombres de clientes para el dropdown de filtro.
  List<String> get clienteOptions {
    final Set<String> names = {'Todos'};
    for (final c in clientesVM.clientes) {
      if (c.nombre.isNotEmpty) {
        names.add(c.nombre);
      }
    }
    return names.toList()..sort();
  }

  /// Lista de nombres de técnicos para el dropdown de filtro.
  List<String> get tecnicoOptions {
    final Set<String> names = {'Todos'};
    for (final u in usuariosVM.usuarios) {
      if (u.nombre.isNotEmpty) {
        names.add(u.nombre);
      }
    }
    return names.toList()..sort();
  }

  // ========== PRIORIDAD DE ESTADOS ==========

  static const List<String> _statusOrder = [
    'iniciado',
    'en progreso',
    'en espera',
    'pendiente',
    'finalizado',
    'completo',
    'cerrado',
  ];

  // ========== MERGE DE TRABAJOS CON ASIGNACIONES ==========

  /// Combina los trabajos del catálogo con sus asignaciones.
  List<Trabajo> get mergedJobs {
    final catalogo = trabajosVM.trabajos;
    final asignaciones = asignadosVM.trabajos;
    final List<Trabajo> result = [];

    for (final job in catalogo) {
      final jobAssignments = asignaciones
          .where((a) => a.trabajoId == job.id && a.activo)
          .toList();

      String consolidatedState = job.estado.isNotEmpty
          ? job.estado.replaceAll('_', ' ')
          : 'En espera';

      if (jobAssignments.isNotEmpty) {
        int bestIndex = _statusOrder.length;
        for (final a in jobAssignments) {
          final s = a.estado.replaceAll('_', ' ').toLowerCase();
          String normalized = s;
          if (s == 'pendiente') normalized = 'en espera';
          if (s == 'completo' || s == 'completado') normalized = 'finalizado';

          final idx = _statusOrder.indexWhere((e) => e == normalized);
          final index = idx == -1 ? _statusOrder.length : idx;
          if (index < bestIndex) {
            bestIndex = index;
            consolidatedState = _formatStatus(normalized);
          }
        }
      }

      final clientNames = _getClientNames(job, jobAssignments);
      final techNames = _getTechNames(jobAssignments);

      result.add(
        job.copyWith(
          estado: consolidatedState,
          clientesAsignados: clientNames.toList(),
          empleadosAsignados: techNames.toList(),
        ),
      );
    }

    // Incluir trabajos que existen solo en asignaciones
    final catalogIds = catalogo.map((t) => t.id).toSet();
    final extraAssignments = asignaciones
        .where((a) => !catalogIds.contains(a.trabajoId))
        .toList();

    for (final a in extraAssignments) {
      final clientNames = _getClientNamesFromAssignment(a);
      final techNames = _getTechNamesFromAssignment(a);

      result.add(
        Trabajo(
          id: a.trabajoId,
          titulo: a.tituloTrabajo.isNotEmpty ? a.tituloTrabajo : a.trabajoId,
          cliente: clientNames.isNotEmpty ? clientNames.first : '',
          fechaInicio: a.fechaInicio,
          fechaFin: a.fechaFin,
          estado: a.estado.replaceAll('_', ' '),
          descripcion: '',
          costo: a.precioFinal,
          esCiclico: a.esCiclico,
          frecuenciaCiclico: a.frecuenciaCiclico,
          proximaFecha: a.proximaFecha,
          empleadosAsignados: techNames.toList(),
          clientesAsignados: clientNames.toList(),
          clienteId: a.clienteId,
          empresaId: a.empresaId,
        ),
      );
    }

    return result;
  }

  String _formatStatus(String normalized) {
    switch (normalized) {
      case 'en espera':
        return 'En espera';
      case 'iniciado':
        return 'Iniciado';
      case 'finalizado':
        return 'Finalizado';
      case 'cerrado':
        return 'Cerrado';
      default:
        return normalized.substring(0, 1).toUpperCase() +
            normalized.substring(1);
    }
  }

  Set<String> _getClientNames(Trabajo job, List<TrabajoAsignado> assignments) {
    final Set<String> names = {};
    if (job.cliente.isNotEmpty) names.add(job.cliente);

    for (final a in assignments) {
      if (a.clienteId.isNotEmpty) {
        final client = clientesVM.clientes.firstWhere(
          (c) => c.id == a.clienteId,
          orElse: () => Cliente(
            id: a.clienteId,
            nombre: a.clienteId,
            razonSocial: '',
            personaContacto: '',
            telefono: '',
            correo: '',
            direccion: '',
          ),
        );
        if (client.nombre.isNotEmpty) names.add(client.nombre);
      }
    }
    return names;
  }

  Set<String> _getTechNames(List<TrabajoAsignado> assignments) {
    final Set<String> names = {};
    for (final a in assignments) {
      for (final techId in a.tecnicosAsignados) {
        final user = usuariosVM.usuarios.firstWhere(
          (u) => u.id == techId,
          orElse: () => Usuario(
            id: techId,
            authUid: '',
            nombre: techId,
            email: '',
            idEmpresa: '',
            perfilId: '',
          ),
        );
        if (user.nombre.isNotEmpty) names.add(user.nombre);
      }
    }
    return names;
  }

  Set<String> _getClientNamesFromAssignment(TrabajoAsignado a) {
    final Set<String> names = {};
    if (a.clienteId.isNotEmpty) {
      final client = clientesVM.clientes.firstWhere(
        (c) => c.id == a.clienteId,
        orElse: () => Cliente(
          id: a.clienteId,
          nombre: a.clienteId,
          razonSocial: '',
          personaContacto: '',
          telefono: '',
          correo: '',
          direccion: '',
        ),
      );
      if (client.nombre.isNotEmpty) names.add(client.nombre);
    }
    return names;
  }

  Set<String> _getTechNamesFromAssignment(TrabajoAsignado a) {
    final Set<String> names = {};
    for (final techId in a.tecnicosAsignados) {
      final user = usuariosVM.usuarios.firstWhere(
        (u) => u.id == techId,
        orElse: () => Usuario(
          id: techId,
          authUid: '',
          nombre: techId,
          email: '',
          idEmpresa: '',
          perfilId: '',
        ),
      );
      if (user.nombre.isNotEmpty) names.add(user.nombre);
    }
    return names;
  }

  // ========== AGRUPACIÓN DE TRABAJOS ==========

  /// Agrupa trabajos que representan múltiples asignaciones en uno solo.
  List<Trabajo> get groupedJobs {
    final trabajos = mergedJobs;
    final Map<String, Trabajo> grouped = {};

    for (final t in trabajos) {
      if (grouped.containsKey(t.id)) {
        final existing = grouped[t.id]!;
        final Set<String> mergedClients = {
          ...existing.clientesAsignados,
          ...t.clientesAsignados,
        };
        final Set<String> mergedTechs = {
          ...existing.empleadosAsignados,
          ...t.empleadosAsignados,
        };

        // Consolidar estado
        final existingIdx = _getStatusPriority(existing.estado);
        final newIdx = _getStatusPriority(t.estado);
        final bestState = newIdx < existingIdx ? t.estado : existing.estado;

        grouped[t.id] = existing.copyWith(
          estado: bestState,
          clientesAsignados: mergedClients.toList(),
          empleadosAsignados: mergedTechs.toList(),
        );
      } else {
        grouped[t.id] = t;
      }
    }

    return grouped.values.toList();
  }

  int _getStatusPriority(String status) {
    final normalized = status.replaceAll('_', ' ').toLowerCase();
    final idx = _statusOrder.indexWhere((e) => e == normalized);
    return idx == -1 ? _statusOrder.length : idx;
  }

  // ========== LISTA FILTRADA FINAL ==========

  /// Lista de trabajos filtrados por búsqueda, cliente y técnico.
  List<Trabajo> get filteredJobs {
    var jobs = groupedJobs;

    // Filtro por rol de usuario (técnico solo ve sus trabajos asignados)
    if (userRole == 'PERF_TEC') {
      jobs = jobs.where((t) {
        final assignments = asignadosVM.trabajos.where(
          (a) => a.trabajoId == t.id && a.activo,
        );
        return assignments.any((a) => a.tecnicosAsignados.contains(userId));
      }).toList();
    }

    // Filtro por búsqueda
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      jobs = jobs.where((t) {
        return t.titulo.toLowerCase().contains(q) ||
            t.descripcion.toLowerCase().contains(q) ||
            t.cliente.toLowerCase().contains(q) ||
            t.clientesAsignados.any((c) => c.toLowerCase().contains(q)) ||
            t.empleadosAsignados.any((e) => e.toLowerCase().contains(q));
      }).toList();
    }

    // Filtro por cliente
    if (_filtroCliente != 'Todos') {
      jobs = jobs.where((t) {
        return t.cliente == _filtroCliente ||
            t.clientesAsignados.contains(_filtroCliente);
      }).toList();
    }

    // Filtro por técnico
    if (_filtroTecnico != 'Todos') {
      jobs = jobs.where((t) {
        return t.empleadosAsignados.contains(_filtroTecnico);
      }).toList();
    }

    // Ordenar por estado (activos primero) y luego por fecha
    jobs.sort((a, b) {
      final aIdx = _getStatusPriority(a.estado);
      final bIdx = _getStatusPriority(b.estado);
      if (aIdx != bIdx) return aIdx.compareTo(bIdx);
      return b.fechaInicio.compareTo(a.fechaInicio);
    });

    return jobs;
  }

  // ========== HELPERS ==========

  /// Obtiene las iniciales de un nombre.
  String getInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}
