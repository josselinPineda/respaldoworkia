import 'package:flutter/foundation.dart';

/// Model representing a type of expense.
@immutable
class TipoGasto {
  final String id;
  final String empresaId;
  final String codigo;
  final String nombre;
  final String descripcion;

  const TipoGasto({
    this.id = '',
    this.empresaId = '',
    required this.codigo,
    required this.nombre,
    required this.descripcion,
  });

  factory TipoGasto.fromJson(Map<String, dynamic> json) {
    return TipoGasto(
      id: json['id'] as String? ?? '',
      empresaId: json['empresaId'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresaId': empresaId,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }
}
