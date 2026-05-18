import '../repositories/actividad_repository.dart';
import '../entities/actividad.dart';

/// Caso de uso para obtener todas las actividades de una empresa.
class ObtenerTodasActividades {
  final ActividadRepository _repo;
  ObtenerTodasActividades(this._repo);

  Future<List<Actividad>> call(String empresaId) {
    return _repo.obtenerTodasActividades(empresaId);
  }
}
