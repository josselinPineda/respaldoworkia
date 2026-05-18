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

    if (index != -1) {
      backupSession = _sesiones[index];
      _sesiones[index] = _sesiones[index].copyWith(fin: DateTime.now());
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
        _updateActiveSessions();
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> loadRegisteredHoursForDate(
    String empresaId,
    DateTime date,
  ) async {
    try {
      final sessions = await _repository.obtenerSesionesPorEmpresaYFecha(
        empresaId,
        date,
      );
      _dailySessions = sessions;

      final Map<String, double> hoursByTech = {};
      final now = DateTime.now();
      // Check if the requested date is "today" (same year, month, day)
      final isToday =
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;

      for (var s in sessions) {
        double horas = s.horas;
        if (s.fin == null) {
          // If the session is still open...
          if (isToday) {
            // If viewing today, calc duration until now
            final duration = now.difference(s.inicio);
            horas = double.parse(
              (duration.inMinutes / 60.0).toStringAsFixed(2),
            );
          } else {
            // If viewing a past date and it's still open,
            // it means it's a long running session or error.
            // We'll show duration until now for consistency,
            // or maybe we should cap it?
            // Let's stick to "Current Duration" to be safe.
            final duration = now.difference(s.inicio);
            horas = double.parse(
              (duration.inMinutes / 60.0).toStringAsFixed(2),
            );
          }
        }
        hoursByTech.update(
          s.tecnicoId,
          (val) => val + horas,
          ifAbsent: () => horas,
        );
      }
      _dailyHours = hoursByTech;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading registered hours: $e');
      // Set empty state on error to avoid stale data
      _dailySessions = [];
      _dailyHours = {};
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
    notifyListeners();
  }
}
