import '../../repositories/gasto_repository.dart';
import '../../../models/gasto.dart';

/// Caso de uso para registrar un nuevo gasto.
class AgregarGasto {
  final GastoRepository _repository;
  AgregarGasto(this._repository);

  Future<void> call(Gasto gasto) {
    return _repository.agregarGasto(gasto);
  }
}