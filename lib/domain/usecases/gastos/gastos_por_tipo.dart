import '../../repositories/gasto_repository.dart';
import '../../../models/gasto.dart';

/// Caso de uso para obtener los gastos de un tipo específico.
class GastosPorTipo {
  final GastoRepository _repository;
  GastosPorTipo(this._repository);

  Future<List<Gasto>> call(String tipoId, String empresaId) {
    return _repository.gastosPorTipo(tipoId, empresaId);
  }
}
