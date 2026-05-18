import '../../repositories/trabajo_repository.dart';
import '../../../models/job.dart';

/// Caso de uso para buscar trabajos por título, cliente u otros
/// criterios establecidos en el repositorio.
class BuscarTrabajos {
  final TrabajoRepository _repository;
  BuscarTrabajos(this._repository);

  Future<List<Trabajo>> call(String consulta, String empresaId) {
    return _repository.buscarTrabajos(consulta, empresaId);
  }
}
