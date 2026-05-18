import '../../repositories/cliente_repository.dart';
import '../../../models/cliente.dart';

/// Caso de uso para agregar un nuevo cliente.
///
/// Recibe un objeto [Cliente] y delega la creación al
/// [ClienteRepository].  Al encapsular esta lógica en un caso de
/// uso se puede validar o transformar los datos antes de
/// enviarlos al repositorio en el futuro.
class AgregarCliente {
  final ClienteRepository _repository;
  AgregarCliente(this._repository);

  Future<void> call(Cliente cliente) {
    return _repository.agregarCliente(cliente);
  }
}