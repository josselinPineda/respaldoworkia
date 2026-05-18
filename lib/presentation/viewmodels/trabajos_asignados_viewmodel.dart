import 'package:flutter/foundation.dart';

import '../../domain/usecases/trabajos_asignados/obtener_trabajos_asignados.dart';
import '../../domain/usecases/trabajos_asignados/agregar_trabajo_asignado.dart';
import '../../domain/usecases/trabajos_asignados/actualizar_trabajo_asignado.dart';
import '../../domain/usecases/trabajos_asignados/cancelar_trabajo_asignado.dart';
import '../../domain/usecases/trabajos_asignados/buscar_trabajos_asignados.dart';
import '../../models/trabajo_asignado.dart';
import '../../features/activities/domain/entities/actividad.dart';

/// ViewModel para gestionar operaciones sobre trabajos asignados.
class TrabajosAsignadosViewModel extends ChangeNotifier {
  final ObtenerTrabajosAsignados _obtener;
  final AgregarTrabajoAsignado _agregar;
  final ActualizarTrabajoAsignado _actualizar;
  final CancelarTrabajoAsignado _cancelar;
  final BuscarTrabajosAsignados _buscar;

  TrabajosAsignadosViewModel(
    this._obtener,
    this._agregar,
    this._actualizar,
    this._cancelar,
    this._buscar,
  );

  List<TrabajoAsignado> _trabajos = [];
  List<TrabajoAsignado> _filtrados = [];
  bool _cargando = false;
  bool _buscando = false;
  String _lastQuery = '';

  /// Mapa de actividades por trabajo asignado, utilizado para
  /// cálculos locales (agenda) sin reconsultar el backend.
  final Map<String, List<Actividad>> _actividadesPorTrabajoAsignado = {};

  List<TrabajoAsignado> get trabajos => _buscando ? _filtrados : _trabajos;
  bool get cargando => _cargando;
  Map<String, List<Actividad>> get actividadesPorTrabajoAsignado =>
      _actividadesPorTrabajoAsignado;

  Future<void> cargarTrabajosAsignados(String empresaId) async {
    _cargando = true;
    notifyListeners();
    final todos = await _obtener(empresaId);
    _trabajos = todos.where((t) => t.activo).toList();
    _filtrados = [];
    _buscando = false;
    _cargando = false;
    notifyListeners();
  }

  Future<void> agregar(TrabajoAsignado trabajoAsignado) async {
    await _agregar(trabajoAsignado);
    await cargarTrabajosAsignados(trabajoAsignado.empresaId);
  }

  Future<void> actualizar(TrabajoAsignado trabajoAsignado) async {
    await _actualizar(trabajoAsignado);
    await cargarTrabajosAsignados(trabajoAsignado.empresaId);
  }

  /// Actualización optimista local para que la UI reaccione instantáneamente
  /// sin esperar a Firestore.
  void actualizarEstadoLocal(String id, String nuevoEstado, {String? tecnicoIdConHoras}) {
    final index = _trabajos.indexWhere((t) => t.id == id);
    if (index != -1) {
      final t = _trabajos[index];
      
      Map<String, double> nuevasHoras = Map.from(t.horasAcumuladas);
      if (tecnicoIdConHoras != null) {
        nuevasHoras[tecnicoIdConHoras] = (nuevasHoras[tecnicoIdConHoras] ?? 0.0) + 0.1; // Valor simulado
      }

      _trabajos[index] = t.copyWith(
        estado: nuevoEstado,
        horasAcumuladas: nuevasHoras,
      );
      notifyListeners();
    }
  }

  Future<void> cancelar(
    String id,
    String empresaId,
    String actualizadoPor,
  ) async {
    await _cancelar(id, actualizadoPor);
    await cargarTrabajosAsignados(empresaId);
  }

  Future<void> buscar(String consulta, String empresaId) async {
    _lastQuery = consulta;
    if (consulta.trim().isEmpty) {
      _filtrados = [];
      _buscando = false;
      notifyListeners();
    } else {
      _buscando = true;
      // No notificamos aquí para evitar parpadeos
      final resultados = await _buscar(consulta, empresaId);
      if (_lastQuery == consulta) {
        _filtrados = resultados;
        notifyListeners();
      }
    }
  }

  /// Almacena una actividad asociada a un trabajo asignado en el mapa local.
  void agregarActividad(String trabajoAsignadoId, Actividad actividad) {
    final lista = _actividadesPorTrabajoAsignado.putIfAbsent(
      trabajoAsignadoId,
      () => [],
    );
    lista.add(actividad);
    notifyListeners();
  }

  /// Limpia el estado del ViewModel.
  void limpiar() {
    _trabajos = [];
    _filtrados = [];
    _cargando = false;
    _buscando = false;
    _lastQuery = '';
    _actividadesPorTrabajoAsignado.clear();
    notifyListeners();
  }
}
