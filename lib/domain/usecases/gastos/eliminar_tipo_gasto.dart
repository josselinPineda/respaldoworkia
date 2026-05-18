import '../../repositories/gasto_repository.dart';

class EliminarTipoGasto {
  final GastoRepository _repository;
  EliminarTipoGasto(this._repository);
  Future<void> call(String id) {
    return _repository.eliminarTipoGasto(id);
  }
}
