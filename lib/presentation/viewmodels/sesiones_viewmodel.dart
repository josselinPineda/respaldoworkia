import 'dart:async';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:workia/domain/repositories/sesion_trabajo_repository.dart';
import 'package:workia/models/sesion_trabajo.dart';

class SesionesViewModel extends ChangeNotifier {
  final SesionTrabajoRepository _repository;

  List<SesionTrabajo> _sesiones = [];
  bool _isLoading = false;

  List<SesionTrabajo> get sesiones => _sesiones;
  bool get isLoading => _isLoading;

  SesionesViewModel({required SesionTrabajoRepository repository})
    : _repository = repository;

  // Mapa para acceso rápido a la sesión activa de cada técnicos
  // Key: tecnicoId, Value: SesionTrabajo (activa)
  final Map<String, SesionTrabajo> _activeSessions = {};

  // Timers locales para auto-finalizar sesiones por tiempo (solo mientras la app estÃ¡ abierta).
  // Key: sesionId
  final Map<String, Timer> _autoFinishTimers = {};

  // Timer para actualizar "Horas registradas" en vivo (solo para el dÃ­a de hoy).
  Timer? _liveDailyHoursTimer;
  DateTime? _liveDailyHoursDate;
  String? _liveDailyHoursEmpresaId;
  Set<String>? _liveDailyHoursAssignmentIdsFilter;
  bool _liveDailyHoursTickInFlight = false;

  // Mapa para horas diarias por técnico
  Map<String, double> _dailyHours = {};
  Map<String, double> get dailyHours => _dailyHours;

  // Lista de sesiones diarias
  List<SesionTrabajo> _dailySessions = [];
  List<SesionTrabajo> get dailySessions => _dailySessions;

  // Lista de TODAS las sesiones (historial completo)
  List<SesionTrabajo> _allHistorySessions = [];
  List<SesionTrabajo> get allHistorySessions => _allHistorySessions;

  bool isSessionActiveFor(String tecnicoId) {
    return _activeSessions.containsKey(tecnicoId);
  }

  SesionTrabajo? getActiveSessionFor(String tecnicoId) {
    return _activeSessions[tecnicoId];
  }

  /// Intenta hidratar la sesiÃ³n activa de un tÃ©cnico para una asignaciÃ³n.
  ///
  /// Esto se usa cuando la UI necesita saber si el trabajo ya estÃ¡ iniciado
  /// (por ejemplo tras re-login) sin requerir `init()` (stream) por asignaciÃ³n.
  Future<void> hydrateActiveSessionForAssignment(
    String trabajoAsignadoId,
    String tecnicoId,
  ) async {
    try {
      final session = await _repository.obtenerSesionActiva(
        trabajoAsignadoId,
        tecnicoId,
      );
      if (session == null) return;

      // Un tÃ©cnico solo deberÃ­a tener 1 sesiÃ³n activa; guardamos la encontrada.
      _activeSessions[tecnicoId] = session;
      notifyListeners();
    } catch (e) {
      debugPrint('Error hydrating active session: $e');
    }
  }

  StreamSubscription? _subscription;

  /// Cargar sesiones y escuchar cambios en tiempo real
  void init(String trabajoAsignadoId) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = _repository.getSesionesPorAsignacion(trabajoAsignadoId).listen((
      data,
    ) {
      _sesiones = data;
      _updateActiveSessions();
      _isLoading = false;

      // Si hay sesiones nuevas o cerradas, podría ser útil recargar los totales
      // en el TrabajoAsignadoViewModel, aunque Firestore debería notificar
      // el cambio en el documento principal automáticamente.
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    for (final t in _autoFinishTimers.values) {
      t.cancel();
    }
    _autoFinishTimers.clear();
    _liveDailyHoursTimer?.cancel();
    super.dispose();
  }

  void _updateActiveSessions() {
    _activeSessions.clear();
    for (var s in _sesiones) {
      if (s.fin == null) {
        // Asumimos que la más reciente es la activa, lógica de seguridad
        _activeSessions[s.tecnicoId] = s;
      }
    }
  }

  void _stopLiveDailyHours() {
    _liveDailyHoursTimer?.cancel();
    _liveDailyHoursTimer = null;
    _liveDailyHoursDate = null;
    _liveDailyHoursEmpresaId = null;
    _liveDailyHoursAssignmentIdsFilter = null;
    _liveDailyHoursTickInFlight = false;
  }

  void _recomputeDailyHoursFromLoadedSessions(DateTime date) {
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(date, now);
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = dateStart.add(const Duration(days: 1));

    final Map<String, double> hoursByTech = {};
    for (final s in _dailySessions) {
      final sessionStart = s.inicio.toLocal();
      final sessionEnd = (s.fin ?? (isToday ? now : dateEnd)).toLocal();

      final overlapStart =
          sessionStart.isBefore(dateStart) ? dateStart : sessionStart;
      final overlapEnd = sessionEnd.isAfter(dateEnd) ? dateEnd : sessionEnd;

      double horas = 0.0;
      if (overlapEnd.isAfter(overlapStart)) {
        final duration = overlapEnd.difference(overlapStart);
        horas = double.parse((duration.inMinutes / 60.0).toStringAsFixed(2));
      }

      hoursByTech.update(
        s.tecnicoId,
        (val) => val + horas,
        ifAbsent: () => horas,
      );
    }
    _dailyHours = hoursByTech;
  }

  void _maybeStartLiveDailyHours(DateTime date) {
    final now = DateTime.now();
    if (!DateUtils.isSameDay(date, now)) {
      _stopLiveDailyHours();
      return;
    }

    if (_liveDailyHoursTimer != null &&
        _liveDailyHoursDate != null &&
        DateUtils.isSameDay(_liveDailyHoursDate!, date)) {
      return;
    }

    _stopLiveDailyHours();
    _liveDailyHoursDate = date;

    _liveDailyHoursTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (_liveDailyHoursDate == null) return;
      if (_liveDailyHoursTickInFlight) return;
      if (_liveDailyHoursEmpresaId == null) return;

      _liveDailyHoursTickInFlight = true;
      try {
        final sessions = await _repository.obtenerSesionesPorEmpresaYFecha(
          _liveDailyHoursEmpresaId!,
          _liveDailyHoursDate!,
        );
        final filter = _liveDailyHoursAssignmentIdsFilter;
        _dailySessions = filter == null
            ? sessions
            : sessions.where((s) => filter.contains(s.trabajoAsignadoId)).toList();
        _recomputeDailyHoursFromLoadedSessions(_liveDailyHoursDate!);
        notifyListeners();
      } catch (e) {
        debugPrint('Live daily hours tick error: $e');
      } finally {
        _liveDailyHoursTickInFlight = false;
      }
    });
  }

  Future<void> iniciarSesion(
    String trabajoAsignadoId,
    String tecnicoId,
    String trabajoId,
    String empresaId,
  ) async {
    // Optimistic Update: Generar ID real para uso inmediato
    final newSessionId = _repository.generateId();
    final tempSession = SesionTrabajo(
      id: newSessionId, // Ahora el ID es válido en servidor
      trabajoAsignadoId: trabajoAsignadoId,
      tecnicoId: tecnicoId,
      inicio: DateTime.now(),
      empresaId: empresaId,
    );
    _sesiones.insert(0, tempSession);
    _updateActiveSessions();
    notifyListeners();

    try {
      await _repository.iniciarSesion(
        trabajoAsignadoId,
        tecnicoId,
        trabajoId,
        sesionId: newSessionId,
        empresaId: empresaId,
      );
      // El stream actualizará la lista real, pero el ID ya coincide
    } catch (e) {
      debugPrint('Error iniciando sesión: $e');
      // Revertir en caso de error
      _sesiones.removeWhere((s) => s.id == newSessionId);
      _updateActiveSessions();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> finalizarSesion(
    String sesionId,
    String trabajoAsignadoId,
  ) async {
    // Optimistic Update: Actualizar sesión localmente
    final index = _sesiones.indexWhere((s) => s.id == sesionId);
    SesionTrabajo? backupSession;
    String? backupActiveTechId;
    SesionTrabajo? backupActiveSession;

    // Si esta sesiÃ³n solo existe en el mapa de activas (por ejemplo tras hydrate),
    // cerrarla localmente para que la UI no se quede "pegada".
    try {
      final entry = _activeSessions.entries.firstWhere(
        (e) => e.value.id == sesionId,
      );
      backupActiveTechId = entry.key;
      backupActiveSession = entry.value;
      _activeSessions[entry.key] = entry.value.copyWith(fin: DateTime.now());
    } catch (_) {}

    if (index != -1) {
      backupSession = _sesiones[index];
      _sesiones[index] = _sesiones[index].copyWith(fin: DateTime.now());
      _updateActiveSessions();
      notifyListeners();
    } else {
      // Recalcular sesiones activas usando el estado actual.
      _updateActiveSessions();
      notifyListeners();
    }

    try {
      await _repository.finalizarSesion(sesionId, trabajoAsignadoId);
      // El stream actualizará la UI
    } catch (e) {
      debugPrint('Error finalizando sesión: $e');
      // Revertir
      if (index != -1 && backupSession != null) {
        _sesiones[index] = backupSession;
      }
      if (backupActiveTechId != null && backupActiveSession != null) {
        _activeSessions[backupActiveTechId] = backupActiveSession;
      }
      _updateActiveSessions();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadRegisteredHoursForDate(
    String empresaId,
    DateTime date,
    {Set<String>? assignmentIdsFilter}
  ) async {
    try {
      final sessions = await _repository.obtenerSesionesPorEmpresaYFecha(
        empresaId,
        date,
      );
      final filteredSessions = assignmentIdsFilter == null
          ? sessions
          : sessions
              .where((s) => assignmentIdsFilter.contains(s.trabajoAsignadoId))
              .toList();
      _dailySessions = filteredSessions;
      _recomputeDailyHoursFromLoadedSessions(date);
      notifyListeners();
      _liveDailyHoursEmpresaId = empresaId;
      _liveDailyHoursAssignmentIdsFilter = assignmentIdsFilter;
      _maybeStartLiveDailyHours(date);
    } catch (e) {
      debugPrint('Error loading registered hours: $e');
      // Set empty state on error to avoid stale data
      _dailySessions = [];
      _dailyHours = {};
      _stopLiveDailyHours();
    }
  }

  Future<void> loadAllRegisteredHours(String empresaId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final sessions = await _repository.obtenerTodasSesionesPorEmpresa(
        empresaId,
      );
      _allHistorySessions = sessions;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading all registered hours: $e');
      _allHistorySessions = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearDailyRegisteredHours() {
    _dailySessions = [];
    _dailyHours = {};
    _stopLiveDailyHours();
    notifyListeners();
  }
}
