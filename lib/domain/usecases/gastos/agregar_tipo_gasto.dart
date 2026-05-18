import '../../repositories/gasto_repository.dart';
import '../../../models/tipo_gasto.dart';

class AgregarTipoGasto {
  final GastoRepository _repository;
  AgregarTipoGasto(this._repository);
  Future<void> call(TipoGasto tipo) {
    return _repository.agregarTipoGasto(tipo);
  }
}
