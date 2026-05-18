import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:workia/domain/repositories/sesion_trabajo_repository.dart';
import 'package:workia/models/sesion_trabajo.dart';

class SesionTrabajoRepositoryFirestore implements SesionTrabajoRepository {
  final FirebaseFirestore _firestore;

  SesionTrabajoRepositoryFirestore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _sesionesCollection =>
      _firestore.collection('sesiones_trabajo');
  CollectionReference get _asignacionesCollection =>
      _firestore.collection('trabajosAsignados');

  @override
  Stream<List<SesionTrabajo>> getSesionesPorAsignacion(
    String trabajoAsignadoId,
  ) {
    return _sesionesCollection
        .where('trabajoAsignadoId', isEqualTo: trabajoAsignadoId)
        // .orderBy('inicio', descending: true)  <-- Remover para evitar indice compuesto
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return SesionTrabajo.fromJson(data);
          }).toList();

          // Ordenar en memoria
          docs.sort((a, b) => b.inicio.compareTo(a.inicio));
          return docs;
        });
  }

  @override
  String generateId() {
    return _sesionesCollection.doc().id;
  }

  @override
  Future<void> iniciarSesion(
    String trabajoAsignadoId,
    String tecnicoId,
    String trabajoId, {
    String? sesionId,
    required String empresaId,
  }) async {
    final batch = _firestore.batch();
    // Usar ID proporcionado o generar uno nuevo
    final newSessionRef = sesionId != null
        ? _sesionesCollection.doc(sesionId)
        : _sesionesCollection.doc();

    final sesion = SesionTrabajo(
      id: newSessionRef.id,
      trabajoAsignadoId: trabajoAsignadoId,
      tecnicoId: tecnicoId,
      inicio: DateTime.now(),
      empresaId: empresaId,
    );

    batch.set(newSessionRef, sesion.toJson());

    // Actualizar estado del trabajoAsignado a 'INICIADO' si está pendiente (Optimistic Update)
    final asigRef = _asignacionesCollection.doc(trabajoAsignadoId);
    batch.update(asigRef, {
      'sesionesActivas': FieldValue.increment(1),
      'actualizadoPor': tecnicoId,
    });

    await batch.commit();
  }

  @override
  Future<void> finalizarSesion(
    String sesionId,
    String trabajoAsignadoId,
  ) async {
    return _firestore.runTransaction((transaction) async {
      debugPrint(
        'DEBUG: Intentando finalizar sesión ID: "$sesionId"',
      ); // LOG DEBUG
      final sessionRef = _sesionesCollection.doc(sesionId);
      final asigRef = _asignacionesCollection.doc(trabajoAsignadoId);

      // 1. LEER TODO (READS)
      final sessionSnapshot = await transaction.get(sessionRef);
      if (!sessionSnapshot.exists) {
        throw Exception('Sesión no encontrada');
      }
      final asigSnapshot = await transaction.get(asigRef);

      // 2. CÁLCULOS
      final sessionData = sessionSnapshot.data() as Map<String, dynamic>;
      final inicio = (sessionData['inicio'] as Timestamp).toDate();
      final fin = DateTime.now();
      final duration = fin.difference(inicio);
      final horas = double.parse(
        (duration.inMinutes / 60.0).toStringAsFixed(2),
      );

      // 3. ACTUALIZAR TODO (WRITES)
      // Actualizar Sesión
      transaction.update(sessionRef, {
        'fin': Timestamp.fromDate(fin),
        'horas': horas,
      });

      // Actualizar acumulado en TrabajoAsignado
      if (asigSnapshot.exists) {
        final asigData = asigSnapshot.data() as Map<String, dynamic>;
        final tecnicoId = sessionData['tecnicoId'] as String;

        // Obtener mapa actual o crear uno nuevo
        Map<String, dynamic> horasAcumuladas = {};
        if (asigData['horasAcumuladas'] != null) {
          horasAcumuladas = Map<String, dynamic>.from(
            asigData['horasAcumuladas'],
          );
        }

        final currentTotal = (horasAcumuladas[tecnicoId] as num?) ?? 0.0;
        horasAcumuladas[tecnicoId] = double.parse(
          (currentTotal + horas).toStringAsFixed(2),
        );

        int currentActive = (asigData['sesionesActivas'] as num?)?.toInt() ?? 1;
        // Decrementar, pero evitar negativos (safety)
        int newActive = currentActive > 0 ? currentActive - 1 : 0;

        String newStatus = asigData['estado'] as String;
        // Auto-Finalización: SOLO si no hay sesiones activas Y todos han trabajado
        if (newActive == 0 && newStatus == 'INICIADO') {
          final assignedTechs = List<String>.from(
            asigData['tecnicosAsignados'] ?? [],
          );
          // Verificar si todos tienen horas registradas (claves en horasAcumuladas)
          // Nota: horasAcumuladas ya tiene el update actual incluido
          final techWithHours = horasAcumuladas.keys.toSet();
          final allWorked = assignedTechs.every(
            (tId) => techWithHours.contains(tId),
          );

          if (allWorked) {
            newStatus = 'FINALIZADO';
          }
        }

        transaction.update(asigRef, {
          'horasAcumuladas': horasAcumuladas,
          'sesionesActivas': newActive,
          'estado': newStatus,
          'actualizadoPor': tecnicoId,
        });
      }
    });
  }

  @override
  Future<SesionTrabajo?> obtenerSesionActiva(
    String trabajoAsignadoId,
    String tecnicoId,
  ) async {
    final snapshot = await _sesionesCollection
        .where('trabajoAsignadoId', isEqualTo: trabajoAsignadoId)
        .where('tecnicoId', isEqualTo: tecnicoId)
        .where('fin', isNull: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final data = snapshot.docs.first.data() as Map<String, dynamic>;
    data['id'] = snapshot.docs.first.id;
    return SesionTrabajo.fromJson(data);
  }

  @override
  Future<List<SesionTrabajo>> obtenerSesionesPorEmpresaYFecha(
    String empresaId,
    DateTime fecha,
  ) async {
    final start = DateTime(fecha.year, fecha.month, fecha.day);
    final end = start.add(const Duration(days: 1));

    // Realizar búsqueda simple y filtrar en memoria para evitar índices compuestos
    final snapshot = await _sesionesCollection
        .where('empresaId', isEqualTo: empresaId)
        .get();

    final allSessions = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return SesionTrabajo.fromJson(data);
    }).toList();

    return allSessions.where((s) {
      return (s.inicio.isAfter(start) || s.inicio.isAtSameMomentAs(start)) &&
             s.inicio.isBefore(end);
    }).toList();
  }

  @override
  Future<List<SesionTrabajo>> obtenerTodasSesionesPorEmpresa(
    String empresaId,
  ) async {
    // Busca todas las sesiones de la empresa y ordena en memoria para evitar índice compuesto
    final snapshot = await _sesionesCollection
        .where('empresaId', isEqualTo: empresaId)
        .get();

    final list = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return SesionTrabajo.fromJson(data);
    }).toList();

    list.sort((a, b) => b.inicio.compareTo(a.inicio));
    return list;
  }

}
