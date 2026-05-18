import '../../repositories/gasto_repository.dart';
import '../../../models/gasto.dart';

/// Caso de uso para actualizar un gasto existente.
class ActualizarGasto {
  final GastoRepository _repository;
  ActualizarGasto(this._repository);

  Future<void> call(Gasto gasto) {
    return _repository.actualizarGasto(gasto);
  }
}