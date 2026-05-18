import '../repositories/actividad_repository.dart';
import '../entities/actividad.dart';

/// Caso de uso para obtener las actividades de un trabajo asignado.
class ObtenerActividades {
  final ActividadRepository _repo;
  ObtenerActividades(this._repo);

  Future<List<Actividad>> call(String trabajoAsignadoId, String empresaId) {
    return _repo.obtenerActividades(trabajoAsignadoId, empresaId);
  }
}
