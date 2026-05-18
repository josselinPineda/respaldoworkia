import '../../repositories/cliente_repository.dart';

/// Caso de uso para inactivar (eliminar lógicamente) un cliente.
///
/// Acepta un id de cliente y utiliza [ClienteRepository] para
/// marcarlo como inactivo.  La eliminación física no se realiza
/// para conservar el historial.
class InactivarCliente {
  final ClienteRepository _repository;
  InactivarCliente(this._repository);

  Future<void> call(String id, String actualizadoPor) {
    return _repository.inactivarCliente(id, actualizadoPor);
  }
}
