import '../../repositories/gasto_repository.dart';
import '../../../models/tipo_gasto.dart';

class ActualizarTipoGasto {
  final GastoRepository _repository;
  ActualizarTipoGasto(this._repository);
  Future<void> call(TipoGasto tipo) {
    return _repository.actualizarTipoGasto(tipo);
  }
}
