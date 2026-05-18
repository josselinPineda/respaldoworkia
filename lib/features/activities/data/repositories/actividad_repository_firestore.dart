import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/actividad_repository.dart';
import '../../domain/entities/actividad.dart';
import '../models/actividad_model.dart';

/// Implementación de [ActividadRepository] respaldada por Firebase Firestore.
/// Maneja el CRUD de actividades asociadas a trabajos asignados,
/// garantizando el filtrado por empresa.
class ActividadRepositoryFirestore implements ActividadRepository {
  ActividadRepositoryFirestore({FirebaseFirestore? firestore})
    : _coleccion = (firestore ?? FirebaseFirestore.instance).collection(
        'actividades',
      );

  final CollectionReference<Map<String, dynamic>> _coleccion;

  @override
  Future<List<Actividad>> obtenerActividades(
    String trabajoAsignadoId,
    String empresaId,
  ) async {
    if (empresaId.isEmpty) throw ArgumentError('empresaId cannot be empty');
    final snapshot = await _coleccion
        .where('empresaId', isEqualTo: empresaId)
        .where('trabajoAsignadoId', isEqualTo: trabajoAsignadoId)
        .where('activo', isEqualTo: true)
        .get();

    final actividades = snapshot.docs.map((doc) => ActividadModel.fromJson(doc.data(), id: doc.id)).toList();
    actividades.sort((a, b) => b.fechaActividad.compareTo(a.fechaActividad));
    return actividades;
  }

  @override
  Future<List<Actividad>> obtenerTodasActividades(String empresaId) async {
    if (empresaId.isEmpty) throw ArgumentError('empresaId cannot be empty');

    final snapshot = await _coleccion
        .where('empresaId', isEqualTo: empresaId)
        .where('activo', isEqualTo: true)
        .get();

    final actividades = snapshot.docs.map((doc) => ActividadModel.fromJson(doc.data(), id: doc.id)).toList();
    actividades.sort((a, b) => b.fechaActividad.compareTo(a.fechaActividad));
    return actividades;
  }

  @override
  Future<void> agregarActividad(Actividad actividad) async {
    final String id;
    if (actividad.id.isNotEmpty) {
      id = actividad.id;
    } else {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      id = 'ACT_${actividad.trabajoAsignadoId}_$timestamp';
    }
    
    final model = ActividadModel.fromEntity(actividad);
    await _coleccion.doc(id).set(model.toFirestore());
  }

  @override
  Future<void> actualizarActividad(Actividad actividad) async {
    if (actividad.id.isEmpty) return;
    final model = ActividadModel.fromEntity(actividad);
    await _coleccion.doc(actividad.id).update(model.toFirestore());
  }

  @override
  Future<void> eliminarActividad(String id, String actualizadoPor) async {
    if (id.isEmpty) return;
    await _coleccion.doc(id).update({
      'activo': false,
      'actualizadoPor': actualizadoPor,
      'fechaActualizacion': Timestamp.fromDate(DateTime.now()),
    });
  }
}
