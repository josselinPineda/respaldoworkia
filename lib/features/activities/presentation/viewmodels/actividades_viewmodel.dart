import 'package:flutter/foundation.dart';

import '../../domain/usecases/obtener_actividades.dart';
import '../../domain/usecases/obtener_todas_actividades.dart';
import '../../domain/usecases/agregar_actividad.dart';
import '../../domain/usecases/actualizar_actividad.dart';
import '../../domain/usecases/eliminar_actividad.dart';
import '../../domain/entities/actividad.dart';

/// ViewModel encargado de gestionar las actividades registradas
/// para trabajos asignados.
class ActividadesViewModel extends ChangeNotifier {
  final ObtenerActividades _obtener;
  final ObtenerTodasActividades _obtenerTodas;
  final AgregarActividad _agregar;
  final ActualizarActividad _actualizar;
  final EliminarActividad _eliminar;

  ActividadesViewModel(
    this._obtener,
    this._obtenerTodas,
    this._agregar,
    this._actualizar,
    this._eliminar,
  );

  /// Mapa de actividades por trabajo asignado.
  final Map<String, List<Actividad>> _actividadesPorAsignacion = {};

  Map<String, List<Actividad>> get actividadesPorAsignacion =>
      _actividadesPorAsignacion;

  /// Indica si se está cargando información desde la base de datos.
  bool _cargando = false;
  bool get cargando => _cargando;

  /// Devuelve la lista de actividades para un trabajo asignado.
  List<Actividad> obtenerActividades(String trabajoAsignadoId) {
    return _actividadesPorAsignacion[trabajoAsignadoId] ?? [];
  }

  /// Carga las actividades desde el repositorio para el trabajo asignado.
  Future<void> cargarActividades(
    String trabajoAsignadoId,
    String empresaId,
  ) async {
    _cargando = true;
    notifyListeners();

    final actividades = await _obtener.call(trabajoAsignadoId, empresaId);

    _actividadesPorAsignacion[trabajoAsignadoId] = actividades
        .where((a) => a.activo)
        .toList();
    _cargando = false;
    notifyListeners();
  }

  /// Agrega una nueva actividad.
  Future<void> agregar(Actividad actividad) async {
    await _agregar.call(actividad);
    await cargarActividades(actividad.trabajoAsignadoId, actividad.empresaId);
  }

  /// Actualiza una actividad existente.
  Future<void> actualizar(Actividad actividad) async {
    await _actualizar.call(actividad);
    await cargarActividades(actividad.trabajoAsignadoId, actividad.empresaId);
  }

  /// Elimina una actividad por su ID.
  Future<void> eliminar(
    String id,
    String trabajoAsignadoId,
    String empresaId,
    String actualizadoPor,
  ) async {
    await _eliminar.call(id, actualizadoPor);
    await cargarActividades(trabajoAsignadoId, empresaId);
  }

  /// Carga todas las actividades de la empresa.
  Future<void> cargarTodasActividades(String empresaId) async {
    _cargando = true;
    notifyListeners();

    final actividades = await _obtenerTodas.call(empresaId);

    for (final actividad in actividades) {
      if (!actividad.activo) continue;
      if (_actividadesPorAsignacion.containsKey(actividad.trabajoAsignadoId)) {
        final lista = _actividadesPorAsignacion[actividad.trabajoAsignadoId]!;
        if (!lista.any((a) => a.id == actividad.id)) {
          lista.add(actividad);
        }
      } else {
        _actividadesPorAsignacion[actividad.trabajoAsignadoId] = [actividad];
      }
    }

    _cargando = false;
    notifyListeners();
  }

  /// Limpia el estado del ViewModel.
  void limpiar() {
    _actividadesPorAsignacion.clear();
    _cargando = false;
    notifyListeners();
  }
}
