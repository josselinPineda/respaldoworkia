import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/foundation.dart';

/// Model representing a user account.
@immutable
class Usuario {
  final String id;

  /// Identificador único de autenticación de Firebase para este
  /// usuario.  Este valor corresponde al `uid` devuelto por
  /// FirebaseAuth cuando se registra una cuenta nueva.  Se almacena
  /// junto con el documento de usuario en Firestore para vincular
  /// el documento de perfil con la cuenta de autenticación.  En
  /// implementaciones previas se usaba únicamente el campo [id],
  /// pero al integrar Firebase Auth se requiere separar el ID de
  /// autenticación del ID lógico del documento.
  final String authUid;
  final String nombre;
  final String email;
  final bool activo;
  final String idEmpresa;
  final String telefono;
  final String perfilId;
  final String idioma;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  /// Identificador del usuario que creó este registro.  Se almacena
  /// como parte de la auditoría en Firestore.  Cuando se crea un
  /// usuario nuevo se establece al uid del administrador que lo
  /// registra.  Por defecto es una cadena vacía.
  final String creadoPor;

  /// Identificador del usuario que actualizó por última vez este
  /// registro.  Este campo se actualiza con cada modificación para
  /// mantener un historial de cambios.  Por defecto es una cadena
  /// vacía.
  final String actualizadoPor;

  const Usuario({
    this.id = '',
    this.authUid = '',
    required this.nombre,
    required this.email,
    this.activo = true,
    required this.idEmpresa,
    this.telefono = '',
    required this.perfilId,
    this.idioma = 'es',
    this.fechaCreacion,
    this.fechaActualizacion,
    this.creadoPor = '',
    this.actualizadoPor = '',
  });

  /// Factory constructor para crear un Usuario vacío (usado como fallback en orElse).
  factory Usuario.empty() =>
      const Usuario(id: '', nombre: '', email: '', idEmpresa: '', perfilId: '');

  /// Devuelve una copia del usuario con campos modificados.
  ///
  /// Este método permite actualizar parcialmente un usuario de
  /// manera inmutable.  Si un argumento es nulo se conserva el
  /// valor actual.
  Usuario copyWith({
    String? id,
    String? authUid,
    String? nombre,
    String? email,
    bool? activo,
    String? idEmpresa,
    String? telefono,
    String? perfilId,
    String? idioma,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? creadoPor,
    String? actualizadoPor,
  }) {
    return Usuario(
      id: id ?? this.id,
      authUid: authUid ?? this.authUid,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      activo: activo ?? this.activo,
      idEmpresa: idEmpresa ?? this.idEmpresa,
      telefono: telefono ?? this.telefono,
      perfilId: perfilId ?? this.perfilId,
      idioma: idioma ?? this.idioma,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      creadoPor: creadoPor ?? this.creadoPor,
      actualizadoPor: actualizadoPor ?? this.actualizadoPor,
    );
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String? ?? '',
      authUid: json['authUid'] as String? ?? json['uid'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      email: json['email'] as String? ?? '',
      activo: json['activo'] as bool? ?? true,
      // Aceptar tanto "idEmpresa" como "empresaId" del backend.  Si
      // ninguno de los dos está presente se usará una cadena vacía.
      idEmpresa:
          json['idEmpresa'] as String? ?? json['empresaId'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
      perfilId: json['perfilId'] as String? ?? '',
      idioma: json['idioma'] as String? ?? 'es',
      fechaCreacion: _parseUsuarioFecha(
        json['fechaCreacion'] ?? json['createdAt'],
      ),
      fechaActualizacion: _parseUsuarioFecha(
        json['fechaActualizacion'] ?? json['updatedAt'],
      ),
      creadoPor: json['creadoPor'] as String? ?? '',
      actualizadoPor: json['actualizadoPor'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (authUid.isNotEmpty) 'authUid': authUid,
      'nombre': nombre,
      'email': email,
      'activo': activo,
      // Al persistir se utiliza la clave "empresaId" para
      // compatibilidad con Firestore.  Se mantiene "idEmpresa" sólo
      // en la instancia en memoria.
      'empresaId': idEmpresa,
      'telefono': telefono,
      'perfilId': perfilId,
      'idioma': idioma,
      if (fechaCreacion != null)
        'fechaCreacion': fechaCreacion!.toIso8601String(),
      if (fechaActualizacion != null)
        'fechaActualizacion': fechaActualizacion!.toIso8601String(),
      if (creadoPor.isNotEmpty) 'creadoPor': creadoPor,
      if (actualizadoPor.isNotEmpty) 'actualizadoPor': actualizadoPor,
    };
  }
}

DateTime? _parseUsuarioFecha(dynamic valor) {
  if (valor == null) return null;
  if (valor is DateTime) return valor;
  if (valor is Timestamp) return valor.toDate();
  if (valor is int) return DateTime.fromMillisecondsSinceEpoch(valor);
  if (valor is num) return DateTime.fromMillisecondsSinceEpoch(valor.toInt());
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
