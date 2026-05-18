import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workia/models/cliente.dart';
import 'package:workia/models/job.dart';
import 'package:workia/models/trabajo_asignado.dart';
import 'package:workia/models/usuario.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/presentation/viewmodels/sesiones_viewmodel.dart';

/// ViewModel para la pantalla de detalle de trabajo.
///
/// Contiene TODA la lógica de negocio: filtros, cálculos de estado,
/// resolución de clientes, preparación de asignaciones, gestión de sesiones.
/// La Vista solo consume los getters y dispara los métodos.
class JobDetailViewModel extends ChangeNotifier {
  // Dependencias (ViewModels de datos)
  final ClientesViewModel clientesVM;
  final TrabajosAsignadosViewModel asignadosVM;
  final UsuariosViewModel usuariosVM;
  final SesionesViewModel sesionesVM;

  // Datos del trabajo actual
  final Trabajo job;
  final String userRole;
  final String userName;
  final String currentUserId;

  JobDetailViewModel({
    required this.clientesVM,
    required this.asignadosVM,
    required this.usuariosVM,
    required this.sesionesVM,
    required this.job,
    required this.userRole,
    required this.userName,
    required this.currentUserId,
  });

  // ========== ESTADO DE FILTROS ==========

  String _clientStatusFilter = 'Todos';
  String get clientStatusFilter => _clientStatusFilter;

  bool _showFilters = false;
  bool get showFilters => _showFilters;

  DateTime? _filterStartDate;
  DateTime? get filterStartDate => _filterStartDate;

  DateTime? _filterEndDate;
  DateTime? get filterEndDate => _filterEndDate;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // ========== ACCIONES DE FILTROS ==========

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _clientStatusFilter = status;
    notifyListeners();
  }

  void toggleFilters() {
    _showFilters = !_showFilters;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _filterStartDate = start;
    _filterEndDate = end;
    notifyListeners();
  }

  void clearDateFilter() {
    _filterStartDate = null;
    _filterEndDate = null;
    notifyListeners();
  }

  // ========== LÓGICA DE NEGOCIO: RANKING DE ESTADOS ==========

  /// Define la prioridad de los estados para ordenar clientes.
  /// Menor índice = mayor prioridad (aparece primero).
  int _indexOfStatus(String status) {
    final normalized = status.replaceAll('_', ' ').toLowerCase();
    switch (normalized) {
      case 'iniciado':
      case 'en progreso':
        return 0;
      case 'en espera':
      case 'pendiente':
        return 1;
      case 'finalizado':
      case 'completo':
        return 2;
      case 'cerrado':
        return 3;
      case 'cancelado':
        return 4;
      default:
        return 5;
    }
  }

  // ========== LÓGICA DE NEGOCIO: RESOLUCIÓN DE CLIENTES ==========

  /// Obtiene todas las asignaciones del trabajo actual.
  /// Filtra por técnico si el usuario es técnico.
  List<TrabajoAsignado> get _rawAssignments {
    var asignaciones = asignadosVM.trabajos.where((a) {
      final matchesId = a.trabajoId == job.id || a.id == job.id;
      final matchesTitle = a.tituloTrabajo == job.titulo;
      return matchesId || matchesTitle;
    }).toList();

    // Si es técnico, filtrar solo sus asignaciones
    if (userRole == 'PERF_TEC') {
      final currentUserId = _getCurrentUserId();
      if (currentUserId.isNotEmpty) {
        asignaciones = asignaciones
            .where((a) => a.tecnicosAsignados.contains(currentUserId))
            .toList();
      }
    }

    return asignaciones;
  }

  String _getCurrentUserId() {
    try {
      final currentUser = usuariosVM.usuarios.firstWhere(
        (u) => u.nombre == userName,
      );
      return currentUser.id;
    } catch (_) {
      return '';
    }
  }

  /// Determina la mejor asignación por cliente (según estado).
  /// Devuelve un mapa clienteId -> TrabajoAsignado.
  Map<String, TrabajoAsignado> get _bestAssignmentByClient {
    final Map<String, TrabajoAsignado> best = {};
    final Map<String, int> ranking = {};

    for (final a in _rawAssignments) {
      final clientId = a.clienteId;
      final idx = _indexOfStatus(a.estado);
      if (!best.containsKey(clientId)) {
        best[clientId] = a;
        ranking[clientId] = idx;
      } else {
        final currentIdx = ranking[clientId]!;
        if (idx < currentIdx) {
          best[clientId] = a;
          ranking[clientId] = idx;
        }
      }
    }

    // Agregar clientes del catálogo del trabajo
    _addCatalogClients(best, ranking);

    return best;
  }

  void _addCatalogClients(
    Map<String, TrabajoAsignado> best,
    Map<String, int> ranking,
  ) {
    void addClient(String id) {
      if (id.isEmpty) return;
      String resolvedId = id;
      try {
        final client = clientesVM.clientes.firstWhere(
          (c) => c.id == id || c.nombre == id,
        );
        resolvedId = client.id;
      } catch (_) {}

      if (!best.containsKey(resolvedId)) {
        best[resolvedId] = TrabajoAsignado(
          id: '',
          trabajoId: job.id,
          tituloTrabajo: job.titulo,
          precioBase: 0.0,
          precioFinal: 0.0,
          clienteId: resolvedId,
          estado: 'EN ESPERA',
          fechaInicio: DateTime.now(),
          fechaFin: DateTime.now(),
          proximaFecha: null,
          esCiclico: false,
          frecuenciaCiclico: null,
          tecnicosAsignados: const [],
          empresaId: job.empresaId,
          activo: true,
          fechaCreacion: null,
          fechaActualizacion: null,
          creadoPor: '',
          actualizadoPor: '',
        );
        ranking[resolvedId] = _indexOfStatus('EN ESPERA');
      }
    }

    // Agregar clienteId principal si no está en asignados
    if (job.clienteId.isNotEmpty &&
        !job.clientesAsignados.contains(job.clienteId)) {
      addClient(job.clienteId);
    }

    // Agregar todos los clientes asignados del catálogo
    for (final c in job.clientesAsignados) {
      addClient(c);
    }
  }

  /// Resuelve un cliente por su ID desde el ViewModel de clientes.
  Cliente _resolveClient(String clientId) {
    try {
      return clientesVM.clientes.firstWhere(
        (c) => c.id == clientId || c.nombre == clientId,
      );
    } catch (_) {
      return Cliente(
        id: clientId,
        nombre: clientId,
        razonSocial: '',
        personaContacto: '',
        telefono: '',
        correo: '',
        direccion: '',
      );
    }
  }

  // ========== GETTER PRINCIPAL: Datos Filtrados y Ordenados ==========

  /// Devuelve la lista de items (cliente + asignación) ya filtrados y ordenados.
  /// La Vista solo consume este getter, SIN hacer cálculos.
  List<ClientAssignmentItem> get filteredClientAssignments {
    final bestByClient = _bestAssignmentByClient;
    final query = _searchQuery.trim().toLowerCase();

    // Construir ranking para ordenación
    final Map<String, int> rankingByClient = {};
    for (final entry in bestByClient.entries) {
      rankingByClient[entry.key] = _indexOfStatus(entry.value.estado);
    }

    // Construir lista de items
    final List<ClientAssignmentItem> items = [];
    bestByClient.forEach((clientId, assign) {
      final client = _resolveClient(clientId);
      items.add(ClientAssignmentItem(client: client, assignment: assign));
    });

    // Ordenar por ranking de estado y luego por nombre
    items.sort((a, b) {
      final ca = rankingByClient[a.assignment.clienteId] ?? 4;
      final cb = rankingByClient[b.assignment.clienteId] ?? 4;
      if (ca != cb) return ca.compareTo(cb);
      return a.client.nombre.compareTo(b.client.nombre);
    });

    // Aplicar filtros
    return items.where((item) {
      // Filtro de texto
      if (query.isNotEmpty &&
          !item.client.nombre.toLowerCase().contains(query)) {
        return false;
      }

      // Filtro de estado
      if (_clientStatusFilter != 'Todos') {
        String assignStatus = item.assignment.estado;
        if (assignStatus == 'En_progreso') assignStatus = 'En progreso';

        String filterStatus = _clientStatusFilter;
        if (filterStatus == 'En_progreso') filterStatus = 'En progreso';

        if (assignStatus.toLowerCase() != filterStatus.toLowerCase()) {
          return false;
        }
      }

      // Filtro de fecha
      if (_filterStartDate != null && _filterEndDate != null) {
        final start = DateTime(
          _filterStartDate!.year,
          _filterStartDate!.month,
          _filterStartDate!.day,
        );
        final end = DateTime(
          _filterEndDate!.year,
          _filterEndDate!.month,
          _filterEndDate!.day,
          23,
          59,
          59,
        );

        if (item.assignment.fechaInicio.isBefore(start) ||
            item.assignment.fechaInicio.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Indica si hay items originales (antes de filtros).
  bool get hasAnyClients => _bestAssignmentByClient.isNotEmpty;

  // ========== LÓGICA DE ASIGNACIÓN ==========

  /// Lista de clientes disponibles para asignar (no asignados aún).
  List<Cliente> get availableClientsForAssignment {
    final assignedIds = _bestAssignmentByClient.keys.toSet();
    return clientesVM.clientes
        .where((c) => !assignedIds.contains(c.id))
        .toList();
  }

  /// Lista de técnicos disponibles para asignar.
  /// Devuelve todos los usuarios cargados (sin restricción de perfil)
  /// para permitir máxima flexibilidad en la asignación.
  List<Usuario> get availableTechnicians {
    return usuariosVM.usuarios
        .where((u) => u.nombre.isNotEmpty)
        .toList();
  }

  /// Calcula la próxima fecha según la frecuencia cíclica.
  DateTime? calculateNextDate(DateTime start, String? frequency) {
    if (frequency == null) return null;

    switch (frequency) {
      case 'mensual':
        return DateTime(start.year, start.month + 1, start.day, 12);
      case 'trimestral':
        return DateTime(start.year, start.month + 3, start.day, 12);
      case 'semestral':
        return DateTime(start.year, start.month + 6, start.day, 12);
      case 'anual':
        return DateTime(start.year + 1, start.month, start.day, 12);
      default:
        return DateTime(start.year, start.month + 1, start.day, 12);
    }
  }

  /// Crea o actualiza asignaciones para los clientes seleccionados.
  Future<int> saveAssignments({
    required List<Cliente> selectedClients,
    required List<String> selectedTechIds,
    required DateTime startDate,
    required bool isCyclic,
    required String? frequency,
    required double? manualPrice,
    int? autoFinalizarHoras,
    int? tiempoEnEsperaMin,
    int? tiempoIniciadoMin,
    int? tiempoFinalizadoMin,
    int? tiempoCerradoMin,
    TrabajoAsignado? existingAssignment,
  }) async {
    final inicio = DateTime(startDate.year, startDate.month, startDate.day, 12);
    final fin = inicio;

    DateTime? proxima;
    if (isCyclic && frequency != null) {
      proxima = calculateNextDate(inicio, frequency);
    }

    int processedCount = 0;
    final currentAssignments = asignadosVM.trabajos
        .where((a) => a.trabajoId == job.id)
        .toList();

    for (final client in selectedClients) {
      TrabajoAsignado? existing;
      try {
        existing = currentAssignments.firstWhere(
          (a) => a.clienteId == client.id,
        );
      } catch (_) {}

      final finalPrice = manualPrice ?? job.costo;

      if (existing != null) {
        // Actualizar existente
        final updated = existing.copyWith(
          fechaInicio: inicio,
          fechaFin: fin,
          esCiclico: isCyclic,
          frecuenciaCiclico: isCyclic ? frequency : null,
          proximaFecha: proxima,
          tecnicosAsignados: selectedTechIds,
          precioFinal: finalPrice,
          autoFinalizarHoras: autoFinalizarHoras,
          tiempoEnEsperaMin: tiempoEnEsperaMin,
          tiempoIniciadoMin: tiempoIniciadoMin,
          tiempoFinalizadoMin: tiempoFinalizadoMin,
          tiempoCerradoMin: tiempoCerradoMin,
          fechaActualizacion: DateTime.now(),
          actualizadoPor: userName,
        );
        await asignadosVM.actualizar(updated);
      } else {
        // Crear nueva
        final newAssignment = TrabajoAsignado(
          id: '',
          trabajoId: job.id,
          tituloTrabajo: job.titulo,
          precioBase: job.costo,
          precioFinal: finalPrice,
          clienteId: client.id,
          estado: 'EN ESPERA',
          fechaInicio: inicio,
          fechaFin: fin,
          proximaFecha: proxima,
          esCiclico: isCyclic,
          frecuenciaCiclico: isCyclic ? frequency : null,
          tecnicosAsignados: selectedTechIds,
          empresaId: job.empresaId,
          activo: true,
          fechaCreacion: DateTime.now(),
          fechaActualizacion: DateTime.now(),
          creadoPor: userName,
          actualizadoPor: userName,
          autoFinalizarHoras: autoFinalizarHoras,
          tiempoEnEsperaMin: tiempoEnEsperaMin,
          tiempoIniciadoMin: tiempoIniciadoMin,
          tiempoFinalizadoMin: tiempoFinalizadoMin,
          tiempoCerradoMin: tiempoCerradoMin,
        );
        await asignadosVM.agregar(newAssignment);
      }
      processedCount++;
    }

    // Recargar datos
    await asignadosVM.cargarTrabajosAsignados(job.empresaId);
    notifyListeners();

    return processedCount;
  }

  // ========== HELPERS DE FORMATEO ==========

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String formatDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '';
    return '${start.day}/${start.month} - ${end.day}/${end.month}';
  }

  // ========== GESTIÓN DE SESIONES (MVVM) ==========

  /// Indica si hay una sesión activa para el usuario actual.
  bool get isSessionActiveForCurrentUser =>
      sesionesVM.isSessionActiveFor(currentUserId);

  /// Indica si el usuario actual está asignado a un trabajo específico.
  bool isCurrentUserAssignedTo(TrabajoAsignado assignment) =>
      assignment.tecnicosAsignados.contains(currentUserId);

  /// Actualiza el estado de una asignación.
  Future<void> updateAssignmentStatus(
    TrabajoAsignado assignment,
    String newStatus,
  ) async {
    if (newStatus != assignment.estado) {
      final updated = assignment.copyWith(estado: newStatus);
      await asignadosVM.actualizar(updated);
      notifyListeners();
    }
  }

  /// Inicia una sesión de trabajo para la asignación actual.
  /// Verifica geolocalización si el trabajo tiene coordenadas.
  /// Devuelve un resultado con éxito/fallo y mensaje.
  Future<SessionStartResult> startSessionForAssignment(
    TrabajoAsignado assignment,
  ) async {
    final lat = job.latitud;
    final lng = job.longitud;

    // Verificar geolocalización si hay coordenadas
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return SessionStartResult.failure('Por favor activa el GPS');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return SessionStartResult.failure('Permiso de ubicación denegado');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return SessionStartResult.failure(
          'Permisos de ubicación denegados permanentemente',
        );
      }

      final position = await Geolocator.getCurrentPosition();
      final distance = Geolocator.distanceBetween(
        lat,
        lng,
        position.latitude,
        position.longitude,
      );

      const double maxDistance = 200;
      if (distance > maxDistance) {
        return SessionStartResult.outOfRange(
          distance: distance.round(),
          maxDistance: maxDistance.round(),
        );
      }
    }

    // Iniciar sesión
    sesionesVM.iniciarSesion(
      assignment.id,
      currentUserId,
      assignment.trabajoId,
      job.empresaId,
    );

    notifyListeners();
    return SessionStartResult.success();
  }

  /// Finaliza la sesión activa del usuario actual.
  void stopCurrentSession(TrabajoAsignado assignment) {
    final session = sesionesVM.getActiveSessionFor(currentUserId);
    if (session != null) {
      sesionesVM.finalizarSesion(session.id, assignment.id);
      notifyListeners();
    }
  }

  // ========== RESOLUCIÓN DE TÉCNICOS ==========

  /// Devuelve la lista de técnicos asignados a un trabajo.
  List<Usuario> getTechniciansForAssignment(TrabajoAsignado assignment) {
    final List<Usuario> techs = [];
    for (final id in assignment.tecnicosAsignados) {
      final user = usuariosVM.usuarios.firstWhere(
        (u) => u.id == id,
        orElse: () => Usuario(
          id: id,
          authUid: '',
          nombre: id,
          email: '',
          idEmpresa: '',
          perfilId: '',
        ),
      );
      techs.add(user);
    }
    techs.sort((a, b) => a.nombre.compareTo(b.nombre));
    return techs;
  }
}

/// Resultado de iniciar una sesión.
class SessionStartResult {
  final bool success;
  final String? message;
  final bool isOutOfRange;
  final int? distance;
  final int? maxDistance;

  const SessionStartResult._({
    required this.success,
    this.message,
    this.isOutOfRange = false,
    this.distance,
    this.maxDistance,
  });

  factory SessionStartResult.success() =>
      const SessionStartResult._(success: true);

  factory SessionStartResult.failure(String message) =>
      SessionStartResult._(success: false, message: message);

  factory SessionStartResult.outOfRange({
    required int distance,
    required int maxDistance,
  }) => SessionStartResult._(
    success: false,
    isOutOfRange: true,
    distance: distance,
    maxDistance: maxDistance,
  );
}

/// Modelo simple para agrupar cliente y asignación.
/// Es un DTO para la Vista, sin lógica.
class ClientAssignmentItem {
  final Cliente client;
  final TrabajoAsignado assignment;

  const ClientAssignmentItem({required this.client, required this.assignment});
}
