import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/cliente_repository.dart';
import '../../models/cliente.dart';

/// Implementación de [ClienteRepository] que utiliza Firebase
/// Firestore como backend.  Cada cliente se almacena como un
/// documento en la colección `clientes`.  Los métodos realizan
/// operaciones CRUD básicas y aprovechan los helpers `fromJson` y
/// `toJson` del modelo [Cliente] para la conversión entre objetos
/// Dart y mapas de Firestore.
class ClienteRepositoryFirestore implements ClienteRepository {
  final CollectionReference<Map<String, dynamic>> _coleccion = FirebaseFirestore
      .instance
      .collection('clientes');

  @override
  Future<List<Cliente>> obtenerClientes(String empresaId) async {
    try {
      if (empresaId.isEmpty) throw ArgumentError('empresaId cannot be empty');
      final snapshot = await _coleccion
          .where('empresaId', isEqualTo: empresaId)
          .get();
      return snapshot.docs
          .map((doc) => Cliente.fromJson(doc.data()..['id'] = doc.id))
          .toList();
    } catch (e) {
      // En un entorno real se debería manejar el error de manera
      // apropiada, como enviar un mensaje al ViewModel.
      rethrow;
    }
  }

  @override
  Future<void> agregarCliente(Cliente cliente) async {
    try {
      // Generar un identificador personalizado para el cliente basado en su nombre.
      // Se reemplazan los espacios por guiones bajos y se convierte a mayúsculas
      // anteponiendo el prefijo "CL_" para seguir la nomenclatura solicitada.
      final String id =
          'CL_${cliente.nombre.replaceAll(RegExp(r'\s+'), '_').toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}';
      final data = cliente.toJson();
      // Remover el campo 'id' del objeto ya que Firestore usa el ID del documento
      data.remove('id');
      // Convertir campos de fecha a Timestamp para Firestore.  Si las fechas
      // no están presentes se utilizan valores por defecto.
      if (cliente.fechaCreacion != null) {
        data['fechaCreacion'] = Timestamp.fromDate(cliente.fechaCreacion!);
      } else {
        data['fechaCreacion'] = Timestamp.fromDate(DateTime.now());
      }
      data['fechaActualizacion'] = Timestamp.fromDate(
        cliente.fechaActualizacion ?? DateTime.now(),
      );
      await _coleccion.doc(id).set(data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> actualizarCliente(Cliente cliente) async {
    if (cliente.id.isEmpty) return;
    try {
      final data = cliente.toJson();
      // Convertir fechas a Timestamp y establecer fechaActualizacion
      if (cliente.fechaCreacion != null) {
        data['fechaCreacion'] = Timestamp.fromDate(cliente.fechaCreacion!);
      }
      data['fechaActualizacion'] = Timestamp.fromDate(
        cliente.fechaActualizacion ?? DateTime.now(),
      );
      await _coleccion.doc(cliente.id).update(data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> inactivarCliente(String id, String actualizadoPor) async {
    try {
      await _coleccion.doc(id).update({
        'activo': false,
        'actualizadoPor': actualizadoPor,
        'fechaActualizacion': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Cliente>> buscarClientes(
    String consulta,
    String empresaId,
  ) async {
    try {
      final lower = consulta.trim().toLowerCase();
      if (lower.isEmpty) {
        return obtenerClientes(empresaId);
      }
      final clientes = await obtenerClientes(empresaId);
      return clientes.where((c) {
        return c.nombre.toLowerCase().contains(lower) ||
            c.razonSocial.toLowerCase().contains(lower) ||
            c.personaContacto.toLowerCase().contains(lower) ||
            c.telefono.toLowerCase().contains(lower) ||
            c.correo.toLowerCase().contains(lower) ||
            c.direccion.toLowerCase().contains(lower);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}
