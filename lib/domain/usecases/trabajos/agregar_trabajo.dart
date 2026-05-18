import '../../repositories/trabajo_repository.dart';
import '../../../models/job.dart';

/// Caso de uso para agregar un nuevo trabajo.
class AgregarTrabajo {
  final TrabajoRepository _repository;
  AgregarTrabajo(this._repository);

  Future<void> call(Trabajo trabajo) {
    return _repository.agregarTrabajo(trabajo);
  }
}