import '../../domain/repositories/cliente_repository.dart';
import '../../models/cliente.dart';

/// Implementación en memoria del repositorio de clientes.
///
/// Almacena la lista de clientes en una colección interna y realiza
/// operaciones básicas.  En una implementación real se sustituiría
/// por consultas a una base de datos o a un servicio de backend.
class ClienteRepositoryImpl implements ClienteRepository {
  final List<Cliente> _clientes = [];

  String _generarId() => DateTime.now().millisecondsSinceEpoch.toString();

  @override
  Future<List<Cliente>> obtenerClientes(String empresaId) async {
    return List.unmodifiable(
      _clientes.where((c) => c.empresaId == empresaId || c.empresaId.isEmpty),
    );
  }

  @override
  Future<void> agregarCliente(Cliente cliente) async {
    final nuevo = cliente.id.isEmpty
        ? Cliente(
            id: _generarId(),
            nombre: cliente.nombre,
            razonSocial: cliente.razonSocial,
            personaContacto: cliente.personaContacto,
            telefono: cliente.telefono,
            correo: cliente.correo,
            direccion: cliente.direccion,
            activo: cliente.activo,
            lat: cliente.lat,
            lng: cliente.lng,
            empresaId: cliente.empresaId,
          )
        : cliente;
    _clientes.add(nuevo);
  }

  @override
  Future<void> actualizarCliente(Cliente actualizado) async {
    final index = _clientes.indexWhere((c) => c.id == actualizado.id);
    if (index != -1) {
      _clientes[index] = actualizado;
    }
  }

  @override
  Future<void> inactivarCliente(String id, String actualizadoPor) async {
    final index = _clientes.indexWhere((c) => c.id == id);
    if (index != -1) {
      final c = _clientes[index];
      final actualizado = Cliente(
        id: c.id,
        nombre: c.nombre,
        razonSocial: c.razonSocial,
        personaContacto: c.personaContacto,
        telefono: c.telefono,
        correo: c.correo,
        direccion: c.direccion,
        activo: false,
        lat: c.lat,
        lng: c.lng,
        empresaId: c.empresaId,
        actualizadoPor: actualizadoPor,
      );
      _clientes[index] = actualizado;
    }
  }

  @override
  Future<List<Cliente>> buscarClientes(
    String consulta,
    String empresaId,
  ) async {
    final lower = consulta.toLowerCase();
    return _clientes
        .where(
          (c) =>
              (c.empresaId == empresaId || c.empresaId.isEmpty) &&
              (c.nombre.toLowerCase().contains(lower) ||
                  c.razonSocial.toLowerCase().contains(lower) ||
                  c.personaContacto.toLowerCase().contains(lower)),
        )
        .toList();
  }
}
