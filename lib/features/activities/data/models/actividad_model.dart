import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/actividad.dart';

/// Modelo de datos (DTO) para la entidad [Actividad].
/// Encapsula la lógica de serialización y la interacción con tipos de Firestore.
class ActividadModel extends Actividad {
  const ActividadModel({
    super.id,
    super.trabajoId,
    required super.trabajoAsignadoId,
    required super.clienteId,
    required super.empresaId,
    required super.tecnicoId,
    required super.tecnicoNombre,
    required super.fechaActividad,
    required super.descripcion,
    required super.horasTrabajadas,
    super.materialesUsados,
    super.notas,
    super.activo,
    super.creadoPor,
    super.actualizadoPor,
    super.fechaCreacion,
    super.fechaActualizacion,
  });

  factory ActividadModel.fromEntity(Actividad entidad) {
    return ActividadModel(
      id: entidad.id,
      trabajoId: entidad.trabajoId,
      trabajoAsignadoId: entidad.trabajoAsignadoId,
      clienteId: entidad.clienteId,
      empresaId: entidad.empresaId,
      tecnicoId: entidad.tecnicoId,
      tecnicoNombre: entidad.tecnicoNombre,
      fechaActividad: entidad.fechaActividad,
      descripcion: entidad.descripcion,
      horasTrabajadas: entidad.horasTrabajadas,
      materialesUsados: entidad.materialesUsados,
      notas: entidad.notas,
      activo: entidad.activo,
      creadoPor: entidad.creadoPor,
      actualizadoPor: entidad.actualizadoPor,
      fechaCreacion: entidad.fechaCreacion,
      fechaActualizacion: entidad.fechaActualizacion,
    );
  }

  factory ActividadModel.fromJson(Map<String, dynamic> json, {String? id}) {
    DateTime? parseFecha(dynamic valor) {
      if (valor == null) return null;
      if (valor is Timestamp) return valor.toDate();
      if (valor is DateTime) return valor;
      if (valor is String && valor.isNotEmpty) {
        return DateTime.tryParse(valor);
      }
      return null;
    }

    final matJson = json['materialesUsados'] as Map<String, dynamic>? ?? 
                   (json['materialNombre'] != null ? {
                     'nombre': json['materialNombre'],
                     'cantidad': json['materialCantidad'],
                     'precioUnitario': json['materialCostoUnitario'],
                   } : null);

    return ActividadModel(
      id: id ?? json['id'] as String? ?? '',
      trabajoId: json['trabajoId'] as String? ?? '',
      trabajoAsignadoId: json['trabajoAsignadoId'] as String? ?? '',
      clienteId: json['clienteId'] as String? ?? '',
      empresaId: json['empresaId'] as String? ?? '',
      tecnicoId: json['tecnicoId'] as String? ?? '',
      tecnicoNombre: json['tecnicoNombre'] as String? ?? '',
      fechaActividad: parseFecha(json['fechaActividad']) ?? DateTime.now(),
      descripcion: json['descripcion'] as String? ?? '',
      horasTrabajadas: (json['horasTrabajadas'] as num?)?.toDouble() ?? 0.0,
      materialesUsados: matJson != null ? MaterialesUsados(
        nombre: matJson['nombre'] as String? ?? '',
        cantidad: (matJson['cantidad'] as num?)?.toInt() ?? 0,
        precioUnitario: (matJson['precioUnitario'] as num?)?.toDouble() ?? 0.0,
      ) : null,
      notas: json['notas'] as String? ?? '',
      activo: json['activo'] as bool? ?? true,
      creadoPor: json['creadoPor'] as String? ?? '',
      actualizadoPor: json['actualizadoPor'] as String? ?? '',
      fechaCreacion: parseFecha(json['fechaCreacion']),
      fechaActualizacion: parseFecha(json['fechaActualizacion']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (trabajoId.isNotEmpty) 'trabajoId': trabajoId,
      'trabajoAsignadoId': trabajoAsignadoId,
      'clienteId': clienteId,
      'empresaId': empresaId,
      'tecnicoId': tecnicoId,
      'tecnicoNombre': tecnicoNombre,
      'fechaActividad': Timestamp.fromDate(fechaActividad),
      'descripcion': descripcion,
      'horasTrabajadas': horasTrabajadas,
      'notes': notas, // Note: fixing potencial typo based on field 'notas' vs 'notes' if necessary, but keep 'notas' for consistency with current repo
      'notas': notas,
      'activo': activo,
      'creadoPor': creadoPor,
      'actualizadoPor': actualizadoPor,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion ?? DateTime.now()),
      'fechaActualizacion': Timestamp.fromDate(fechaActualizacion ?? DateTime.now()),
      // Flattened materials for query support if needed, or structured
      'materialNombre': materialesUsados?.nombre,
      'materialCantidad': materialesUsados?.cantidad,
      'materialCostoUnitario': materialesUsados?.precioUnitario,
    };
  }
}
