import 'package:flutter/foundation.dart';

/// Model representing a client (cliente) entity.
@immutable
class Cliente {
  final String id;
  final String nombre;
  final String razonSocial;
  final String personaContacto;
  final String telefono;
  final String correo;
  final String direccion;
  final bool activo;

  /// Optional latitude of the client's location.  When
  /// provided this can be used to display a mini map in the
  /// clients list or detail view.
  final double? lat;

  /// Optional longitude of the client's location.
  final double? lng;

  /// Identificador de la empresa a la que pertenece este cliente.  Este
  /// campo se utiliza para filtrar clientes por empresa en la base
  /// de datos.  Si no se especifica se asume una cadena vacía.
  final String empresaId;

  /// Idioma preferido del cliente.  Por defecto es 'es'.
  final String idioma;

  /// Fecha de creación del cliente en la base de datos.  Puede ser
  /// nula si el registro aún no ha sido persistido.
  final DateTime? fechaCreacion;

  /// Fecha de última actualización del cliente.  Se actualiza cada
  /// vez que se modifica el registro.
  final DateTime? fechaActualizacion;

  /// Usuario responsable de la creación del registro.
  final String creadoPor;

  /// Usuario responsable de la última actualización del registro.
  final String actualizadoPor;

  const Cliente({
    this.id = '',
    required this.nombre,
    required this.razonSocial,
    required this.personaContacto,
    required this.telefono,
    required this.correo,
    required this.direccion,
    this.activo = true,
    this.lat,
    this.lng,
    this.empresaId = '',
    this.idioma = 'es',
    this.fechaCreacion,
    this.fechaActualizacion,
    this.creadoPor = '',
    this.actualizadoPor = '',
  });

  /// Devuelve una copia del cliente con algunos campos modificados.
  ///
  /// Este método es útil para actualizar de manera inmutable un
  /// cliente existente.  Si un parámetro es nulo se mantiene el
  /// valor original de la instancia.
  Cliente copyWith({
    String? id,
    String? nombre,
    String? razonSocial,
    String? personaContacto,
    String? telefono,
    String? correo,
    String? direccion,
    bool? activo,
    double? lat,
    double? lng,
    String? empresaId,
    String? idioma,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? creadoPor,
    String? actualizadoPor,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      razonSocial: razonSocial ?? this.razonSocial,
      personaContacto: personaContacto ?? this.personaContacto,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      direccion: direccion ?? this.direccion,
      activo: activo ?? this.activo,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      empresaId: empresaId ?? this.empresaId,
      idioma: idioma ?? this.idioma,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      creadoPor: creadoPor ?? this.creadoPor,
      actualizadoPor: actualizadoPor ?? this.actualizadoPor,
    );
  }

  /// Crea un [Cliente] a partir de un mapa de datos.
  ///
  /// El origen puede ser Firestore u otro backend. Aquí se manejan
  /// nombres de campo alternativos y se aplican valores por defecto
  /// para evitar excepciones si algún campo falta.
  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      razonSocial: json['razonSocial'] as String? ?? '',
      personaContacto: json['personaContacto'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
      // Aceptar tanto "correo" como "email".  Internamente el
      // modelo utiliza la propiedad `correo` para representar el
      // correo electrónico.  Si no se encuentra ningún valor se
      // utiliza una cadena vacía.
      correo: json['correo'] as String? ?? json['email'] as String? ?? '',
      direccion: json['direccion'] as String? ?? '',
      activo: json['activo'] as bool? ?? true,
      // Convertir coordenadas geográficas a valores de doble.  Se
      // aceptan tanto "latitud" y "longitud" como "lat" y "lng".
      lat: json['latitud'] != null
          ? (json['latitud'] as num).toDouble()
          : (json['lat'] != null ? (json['lat'] as num).toDouble() : null),
      lng: json['longitud'] != null
          ? (json['longitud'] as num).toDouble()
          : (json['lng'] != null ? (json['lng'] as num).toDouble() : null),
      empresaId: json['empresaId'] as String? ?? '',
      idioma: json['idioma'] as String? ?? 'es',
      fechaCreacion: _parseDate(json['fechaCreacion']),
      fechaActualizacion: _parseDate(json['fechaActualizacion']),
      creadoPor: json['creadoPor'] as String? ?? '',
      actualizadoPor: json['actualizadoPor'] as String? ?? '',
    );
  }

  /// Convierte el cliente a JSON para que pueda guardarse en Firestore.
  ///
  /// Se omiten los valores nulos y solo se escribe la información necesaria
  /// para mantener el registro coherente en la base de datos.
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'nombre': nombre,
      'razonSocial': razonSocial,
      'personaContacto': personaContacto,
      'telefono': telefono,
      // Guardar el correo bajo la clave "email" para Firestore.
      'email': correo,
      'direccion': direccion,
      'activo': activo,
      'idioma': idioma,
      if (lat != null) 'latitud': lat,
      if (lng != null) 'longitud': lng,
      if (empresaId.isNotEmpty) 'empresaId': empresaId,
      if (fechaCreacion != null)
        'fechaCreacion': fechaCreacion!.toIso8601String(),
      if (fechaActualizacion != null)
        'fechaActualizacion': fechaActualizacion!.toIso8601String(),
      if (creadoPor.isNotEmpty) 'creadoPor': creadoPor,
      if (actualizadoPor.isNotEmpty) 'actualizadoPor': actualizadoPor,
    };
    return data;
  }

  /// Convierte diferentes formatos de fecha a [DateTime].
  ///
  /// Soporta valores en formato:
  /// - [DateTime]
  /// - String ISO8601
  /// - Map con campos Firebase Timestamp (`_seconds`, `_nanoseconds`).
  static DateTime? _parseDate(dynamic valor) {
    if (valor == null) return null;
    if (valor is DateTime) return valor;
    if (valor is String && valor.isNotEmpty) return DateTime.tryParse(valor);
    if (valor is Map) {
      final seconds = valor['_seconds'] ?? valor['seconds'];
      final nanos = valor['_nanoseconds'] ?? valor['nanoseconds'];
      if (seconds is num) {
        final milliseconds = seconds * 1000 + (nanos is num ? nanos / 1e6 : 0);
        return DateTime.fromMillisecondsSinceEpoch(milliseconds.round());
      }
    }
    return null;
  }
}
