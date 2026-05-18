import '../repositories/actividad_repository.dart';

/// Caso de uso para eliminar una actividad por su ID (borrado lógico).
class EliminarActividad {
  final ActividadRepository _repo;
  EliminarActividad(this._repo);

  Future<void> call(String id, String actualizadoPor) {
    return _repo.eliminarActividad(id, actualizadoPor);
  }
}
