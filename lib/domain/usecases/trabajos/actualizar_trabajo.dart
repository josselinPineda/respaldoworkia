import '../../repositories/trabajo_repository.dart';
import '../../../models/job.dart';

/// Caso de uso para actualizar un trabajo existente.
class ActualizarTrabajo {
  final TrabajoRepository _repository;
  ActualizarTrabajo(this._repository);

  Future<void> call(Trabajo trabajo) {
    return _repository.actualizarTrabajo(trabajo);
  }
}