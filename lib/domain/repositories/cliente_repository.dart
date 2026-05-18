import '../../models/cliente.dart';

/// Contrato que define las operaciones que pueden realizarse sobre clientes.
///
/// Al definir un repositorio se desacopla la obtención de datos de la
/// interfaz de usuario.  Las implementaciones pueden usar Firestore,
/// SQLite o listas en memoria sin afectar al resto de la aplicación.
abstract class ClienteRepository {
  /// Obtiene la lista de clientes de una empresa específica.
  Future<List<Cliente>> obtenerClientes(String empresaId);

  /// Agrega un nuevo cliente.
  Future<void> agregarCliente(Cliente cliente);

  /// Actualiza un cliente existente.
  Future<void> actualizarCliente(Cliente cliente);

  /// Inactiva (elimina lógicamente) un cliente por su ID.
  Future<void> inactivarCliente(String id, String actualizadoPor);

  /// Busca clientes de una empresa cuyo nombre, razón social o persona de contacto
  /// coincida con la consulta.
  Future<List<Cliente>> buscarClientes(String consulta, String empresaId);
}
