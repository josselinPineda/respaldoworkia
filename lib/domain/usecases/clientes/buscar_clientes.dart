import '../../repositories/cliente_repository.dart';
import '../../../models/cliente.dart';

/// Caso de uso para buscar clientes por nombre, razón social o
/// persona de contacto.
class BuscarClientes {
  final ClienteRepository _repository;
  BuscarClientes(this._repository);

  Future<List<Cliente>> call(String consulta, String empresaId) {
    return _repository.buscarClientes(consulta, empresaId);
  }
}
