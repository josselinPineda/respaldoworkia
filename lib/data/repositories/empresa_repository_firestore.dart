import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/empresa_repository.dart';
import '../../models/empresa.dart';

/// Implementación de [EmpresaRepository] respaldada por Firebase Firestore.
///
/// Los datos de la empresa se almacenan en la colección `empresa`.  Se
/// asume que habrá un único documento en esta colección que
/// representa a la empresa actual.  Si existieran varios registros
/// este repositorio devolverá el primero que encuentre.  Las
/// actualizaciones se realizan sobre el documento correspondiente.
class EmpresaRepositoryFirestore implements EmpresaRepository {
  EmpresaRepositoryFirestore({FirebaseFirestore? firestore})
    : _coleccion = (firestore ?? FirebaseFirestore.instance).collection(
        // Usar `empresa` para compatibilidad con reglas/instalaciones existentes.
        // Si en Firestore existe la colección `empresas`, se recomienda alinear
        // reglas y datos, pero este fallback evita permission-denied en apps ya instaladas.
        'empresa',
      );

  final CollectionReference<Map<String, dynamic>> _coleccion;

  @override
  Future<void> actualizarEmpresa(Empresa empresa) async {
    final id = empresa.id;
    final data = empresa.toJson();

    // Si el admin deja la tasa de cambio vacía, debemos eliminarla del documento
    // (con merge:true, un null/ausente no borra el campo).
    if (empresa.tasaCambio == null) {
      data['tasaCambio'] = FieldValue.delete();
    }

    // Convertir fechas a Timestamp
    if (empresa.fechaCreacion != null) {
      data['fechaCreacion'] = Timestamp.fromDate(empresa.fechaCreacion!);
    }
    data['fechaActualizacion'] = Timestamp.fromDate(
      empresa.fechaActualizacion ?? DateTime.now(),
    );
    if (id.isNotEmpty) {
      await _coleccion.doc(id).set(data, SetOptions(merge: true));
    } else {
      // Si no hay id, crea un nuevo documento
      await _coleccion.add(data);
    }
  }

  @override
  Future<List<Empresa>> obtenerEmpresas() async {
    final snapshot = await _coleccion.where('activo', isEqualTo: true).get();
    return snapshot.docs
        .map((doc) => Empresa.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<Empresa?> obtenerEmpresa(String id) async {
    // Caso normal: el `id` de la empresa es el ID del documento.
    final doc = await _coleccion.doc(id).get();
    if (doc.exists) {
      return Empresa.fromJson({...doc.data()!, 'id': doc.id});
    }

    // Fallback: algunos datos pueden guardar el ID lógico en el campo `id`
    // pero usar un ID de documento diferente.
    final snapshot = await _coleccion.where('id', isEqualTo: id).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      final found = snapshot.docs.first;
      return Empresa.fromJson({...found.data(), 'id': found.id});
    }

    // Segundo fallback: si el proyecto usa la colección `empresas`,
    // intentar leer desde allí para mantener compatibilidad.
    final altCol = (FirebaseFirestore.instance).collection('empresas');
    final altDoc = await altCol.doc(id).get();
    if (altDoc.exists) {
      return Empresa.fromJson({...altDoc.data()!, 'id': altDoc.id});
    }
    final altSnap = await altCol.where('id', isEqualTo: id).limit(1).get();
    if (altSnap.docs.isEmpty) return null;
    final altFound = altSnap.docs.first;
    return Empresa.fromJson({...altFound.data(), 'id': altFound.id});
  }

  @override
  Future<bool> existeEmpresa(String id) async {
    try {
      final doc = await _coleccion.doc(id).get();
      if (doc.exists) return true;

      final snapshot =
          await _coleccion.where('id', isEqualTo: id).limit(1).get();
      if (snapshot.docs.isNotEmpty) return true;

      final altCol = (FirebaseFirestore.instance).collection('empresas');
      final altDoc = await altCol.doc(id).get();
      if (altDoc.exists) return true;
      final altSnap = await altCol.where('id', isEqualTo: id).limit(1).get();
      return altSnap.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String> agregarEmpresa(Empresa empresa) async {
    final data = empresa.toJson();

    // Convertir fechas a Timestamp
    if (empresa.fechaCreacion != null) {
      data['fechaCreacion'] = Timestamp.fromDate(empresa.fechaCreacion!);
    }
    data['fechaActualizacion'] = Timestamp.fromDate(
      empresa.fechaActualizacion ?? DateTime.now(),
    );

    // Usar el ID personalizado de la empresa (EMP_NOMBRE formato)
    // en lugar de generar uno automático
    final id = empresa.id.isNotEmpty
        ? empresa.id
        : (() {
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final sanitizedName = empresa.nombre
                .replaceAll(RegExp(r'\\s+'), '_')
                .toUpperCase();
            return 'EMP_${sanitizedName}_$timestamp';
          })();

    try {
      await _coleccion.doc(id).set(data);
      return id;
    } catch (_) {
      final altCol = FirebaseFirestore.instance.collection('empresas');
      await altCol.doc(id).set(data);
      return id;
    }

  }
}
