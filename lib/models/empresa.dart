import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing basic information about a company.
///
/// This entity stores contact and profile details for the company
/// operating the STGF system.  When connecting to Firestore this
/// model can be populated directly from a document.  For the
/// purposes of this prototype it holds data in memory via the
/// [CompanyController].
@immutable
class Empresa {
  final String id;
  final String nombre;
  final String nombreComercial;
  final String razonSocial;
  final String telefono;
  final String direccion;
  final String email;
  final String logoUrl;
  final bool activo;

  /// Fecha en la que se creó el registro de empresa.  Sirve para
  /// llevar un control de auditoría cuando se utilice una base
  /// de datos como Firestore.  Si no se especifica, será nula.
  final DateTime? fechaCreacion;

  /// Fecha de la última actualización del registro.  Se actualiza
  /// cada vez que se modifica cualquier campo de la empresa.
  final DateTime? fechaActualizacion;

  /// Identificador del usuario que creó este registro.  Este
  /// campo coincide con el uid de Firebase del usuario que
  /// registró la empresa.
  final String creadoPor;

  /// Identificador del usuario que actualizó por última vez este
  /// registro.  Ayuda a llevar un seguimiento de cambios en la
  /// configuración de la empresa.
  final String actualizadoPor;

  /// Coordenadas de ubicación de la empresa.  Se utilizan para
  /// mostrar la sede en el mapa.  Si no se proporcionan, serán
  /// nulas.
  final double? latitud;
  final double? longitud;
  final double? tasaCambio;


  const Empresa({
    this.id = '',
    this.nombre = '',
    this.nombreComercial = '',
    this.razonSocial = '',
    this.telefono = '',
    this.direccion = '',
    this.email = '',
    this.logoUrl = '',
    this.activo = true,
    this.fechaCreacion,
    this.fechaActualizacion,
    this.creadoPor = '',
    this.actualizadoPor = '',
    this.latitud,
    this.longitud,
    this.tasaCambio,
  });

  /// Creates a new [Empresa] from a JSON map.  Missing keys will
  /// default to empty strings. Handles both Firestore Timestamp objects
  /// and ISO8601 String dates for fechaCreacion and fechaActual ization.
  factory Empresa.fromJson(Map<String, dynamic> json) {
    // Helper function to convert Firestore Timestamp or ISO String to DateTime
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) {
        // Firestore returns Timestamp objects
        return value.toDate();
      } else if (value is String) {
        // JSON APIs return ISO8601 strings
        return DateTime.tryParse(value);
      }
      return null;
    }

    return Empresa(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      nombreComercial: json['nombreComercial'] as String? ?? '',
      razonSocial: json['razonSocial'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
      direccion: json['direccion'] as String? ?? '',
      email: json['email'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
      activo: json['activo'] as bool? ?? true,
      fechaCreacion: parseDateTime(json['fechaCreacion']),
      fechaActualizacion: parseDateTime(json['fechaActualizacion']),
      creadoPor: json['creadoPor'] as String? ?? '',
      actualizadoPor: json['actualizadoPor'] as String? ?? '',
      latitud: json['latitud'] != null
          ? (json['latitud'] as num).toDouble()
          : (json['lat'] != null ? (json['lat'] as num).toDouble() : null),
      longitud: json['longitud'] != null
          ? (json['longitud'] as num).toDouble()
          : (json['lng'] != null ? (json['lng'] as num).toDouble() : null),
      tasaCambio: json['tasaCambio'] != null
          ? (json['tasaCambio'] as num).toDouble()
          : null,
    );
  }

  /// Converts this [Empresa] into a JSON map for persistence or
  /// interchange.
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'nombre': nombre,
      'nombreComercial': nombreComercial,
      'razonSocial': razonSocial,
      'telefono': telefono,
      'direccion': direccion,
      'email': email,
      'logoUrl': logoUrl,
      'activo': activo,
      if (fechaCreacion != null)
        'fechaCreacion': fechaCreacion!.toIso8601String(),
      if (fechaActualizacion != null)
        'fechaActualizacion': fechaActualizacion!.toIso8601String(),
      if (creadoPor.isNotEmpty) 'creadoPor': creadoPor,
      if (actualizadoPor.isNotEmpty) 'actualizadoPor': actualizadoPor,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
      if (tasaCambio != null) 'tasaCambio': tasaCambio,
    };
    return data;
  }

  /// Returns a copy of this [Empresa] with some fields replaced.
  Empresa copyWith({
    String? id,
    String? nombre,
    String? nombreComercial,
    String? razonSocial,
    String? telefono,
    String? direccion,
    String? email,
    String? logoUrl,
    bool? activo,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? creadoPor,
    String? actualizadoPor,
    double? latitud,
    double? longitud,
    double? tasaCambio,
  }) {
    return Empresa(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      nombreComercial: nombreComercial ?? this.nombreComercial,
      razonSocial: razonSocial ?? this.razonSocial,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      creadoPor: creadoPor ?? this.creadoPor,
      actualizadoPor: actualizadoPor ?? this.actualizadoPor,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      tasaCambio: tasaCambio ?? this.tasaCambio,
    );
  }
}
