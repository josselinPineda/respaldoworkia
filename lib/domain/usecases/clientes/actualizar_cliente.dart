import '../../repositories/cliente_repository.dart';
import '../../../models/cliente.dart';

/// Caso de uso para actualizar un cliente existente.
///
/// Actualiza los datos de un [Cliente] delegando en
/// [ClienteRepository].  Si el cliente no existe se ignora la
/// operación.  Esta clase centraliza la lógica de actualización
/// para facilitar modificaciones futuras.
class ActualizarCliente {
  final ClienteRepository _repository;
  ActualizarCliente(this._repository);

  Future<void> call(Cliente cliente) {
    return _repository.actualizarCliente(cliente);
  }
}