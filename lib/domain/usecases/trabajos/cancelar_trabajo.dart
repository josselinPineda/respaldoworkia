import '../../repositories/trabajo_repository.dart';

/// Caso de uso para cancelar (inactivar) un trabajo.
class CancelarTrabajo {
  final TrabajoRepository _repository;
  CancelarTrabajo(this._repository);

  Future<void> call(String id, String actualizadoPor) {
    return _repository.cancelarTrabajo(id, actualizadoPor);
  }
}
