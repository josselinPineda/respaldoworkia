import '../../repositories/cliente_repository.dart';
import '../../../models/cliente.dart';

/// Caso de uso para obtener todos los clientes registrados.
///
/// Encapsula la llamada al [ClienteRepository] para recuperar la
/// lista completa de clientes.  Permite cambiar la fuente de

/// Caso de uso para obtener todos los clientes registrados.
///
/// Encapsula la llamada al [ClienteRepository] para recuperar la
/// lista completa de clientes.  Permite cambiar la fuente de
/// datos (por ejemplo, una API remota) sin afectar a la capa de
/// presentación.
class ObtenerClientes {
  final ClienteRepository _repository;
  ObtenerClientes(this._repository);

  Future<List<Cliente>> call(String empresaId) {
    return _repository.obtenerClientes(empresaId);
  }
}
