import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a specific work session by a technician on a job assignment.
/// Stored in 'sesiones_trabajo' collection.
class SesionTrabajo {
  final String id;
  final String trabajoAsignadoId;
  final String tecnicoId;
  final DateTime inicio;
  final DateTime? fin; // Null means currently active
  final double horas; // Calculated hours (0.0 if active)
  final String empresaId;

  const SesionTrabajo({
    required this.id,
    required this.trabajoAsignadoId,
    required this.tecnicoId,
    required this.inicio,
    this.fin,
    this.horas = 0.0,
    required this.empresaId,
  });

  factory SesionTrabajo.fromJson(Map<String, dynamic> json) {
    DateTime? toDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return SesionTrabajo(
      id: json['id'] as String? ?? '',
      trabajoAsignadoId: json['trabajoAsignadoId'] as String? ?? '',
      tecnicoId: json['tecnicoId'] as String? ?? '',
      inicio: toDate(json['inicio']) ?? DateTime.now(),
      fin: toDate(json['fin']),
      horas: (json['horas'] as num?)?.toDouble() ?? 0.0,
      empresaId: json['empresaId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trabajoAsignadoId': trabajoAsignadoId,
      'tecnicoId': tecnicoId,
      'inicio': Timestamp.fromDate(inicio),
      'fin': fin != null ? Timestamp.fromDate(fin!) : null,
      'horas': horas,
      'empresaId': empresaId,
    };
  }

  SesionTrabajo copyWith({
    String? id,
    String? trabajoAsignadoId,
    String? tecnicoId,
    DateTime? inicio,
    DateTime? fin,
    double? horas,
    String? empresaId,
  }) {
    return SesionTrabajo(
      id: id ?? this.id,
      trabajoAsignadoId: trabajoAsignadoId ?? this.trabajoAsignadoId,
      tecnicoId: tecnicoId ?? this.tecnicoId,
      inicio: inicio ?? this.inicio,
      fin: fin ?? this.fin,
      horas: horas ?? this.horas,
      empresaId: empresaId ?? this.empresaId,
    );
  }
}
