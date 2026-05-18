import 'package:flutter/foundation.dart';

/// Model representing a user profile (role) with its permissions.
@immutable
class Perfil {
  final String id;
  final String nombre;
  final String descripcion;
  final List<String> pantallasPermitidas;
  final bool activo;

  const Perfil({
    this.id = '',
    required this.nombre,
    required this.descripcion,
    required this.pantallasPermitidas,
    this.activo = true,
  });

  factory Perfil.fromJson(Map<String, dynamic> json) {
    return Perfil(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      pantallasPermitidas: (json['pantallasPermitidas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'pantallasPermitidas': pantallasPermitidas,
      'activo': activo,
    };
  }
}
