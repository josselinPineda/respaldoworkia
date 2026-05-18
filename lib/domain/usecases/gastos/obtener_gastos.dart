import '../../repositories/gasto_repository.dart';
import '../../../models/gasto.dart';

/// Caso de uso para obtener todos los gastos registrados.
class ObtenerGastos {
  final GastoRepository _repository;
  ObtenerGastos(this._repository);

  Future<List<Gasto>> call(String empresaId) {
    return _repository.obtenerGastos(empresaId);
  }
}
