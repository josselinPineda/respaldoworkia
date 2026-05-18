import '../../repositories/gasto_repository.dart';
import '../../../models/tipo_gasto.dart';

/// Caso de uso para obtener la lista de tipos de gasto disponibles.
///
/// Utiliza el repositorio de gastos para recuperar las categorías
/// definidas como materiales, combustible, salarios, etc.  Esto
/// permite a las vistas mostrar nombres descriptivos y ofrecer
/// opciones al registrar gastos.
class ObtenerTiposGasto {
  final GastoRepository _repository;
  ObtenerTiposGasto(this._repository);
  Future<List<TipoGasto>> call(String empresaId) {
    return _repository.obtenerTipos(empresaId);
  }
}