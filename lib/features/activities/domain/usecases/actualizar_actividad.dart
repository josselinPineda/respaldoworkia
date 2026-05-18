import '../repositories/actividad_repository.dart';
import '../entities/actividad.dart';

/// Caso de uso para actualizar una actividad existente.
class ActualizarActividad {
  final ActividadRepository _repo;
  ActualizarActividad(this._repo);

  Future<void> call(Actividad actividad) {
    return _repo.actualizarActividad(actividad);
  }
}
