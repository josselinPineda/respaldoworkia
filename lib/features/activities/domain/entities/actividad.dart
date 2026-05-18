import 'package:flutter/foundation.dart';

/// Nested model representing materials used during an activity.
@immutable
class MaterialesUsados {
  final String nombre;
  final int cantidad;
  final double precioUnitario;

  const MaterialesUsados({
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
  });
}

/// Entidad de dominio que representa una actividad registrada para un trabajo.
/// Sigue los principios de Diseño Orientado al Dominio (pureza de Dart).
@immutable
class Actividad {
  final String id;
  final String trabajoId;
  final String trabajoAsignadoId;
  final String clienteId;
  final String empresaId;
  final String tecnicoId;
  final String tecnicoNombre;
  final DateTime fechaActividad;
  final String descripcion;
  final double horasTrabajadas;
  final MaterialesUsados? materialesUsados;
  final String notas;
  final bool activo;
  final String creadoPor;
  final String actualizadoPor;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  const Actividad({
    this.id = '',
    this.trabajoId = '',
    required this.trabajoAsignadoId,
    required this.clienteId,
    required this.empresaId,
    required this.tecnicoId,
    required this.tecnicoNombre,
    required this.fechaActividad,
    required this.descripcion,
    required this.horasTrabajadas,
    this.materialesUsados,
    this.notas = '',
    this.activo = true,
    this.creadoPor = '',
    this.actualizadoPor = '',
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  /// Compatibilidad con versiones anteriores: alias para acceder al
  /// identificador y nombre del técnico utilizando los nombres
  /// tradicionales de `empleadoId` y `empleadoNombre`.
  String get empleadoId => tecnicoId;
  String get empleadoNombre => tecnicoNombre;

  Actividad copyWith({
    String? id,
    String? trabajoId,
    String? trabajoAsignadoId,
    String? clienteId,
    String? empresaId,
    String? tecnicoId,
    String? tecnicoNombre,
    DateTime? fechaActividad,
    String? descripcion,
    double? horasTrabajadas,
    MaterialesUsados? materialesUsados,
    String? notas,
    bool? activo,
    String? creadoPor,
    String? actualizadoPor,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return Actividad(
      id: id ?? this.id,
      trabajoId: trabajoId ?? this.trabajoId,
      trabajoAsignadoId: trabajoAsignadoId ?? this.trabajoAsignadoId,
      clienteId: clienteId ?? this.clienteId,
      empresaId: empresaId ?? this.empresaId,
      tecnicoId: tecnicoId ?? this.tecnicoId,
      tecnicoNombre: tecnicoNombre ?? this.tecnicoNombre,
      fechaActividad: fechaActividad ?? this.fechaActividad,
      descripcion: descripcion ?? this.descripcion,
      horasTrabajadas: horasTrabajadas ?? this.horasTrabajadas,
      materialesUsados: materialesUsados ?? this.materialesUsados,
      notas: notas ?? this.notas,
      activo: activo ?? this.activo,
      creadoPor: creadoPor ?? this.creadoPor,
      actualizadoPor: actualizadoPor ?? this.actualizadoPor,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
