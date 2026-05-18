import '../../repositories/gasto_repository.dart';

/// Caso de uso para eliminar un gasto por su identificador.
///
/// El repositorio implementa la eliminación lógica o física
/// según su naturaleza.  Desde la capa de presentación solo se
/// pasa el id.
class EliminarGasto {
  final GastoRepository _repository;
  EliminarGasto(this._repository);

  Future<void> call(String id, String actualizadoPor) {
    return _repository.eliminarGasto(id, actualizadoPor);
  }
}
