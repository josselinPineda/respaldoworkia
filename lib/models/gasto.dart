import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Model representing an expense entry.
@immutable
class Gasto {
  /// Identificador único del gasto.  Corresponde al ID de documento
  /// cuando se almacena en Firestore.
  final String id;

  /// Fecha en la que se efectuó el gasto.
  final DateTime fechaGasto;

  /// Monto desembolsado para este gasto.
  final double monto;

  /// Identificador de la empresa responsable del gasto.
  final String empresaId;

  /// Identificador de la asignación de trabajo a la que se asocia este gasto.
  ///
  /// Este campo permite vincular el gasto con una ejecución concreta de un
  /// trabajo para un cliente.  Cuando el gasto no está asociado a una
  /// asignación específica, este valor puede permanecer vacío.  Sin
  /// embargo, para mantener una estructura limpia y coherente con el
  /// modelo de Firestore, es recomendable que todos los gastos se
  /// registren indicando a qué trabajo asignado pertenecen.
  final String trabajoAsignadoId;

  /// Identificador del trabajo de catálogo asociado al gasto.  Este
  /// valor se copia desde la asignación de trabajo correspondiente
  /// (ver [trabajoAsignadoId]) para facilitar consultas por tipo de
  /// trabajo sin tener que cargar la asignación completa.  Puede estar
  /// vacío si no se conoce o no aplica.
  final String trabajoId;

  /// Identificador del cliente asociado al gasto.  Se establece a
  /// partir de la asignación de trabajo para facilitar filtrados por
  /// cliente sin realizar lecturas adicionales.  Este campo puede
  /// permanecer vacío cuando el gasto no está ligado a un cliente.
  final String clienteId;

  /// Indica si el gasto está activo.  Se utiliza para permitir
  /// anulaciones lógicas sin eliminar el documento.
  final bool activo;

  /// URL a una imagen o PDF del comprobante de gasto.
  final String urlComprobante;

  /// Identificador del tipo de gasto.  Corresponde al ID de un
  /// documento en la colección `tiposGasto`.
  final String idTipoGasto;

  /// Descripción del gasto.
  final String descripcion;

  /// Fecha de creación del documento en Firestore.  Puede ser nula
  /// cuando el gasto aún no se ha persistido.
  final DateTime? fechaCreacion;

  /// Fecha de la última actualización del documento en Firestore.
  final DateTime? fechaActualizacion;

  /// Usuario que creó el registro.  Reemplaza al campo `responsable`.
  final String creadoPor;

  /// Usuario que actualizó por última vez el registro.
  final String actualizadoPor;

  const Gasto({
    this.id = '',
    required this.fechaGasto,
    required this.monto,
    required this.empresaId,
    this.trabajoAsignadoId = '',
    this.trabajoId = '',
    this.clienteId = '',
    this.activo = true,
    this.urlComprobante = '',
    required this.idTipoGasto,
    this.descripcion = '',
    this.fechaCreacion,
    this.fechaActualizacion,
    this.creadoPor = '',
    this.actualizadoPor = '',
  });

  /// Devuelve una copia del gasto con campos modificados.
  ///
  /// Permite crear una nueva instancia de [Gasto] tomando la
  /// existente como base.  Se utiliza para actualizar campos
  /// individuales de forma inmutable.
  Gasto copyWith({
    String? id,
    DateTime? fechaGasto,
    double? monto,
    String? empresaId,
    String? trabajoAsignadoId,
    String? trabajoId,
    String? clienteId,
    bool? activo,
    String? urlComprobante,
    String? idTipoGasto,
    String? descripcion,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? creadoPor,
    String? actualizadoPor,
    String? responsable,
  }) {
    return Gasto(
      id: id ?? this.id,
      fechaGasto: fechaGasto ?? this.fechaGasto,
      monto: monto ?? this.monto,
      empresaId: empresaId ?? this.empresaId,
      trabajoAsignadoId: trabajoAsignadoId ?? this.trabajoAsignadoId,
      trabajoId: trabajoId ?? this.trabajoId,
      clienteId: clienteId ?? this.clienteId,
      activo: activo ?? this.activo,
      urlComprobante: urlComprobante ?? this.urlComprobante,
      idTipoGasto: idTipoGasto ?? this.idTipoGasto,
      descripcion: descripcion ?? this.descripcion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      creadoPor: creadoPor ?? responsable ?? this.creadoPor,
      actualizadoPor: actualizadoPor ?? responsable ?? this.actualizadoPor,
    );
  }

  factory Gasto.fromJson(Map<String, dynamic> json) {
    DateTime? _parseFecha(dynamic valor) {
      if (valor is DateTime) return valor;
      if (valor is String) return DateTime.tryParse(valor);
      if (valor is Timestamp) return valor.toDate();
      if (valor is Map && valor['__type__'] == 'timestamp') {
        final seconds = valor['_seconds'] as int?;
        final nanos = valor['_nanoseconds'] as int?;
        if (seconds != null && nanos != null) {
          return DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + nanos ~/ 1000000,
          );
        }
      }
      return null;
    }

    return Gasto(
      id: json['id'] as String? ?? '',
      fechaGasto:
          _parseFecha(json['fechaGasto'] ?? json['fecha_gasto']) ??
          DateTime.now(),
      monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
      empresaId:
          json['empresaId'] as String? ?? json['id_empresa'] as String? ?? '',
      trabajoAsignadoId:
          json['trabajoAsignadoId'] as String? ??
          json['trabajo_asignado_id'] as String? ??
          '',
      trabajoId:
          json['trabajoId'] as String? ?? json['id_trabajo'] as String? ?? '',
      clienteId:
          json['clienteId'] as String? ?? json['id_cliente'] as String? ?? '',
      activo: json['activo'] as bool? ?? true,
      urlComprobante:
          json['urlComprobante'] as String? ??
          json['url_comprobante'] as String? ??
          '',
      idTipoGasto:
          json['idTipoGasto'] as String? ??
          json['idtipogasto'] as String? ??
          '',
      descripcion: json['descripcion'] as String? ?? '',
      fechaCreacion: _parseFecha(
        json['fechaCreacion'] ?? json['fecha_creacion'],
      ),
      fechaActualizacion: _parseFecha(
        json['fechaActualizacion'] ?? json['fecha_actualizacion'],
      ),
      creadoPor:
          json['creadoPor'] as String? ?? json['responsable'] as String? ?? '',
      actualizadoPor:
          json['actualizadoPor'] as String? ??
          json['responsable'] as String? ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      // No incluir 'id' - Firestore lo genera automáticamente
      'fechaGasto': fechaGasto.toIso8601String(),
      'monto': monto,
      'empresaId': empresaId,
      // Se incluyen los identificadores de asignación, trabajo y cliente
      // para mantener la relación entre el gasto y la ejecución concreta
      // del servicio.  Estos campos son opcionales, pero proporcionan un
      // enlace directo sin necesidad de consultar la colección de
      // asignaciones.
      if (trabajoAsignadoId.isNotEmpty) 'trabajoAsignadoId': trabajoAsignadoId,
      if (trabajoId.isNotEmpty) 'trabajoId': trabajoId,
      if (clienteId.isNotEmpty) 'clienteId': clienteId,
      'activo': activo,
      'urlComprobante': urlComprobante,
      'idTipoGasto': idTipoGasto,
      'descripcion': descripcion,
      'creadoPor': creadoPor,
      'actualizadoPor': actualizadoPor,
    };
    if (fechaCreacion != null) {
      data['fechaCreacion'] = fechaCreacion!.toIso8601String();
    }
    if (fechaActualizacion != null) {
      data['fechaActualizacion'] = fechaActualizacion!.toIso8601String();
    }
    return data;
  }
}
