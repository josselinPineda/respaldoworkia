import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/gasto_repository.dart';
import '../../models/gasto.dart';
import '../../models/tipo_gasto.dart';

/// Implementación de [GastoRepository] respaldada por Firebase Firestore.
///
/// Los gastos se almacenan en la colección `gastos` y cada documento
/// representa un desembolso realizado por la empresa.  Los tipos de
/// gasto se almacenan en la colección `tiposGasto`.  Este
/// repositorio se encarga de traducir los documentos de Firestore a
/// instancias de [Gasto] y [TipoGasto] y viceversa.
class GastoRepositoryFirestore implements GastoRepository {
  GastoRepositoryFirestore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _gastosRef =>
      _firestore.collection('gastos');

  CollectionReference<Map<String, dynamic>> get _tiposRef =>
      _firestore.collection('tiposGasto');

  @override
  Future<List<Gasto>> obtenerGastos(String empresaId) async {
    if (empresaId.isEmpty) throw ArgumentError('empresaId cannot be empty');
    // Filtrar solo los gastos activos desde Firestore para eficiencia
    final snapshot = await _gastosRef
        .where('empresaId', isEqualTo: empresaId)
        .where('activo', isEqualTo: true)
        .get();
    final gastos = snapshot.docs
        .map((doc) => Gasto.fromJson({...doc.data(), 'id': doc.id}))
        .toList();

    // Si un gasto apunta a un tipo que ya no existe (fue eliminado),
    // lo ocultamos para que no aparezca en Balance ni exportaciones.
    final tiposSnapshot = await _tiposRef
        .where('empresaId', isEqualTo: empresaId)
        .get();
    final tiposIds = tiposSnapshot.docs.map((d) => d.id).toSet();
    final filtrados = gastos.where((g) => tiposIds.contains(g.idTipoGasto)).toList();
    // Ordenar de más reciente a más antiguo por fecha de gasto
    filtrados.sort((a, b) => b.fechaGasto.compareTo(a.fechaGasto));
    return filtrados;
  }

  @override
  Future<void> agregarGasto(Gasto gasto) async {
    final data = gasto.toJson();
    // Generar un identificador personalizado para el gasto.  Utilizamos el
    // prefijo "GST_", seguido del identificador del tipo de gasto y un
    // timestamp en milisegundos para asegurar unicidad.
    final String id =
        'GST_${gasto.idTipoGasto}_${DateTime.now().millisecondsSinceEpoch}';
    // Convertir DateTime a Timestamp para Firestore
    data['fechaGasto'] = Timestamp.fromDate(gasto.fechaGasto);
    if (gasto.fechaCreacion != null) {
      data['fechaCreacion'] = Timestamp.fromDate(gasto.fechaCreacion!);
    } else {
      data['fechaCreacion'] = Timestamp.fromDate(DateTime.now());
    }
    data['fechaActualizacion'] = Timestamp.fromDate(
      gasto.fechaActualizacion ?? DateTime.now(),
    );
    await _gastosRef.doc(id).set(data);
  }

  @override
  Future<void> eliminarGasto(String id, String actualizadoPor) async {
    if (id.isEmpty) return;
    // Borrado lógico: update activo, updatedBy, updatedAt
    await _gastosRef.doc(id).update({
      'activo': false,
      'actualizadoPor': actualizadoPor,
      'fechaActualizacion': Timestamp.now(),
    });
  }

  @override
  Future<void> actualizarGasto(Gasto gasto) async {
    if (gasto.id.isEmpty) return;
    final doc = _gastosRef.doc(gasto.id);
    final data = gasto.toJson();
    // Manejar conversiones de fechas
    data['fechaGasto'] = Timestamp.fromDate(gasto.fechaGasto);
    if (gasto.fechaCreacion != null) {
      data['fechaCreacion'] = Timestamp.fromDate(gasto.fechaCreacion!);
    }
    data['fechaActualizacion'] = Timestamp.fromDate(
      gasto.fechaActualizacion ?? DateTime.now(),
    );
    await doc.update(data);
  }

  @override
  Future<List<Gasto>> gastosPorTipo(String tipoId, String empresaId) async {
    final snapshot = await _gastosRef
        .where('empresaId', isEqualTo: empresaId)
        .where('idTipoGasto', isEqualTo: tipoId)
        .where('activo', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => Gasto.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<List<Gasto>> gastosPorRango(
    DateTime inicio,
    DateTime fin,
    String empresaId,
  ) async {
    // Incluir gastos cuyo fechaGasto esté en el rango [inicio, fin] y estén activos
    final snapshot = await _gastosRef
        .where('empresaId', isEqualTo: empresaId)
        .where('fechaGasto', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fechaGasto', isLessThanOrEqualTo: Timestamp.fromDate(fin))
        .where('activo', isEqualTo: true)
        .get();
    final gastos = snapshot.docs
        .map((doc) => Gasto.fromJson({...doc.data(), 'id': doc.id}))
        .toList();

    final tiposSnapshot = await _tiposRef
        .where('empresaId', isEqualTo: empresaId)
        .get();
    final tiposIds = tiposSnapshot.docs.map((d) => d.id).toSet();
    return gastos.where((g) => tiposIds.contains(g.idTipoGasto)).toList();
  }

  @override
  Future<List<TipoGasto>> obtenerTipos(String empresaId) async {
    final snapshot = await _tiposRef.where('empresaId', isEqualTo: empresaId).get();
    return snapshot.docs
        .map((doc) => TipoGasto.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<void> agregarTipoGasto(TipoGasto tipo) async {
    final docRef = _tiposRef.doc();
    final data = tipo.toJson();
    data['id'] = docRef.id; // Asegurar que el ID en el documento sea el de Firestore
    await docRef.set(data);
  }

  @override
  Future<void> actualizarTipoGasto(TipoGasto tipo) async {
    if (tipo.id.isEmpty) return;
    await _tiposRef.doc(tipo.id).update(tipo.toJson());
  }

  @override
  Future<void> eliminarTipoGasto(String id) async {
    if (id.isEmpty) return;
    // Cascada: al eliminar una categoría, ocultar (borrado lógico) todos los
    // gastos que pertenezcan a esa categoría para que desaparezcan de Balance
    // y exportaciones.
    final snapshot = await _gastosRef
        .where('idTipoGasto', isEqualTo: id)
        .where('activo', isEqualTo: true)
        .get();

    if (snapshot.docs.isNotEmpty) {
      WriteBatch batch = _firestore.batch();
      int ops = 0;
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'activo': false,
          'actualizadoPor': 'system',
          'fechaActualizacion': Timestamp.now(),
        });
        ops++;
        if (ops >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          ops = 0;
        }
      }
      if (ops > 0) {
        await batch.commit();
      }
    }

    await _tiposRef.doc(id).delete();
  }
}
