import '../repositories/actividad_repository.dart';
import '../entities/actividad.dart';

/// Caso de uso para agregar una nueva actividad.
class AgregarActividad {
  final ActividadRepository _repo;
  AgregarActividad(this._repo);

  Future<void> call(Actividad actividad) {
    return _repo.agregarActividad(actividad);
  }
}
