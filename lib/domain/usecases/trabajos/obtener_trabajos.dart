import '../../repositories/trabajo_repository.dart';
import '../../../models/job.dart';

/// Caso de uso para obtener todos los trabajos registrados.
class ObtenerTrabajos {
  final TrabajoRepository _repository;
  ObtenerTrabajos(this._repository);

  Future<List<Trabajo>> call(String empresaId) {
    return _repository.obtenerTrabajos(empresaId);
  }
}
