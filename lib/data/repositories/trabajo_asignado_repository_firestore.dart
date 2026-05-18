import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/trabajo_asignado_repository.dart';
import '../../models/trabajo_asignado.dart';

/// Implementación de [TrabajoAsignadoRepository] respaldada por Firebase Firestore.
///
/// Cada trabajo asignado vive como un documento en la colección
/// `trabajosAsignados`.  Este repositorio mapea documentos a
/// instancias de [TrabajoAsignado] y realiza la operación inversa
/// al crear o actualizar registros.
class TrabajoAsignadoRepositoryFirestore implements TrabajoAsignadoRepository {
  TrabajoAsignadoRepositoryFirestore({FirebaseFirestore? firestore})
    : _coleccion = (firestore ?? FirebaseFirestore.instance).collection(
        'trabajosAsignados',
      );

  final CollectionReference<Map<String, dynamic>> _coleccion;

  @override
  Future<List<TrabajoAsignado>> obtenerTrabajosAsignados(
    String empresaId,
  ) async {
    if (empresaId.isEmpty) throw ArgumentError('empresaId cannot be empty');
    final snapshot = await _coleccion
        .where('empresaId', isEqualTo: empresaId)
        .get();
    final asignados = snapshot.docs.map(_desdeDocumento).toList();
    return asignados;
  }

  @override
  Future<int> autoFinalizarTrabajosExpirados(
    String empresaId, {
    required int horasTolerancia,
    DateTime? now,
  }) async {
    if (empresaId.isEmpty) throw ArgumentError('empresaId cannot be empty');
    if (horasTolerancia <= 0) return 0;

    final DateTime current = now ?? DateTime.now();
    final snapshot = await _coleccion
        .where('empresaId', isEqualTo: empresaId)
        .get();
    if (snapshot.docs.isEmpty) return 0;

    final Map<String, Map<String, dynamic>> dataById = {
      for (final d in snapshot.docs) d.id: d.data(),
    };

    final asignados = snapshot.docs.map(_desdeDocumento).toList();

    final expired = asignados.where((a) {
      if (!a.activo) return false;
      if (a.estado != 'INICIADO') return false;

      final data = dataById[a.id] ?? const <String, dynamic>{};
      final sesionesActivas = (data['sesionesActivas'] as num?)?.toInt() ?? 0;
      if (sesionesActivas != 0) return false;

      final deadline = a.fechaFin.add(Duration(hours: horasTolerancia));
      return current.isAfter(deadline);
    }).toList();

    if (expired.isEmpty) return 0;

    final batch = _coleccion.firestore.batch();
    int updated = 0;
    for (final a in expired) {
      batch.update(_coleccion.doc(a.id), {
        'estado': 'FINALIZADO',
        'fechaActualizacion': Timestamp.fromDate(current),
      });
      updated++;
    }
    await batch.commit();
    return updated;
  }

  @override
  Future<void> agregarTrabajoAsignado(TrabajoAsignado trabajoAsignado) async {
    // Generar identificador si no viene definido.  Se utiliza un
    // prefijo "ASIG_" seguido del id del trabajo y del cliente para
    // evitar colisiones.  Se incluyen guiones bajos y la fecha en
    // milisegundos para distinguir múltiples asignaciones al mismo
    // cliente y trabajo.
    String id = trabajoAsignado.id;
    if (id.isEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      id =
          'ASIG_${trabajoAsignado.trabajoId}__'
          '${trabajoAsignado.clienteId}_$timestamp';
    }
    await _coleccion.doc(id).set(_aMapaFirestore(trabajoAsignado));
  }

  @override
  Future<void> actualizarTrabajoAsignado(
    TrabajoAsignado trabajoAsignado,
  ) async {
    if (trabajoAsignado.id.isEmpty) return;
    await _coleccion
        .doc(trabajoAsignado.id)
        .update(_aMapaFirestore(trabajoAsignado));
  }

  @override
  Future<void> cancelarTrabajoAsignado(String id, String actualizadoPor) async {
    if (id.isEmpty) return;
    try {
      await _coleccion.doc(id).update({
        'estado': 'Cancelado',
        'activo': false,
        'actualizadoPor': actualizadoPor,
        'fechaActualizacion': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Si el documento no existe, ignorar el error
      if (!e.toString().contains('not-found')) {
        rethrow;
      }
    }
  }

  @override
  Future<List<TrabajoAsignado>> buscarTrabajosAsignados(
    String consulta,
    String empresaId,
  ) async {
    final lower = consulta.trim().toLowerCase();
    if (lower.isEmpty) {
      return obtenerTrabajosAsignados(empresaId);
    }
    final asignados = await obtenerTrabajosAsignados(empresaId);
    return asignados
        .where(
          (a) =>
              a.trabajoId.toLowerCase().contains(lower) ||
              a.clienteId.toLowerCase().contains(lower) ||
              a.estado.toLowerCase().contains(lower),
        )
        .toList();
  }

  TrabajoAsignado _desdeDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final rawData = doc.data() ?? {};
    final data = <String, dynamic>{};
    rawData.forEach((key, value) {
      if (value is Timestamp) {
        data[key] = value.toDate();
      } else if (value is Map) {
        data[key] = value;
      } else if (value is List) {
        data[key] = List.from(value);
      } else {
        data[key] = value;
      }
    });
    return TrabajoAsignado.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> _aMapaFirestore(TrabajoAsignado trabajo) {
    // Utilizar el método toJson del modelo para convertir a mapa.
    // El modelo se encarga de convertir fechas a Timestamps y de
    // omitir campos que no corresponden a Firestore.
    return trabajo.toJson();
  }
}
