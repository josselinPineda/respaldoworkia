import '../../repositories/gasto_repository.dart';
import '../../../models/gasto.dart';

/// Caso de uso para obtener los gastos registrados dentro de un
/// rango de fechas.
class GastosPorRango {
  final GastoRepository _repository;
  GastosPorRango(this._repository);

  Future<List<Gasto>> call(DateTime inicio, DateTime fin, String empresaId) {
    return _repository.gastosPorRango(inicio, fin, empresaId);
  }
}
