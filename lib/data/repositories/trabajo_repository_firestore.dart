import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/trabajo_repository.dart';
import '../../models/job.dart';

/// Implementacion de [TrabajoRepository] respaldada por Firebase Firestore.
///
/// Cada trabajo vive como un documento dentro de la coleccion `trabajos`.
/// Este repositorio mapea documentos a instancias de [Trabajo] y realiza la
/// operacion inversa al crear o actualizar registros.
class TrabajoRepositoryFirestore implements TrabajoRepository {
  TrabajoRepositoryFirestore({FirebaseFirestore? firestore})
    : _coleccion = (firestore ?? FirebaseFirestore.instance).collection(
        'trabajos',
      );

  final CollectionReference<Map<String, dynamic>> _coleccion;

  @override
  Future<List<Trabajo>> obtenerTrabajos(String empresaId) async {
    if (empresaId.isEmpty) throw ArgumentError('empresaId cannot be empty');
    final snapshot = await _coleccion
        .where('empresaId', isEqualTo: empresaId)
        .get();
    final trabajos = snapshot.docs.map(_desdeDocumento).toList();
    // ordena por fecha de inicio porque ese campo ha dejado de ser
    // relevante en el catálogo de trabajos.
    trabajos.sort((a, b) => a.titulo.compareTo(b.titulo));
    return trabajos;
  }

  @override
  Future<void> agregarTrabajo(Trabajo trabajo) async {
    // Generar un identificador personalizado para el trabajo en base al título.
    // Se reemplazan espacios por guiones bajos, se convierte a mayúsculas y
    // se antepone el prefijo "TRB_" para seguir la convención.  Si el
    // trabajo ya tiene id se usa ese valor para permitir actualizaciones
    // programadas.
    final String id = trabajo.id.isNotEmpty
        ? trabajo.id
        : 'TRB_${trabajo.titulo.replaceAll(RegExp(r'\s+'), '_').toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}';
    await _coleccion.doc(id).set(_aMapaFirestore(trabajo));
  }

  @override
  Future<void> actualizarTrabajo(Trabajo trabajo) async {
    if (trabajo.id.isEmpty) return;
    await _coleccion.doc(trabajo.id).update(_aMapaFirestore(trabajo));
  }

  @override
  Future<void> cancelarTrabajo(String id, String actualizadoPor) async {
    if (id.isEmpty) return;
    // Eliminado lógico: establecer activo = false y auditoría
    // Si el documento no existe, no lanzan error; solo ignoramos
    try {
      await _coleccion.doc(id).update({
        'activo': false,
        'actualizadoPor': actualizadoPor,
        'fechaActualizacion': Timestamp.now(),
      });
    } catch (e) {
      // Si el documento no existe en el catálogo (work-only-in-assignments),
      // simplemente ignoramos el error y continuamos.
      // Esto evita fallos cuando se borran asignaciones de trabajos que
      // fueron eliminados de catálogo previamente.
      if (!e.toString().contains('not-found')) {
        rethrow; // Re-lanzar si es otro tipo de error
      }
    }
  }

  @override
  Future<List<Trabajo>> buscarTrabajos(
    String consulta,
    String empresaId,
  ) async {
    final lower = consulta.trim().toLowerCase();

    if (lower.isEmpty) {
      return obtenerTrabajos(empresaId);
    }
    final trabajos = await obtenerTrabajos(empresaId);
    return trabajos
        .where(
          (t) =>
              t.titulo.toLowerCase().contains(lower) ||
              t.descripcion.toLowerCase().contains(lower) ||
              t.costo.toString().contains(lower),
        )
        .toList();
  }

  Trabajo _desdeDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final rawData = doc.data() ?? {};
    // Convierte valores Timestamp a DateTime antes de crear la instancia
    // del modelo.  Esto evita que Trabajo.fromJson devuelva la fecha
    // actual cuando se encuentran valores Timestamp (ver `_parseFecha`).
    final data = <String, dynamic>{};
    rawData.forEach((key, value) {
      if (value is Timestamp) {
        // Utilizar toDate para convertir Timestamp a DateTime
        data[key] = value.toDate();
      } else if (value is Map) {
        // Algunos valores pueden estar anidados dentro de mapas; no
        // modificamos esos aquí porque Trabajo.fromJson los maneja.
        data[key] = value;
      } else if (value is List) {
        // Las listas se copian tal cual para evitar modificar los
        // elementos original.
        data[key] = List.from(value);
      } else {
        data[key] = value;
      }
    });
    // Pasamos todos los datos al constructor de Trabajo a través de
    // fromJson para aprovechar el mapeo y la conversión de tipos
    // implementada allí.  Agregamos el id del documento para
    // conservar la referencia al documento de Firestore.
    return Trabajo.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> _aMapaFirestore(Trabajo trabajo) {
    final data = <String, dynamic>{
      // Información básica del trabajo.
      'titulo': trabajo.titulo,
      'descripcion': trabajo.descripcion,
      'costo': trabajo.costo,
      if (trabajo.autoFinalizarHoras != null)
        'autoFinalizarHoras': trabajo.autoFinalizarHoras,
      'empresaId': trabajo.empresaId,
      // Usar el campo activo del modelo
      'activo': trabajo.activo,
    };
    // Agregar campos de auditoría y marcas de tiempo.
    if (trabajo.fechaCreacion != null) {
      data['fechaCreacion'] = Timestamp.fromDate(trabajo.fechaCreacion!);
    }
    data['fechaActualizacion'] = Timestamp.fromDate(
      trabajo.fechaActualizacion ?? DateTime.now(),
    );
    if (trabajo.creadoPor.isNotEmpty) {
      data['creadoPor'] = trabajo.creadoPor;
    }
    if (trabajo.actualizadoPor.isNotEmpty) {
      data['actualizadoPor'] = trabajo.actualizadoPor;
    }
    return data;
  }
}
