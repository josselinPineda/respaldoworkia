import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:workia/domain/repositories/problema_repository.dart';
import 'package:workia/models/problem.dart';

class ProblemaRepositoryFirestore implements ProblemaRepository {
  final FirebaseFirestore _firestore;

  ProblemaRepositoryFirestore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _coleccion => _firestore.collection('problemas');

  @override
  Future<List<Problema>> obtenerTodosLosProblemas(String empresaId) async {
    final snapshot = await _coleccion
        .where('empresaId', isEqualTo: empresaId)
        .where('activo', isEqualTo: true)
        .get();

    final problemas = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Problema.fromJson(data);
    }).toList();

    problemas.sort((a, b) => (b.fechaCreacion ?? DateTime.now()).compareTo(a.fechaCreacion ?? DateTime.now()));
    return problemas;
  }

  @override
  Future<List<Problema>> obtenerProblemasPendientes(String empresaId) async {
    final snapshot = await _coleccion
        .where('empresaId', isEqualTo: empresaId)
        .where('activo', isEqualTo: true)
        .where('estado', isEqualTo: 'pendiente')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Problema.fromJson(data);
    }).toList();
  }

  @override
  Future<void> agregarProblema(Problema problema) async {
    try {
      print('FIREBASE: Iniciando escritura...');
      final data = problema.toJson();
      
      // Forzar el uso de Timestamps para Firestore (Evita bloqueos de serialización)
      data['fechaCreacion'] = Timestamp.fromDate(DateTime.now());
      data['fechaActualizacion'] = Timestamp.fromDate(DateTime.now());

      final String id = 'PRB_${DateTime.now().millisecondsSinceEpoch}';
      
      await _coleccion.doc(id).set(data).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw 'Timeout: Firebase no responde',
      );
      
      print('FIREBASE: Escritura exitosa');
    } catch (e) {
      print('FIREBASE ERROR: $e');
      rethrow;
    }
  }

  @override
  Future<void> actualizarProblema(Problema problema) async {
    final data = problema.toJson();
    data['fechaActualizacion'] = Timestamp.fromDate(DateTime.now());
    await _coleccion.doc(problema.id).update(data);
  }

  @override
  Future<void> eliminarProblema(String id, String actualizadoPor) async {
    await _coleccion.doc(id).update({
      'activo': false,
      'actualizadoPorId': actualizadoPor,
      'fechaActualizacion': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> ignorarProblemaPorId(String id, String empresaId, String userId) async {
    await _coleccion.doc(id).update({
      'estado': 'ignorado',
      'actualizadoPorId': userId,
      'fechaActualizacion': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> resolverProblemaPorId(
    String id,
    String empresaId,
    String userId,
    String userRole,
  ) async {
    await _coleccion.doc(id).update({
      'estado': 'resuelto',
      'resuelto': true,
      'resueltoPorId': userId,
      'actualizadoPorId': userId,
      'fechaActualizacion': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> ignorarProblema(int indice, String empresaId, String userName) async {
    // Implementación deprecated pero requerida por la interfaz
  }

  @override
  Future<void> resolverProblema(int indice, String empresaId, String userName) async {
    // Implementación deprecated pero requerida por la interfaz
  }
}
