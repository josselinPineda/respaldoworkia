import 'package:flutter/foundation.dart';

/// Modelo que representa un trabajo o servicio que realiza la empresa.
///
/// Cada trabajo está asociado a un cliente, tiene un título descriptivo,
/// un rango de fechas de ejecución, un estado (pendiente, en progreso,
/// completo o cancelado) y un costo que representa el ingreso que
/// generará al finalizarse.
@immutable
class Trabajo {
  /// Identificador único del trabajo.
  final String id;

  /// Título o nombre del trabajo.
  final String titulo;

  /// Nombre del cliente asociado a este trabajo.
  final String cliente;

  /// Fecha de inicio del trabajo.
  final DateTime fechaInicio;

  /// Fecha de fin del trabajo.
  final DateTime fechaFin;

  /// Estado actual del trabajo (Pendiente, En Progreso, Completo, Cancelado).
  final String estado;

  /// Descripción detallada del trabajo.
  final String descripcion;

  /// Monto de ingreso asociado a este trabajo al terminarlo.
  final double costo;

  /// Indica si el trabajo es de carácter cíclico.
  final bool esCiclico;

  /// Frecuencia con la que se repite un trabajo cíclico.
  final String? frecuenciaCiclico;

  /// Próxima fecha programada para ejecutar un trabajo cíclico.
  final DateTime? proximaFecha;

  /// Lista de identificadores de empleados asignados a este trabajo.
  final List<String> empleadosAsignados;

  /// Lista de nombres o identificadores de clientes asignados a este trabajo.
  final List<String> clientesAsignados;

  /// Identificador del cliente principal asociado a este trabajo.
  final String clienteId;

  /// Identificador de la empresa que administra este trabajo.
  final String empresaId;

  /// Fecha de creación del registro en Firestore.
  final DateTime? fechaCreacion;

  /// Fecha de la última actualización del registro en Firestore.
  final DateTime? fechaActualizacion;

  /// Identificador del usuario que creó este registro.
  final String creadoPor;

  /// Identificador del usuario que actualizó por última vez este registro.
  final String actualizadoPor;

  /// Latitud de la ubicación del trabajo (colección `trabajos.latitud`).
  final double? latitud;

  /// Longitud de la ubicación del trabajo (colección `trabajos.longitud`).
  final double? longitud;

  /// Indica si el trabajo está activo (eliminado lógicamente o no).
  final bool activo;

  /// Horas de tolerancia para auto-finalizar asignaciones iniciadas de este trabajo.
  /// Se usa como valor por defecto en las asignaciones si no se define uno específico.
  final int? autoFinalizarHoras;

  const Trabajo({
    this.id = '',
    required this.titulo,
    required this.cliente,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    this.descripcion = '',
    this.costo = 0.0,
    this.esCiclico = false,
    this.frecuenciaCiclico,
    this.proximaFecha,
    this.empleadosAsignados = const [],
    this.clientesAsignados = const [],
    this.clienteId = '',
    this.empresaId = '',
    this.fechaCreacion,
    this.fechaActualizacion,
    this.creadoPor = '',
    this.actualizadoPor = '',
    this.latitud,
    this.longitud,
    this.activo = true,
    this.autoFinalizarHoras,
  });

  /// Factory constructor para crear un Trabajo vacío (usado como fallback en orElse).
  factory Trabajo.empty() => Trabajo(
    id: '',
    titulo: '',
    cliente: '',
    fechaInicio: DateTime.now(),
    fechaFin: DateTime.now(),
    estado: '',
    descripcion: '',
    empresaId: '',
  );

  /// Devuelve una copia del trabajo con algunos campos modificados.
  ///
  /// Este método se usa para actualizar una instancia inmutable sin
  /// cambiar el objeto original. Solo se reemplazan los campos que se
  /// pasan como parámetros; el resto conserva su valor actual.
  Trabajo copyWith({
    String? id,
    String? titulo,
    String? cliente,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? estado,
    String? descripcion,
    double? costo,
    bool? esCiclico,
    String? frecuenciaCiclico,
    DateTime? proximaFecha,
    List<String>? empleadosAsignados,
    List<String>? clientesAsignados,
    String? clienteId,
    String? empresaId,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? creadoPor,
    String? actualizadoPor,
    double? latitud,
    double? longitud,
    bool? activo,
    int? autoFinalizarHoras,
  }) {
    return Trabajo(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      cliente: cliente ?? this.cliente,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      estado: estado ?? this.estado,
      descripcion: descripcion ?? this.descripcion,
      costo: costo ?? this.costo,
      esCiclico: esCiclico ?? this.esCiclico,
      frecuenciaCiclico: frecuenciaCiclico ?? this.frecuenciaCiclico,
      proximaFecha: proximaFecha ?? this.proximaFecha,
      empleadosAsignados: empleadosAsignados ?? this.empleadosAsignados,
      clientesAsignados: clientesAsignados ?? this.clientesAsignados,
      clienteId: clienteId ?? this.clienteId,
      empresaId: empresaId ?? this.empresaId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      creadoPor: creadoPor ?? this.creadoPor,
      actualizadoPor: actualizadoPor ?? this.actualizadoPor,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      activo: activo ?? this.activo,
      autoFinalizarHoras: autoFinalizarHoras ?? this.autoFinalizarHoras,
    );
  }

  /// Devuelve una cadena formateada con el rango de fechas del trabajo.
  String get rangoFechas =>
      '${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year} - '
      '${fechaFin.day}/${fechaFin.month}/${fechaFin.year}';

  /// Crea un [Trabajo] desde un JSON.
  ///
  /// El JSON puede venir de distintas fuentes: Firestore, una API o un
  /// fichero. Este método maneja varios formatos de fecha y nombres de
  /// campo alternativos para garantizar compatibilidad.
  factory Trabajo.fromJson(Map<String, dynamic> json) {
    DateTime? _parseFecha(dynamic valor) {
      // Convierte distintos formatos de fecha a DateTime.
      if (valor == null) return null;
      if (valor is DateTime) return valor;
      if (valor is String && valor.isNotEmpty) {
        return DateTime.tryParse(valor);
      }
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

    // Convierte valores numéricos o cadenas a double.
    // Esto permite aceptar tanto JSON con números como con texto.
    double? _parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    // Asegura convertir cualquier lista de valores a una lista de cadenas.
    // Esto es útil cuando Firestore devuelve un List<dynamic>.
    List<String> _parseLista(dynamic v) {
      if (v is Iterable) {
        return v.map((e) => e.toString()).toList();
      }
      return const [];
    }

    return Trabajo(
      id: json['id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? json['title'] as String? ?? '',
      cliente: json['cliente'] as String? ?? json['client'] as String? ?? '',
      clienteId:
          json['clienteId'] as String? ?? json['cliente_id'] as String? ?? '',
      empresaId:
          json['empresaId'] as String? ?? json['empresa_id'] as String? ?? '',
      fechaInicio:
          _parseFecha(json['fechaInicio'] ?? json['startDate']) ??
          DateTime.now(),
      fechaFin:
          _parseFecha(json['fechaFin'] ?? json['endDate']) ?? DateTime.now(),
      estado: json['estado'] as String? ?? json['status'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      costo: _parseDouble(json['costo']) ?? 0.0,
      esCiclico: json['esCiclico'] as bool? ?? false,
      frecuenciaCiclico: json['frecuenciaCiclico'] as String?,
      proximaFecha: _parseFecha(json['proximaFecha'] ?? json['proxima_fecha']),
      empleadosAsignados: _parseLista(json['empleadosAsignados']),
      clientesAsignados: _parseLista(json['clientesAsignados']),
      fechaCreacion: _parseFecha(
        json['fechaCreacion'] ?? json['fecha_creacion'],
      ),
      fechaActualizacion: _parseFecha(
        json['fechaActualizacion'] ?? json['fecha_actualizacion'],
      ),
      creadoPor: json['creadoPor'] as String? ?? '',
      actualizadoPor: json['actualizadoPor'] as String? ?? '',
      latitud: _parseDouble(json['latitud']),
      longitud: _parseDouble(json['longitud']),
      activo: json['activo'] as bool? ?? true,
      autoFinalizarHoras: (json['autoFinalizarHoras'] as num?)?.toInt(),
    );
  }

  /// Convierte este [Trabajo] a JSON.
  ///
  /// Este JSON se usa para persistencia en Firestore o para enviar al
  /// backend. Sólo incluyimos los campos necesarios y evitamos serializar
  /// valores nulos o vacíos innecesarios.
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'titulo': titulo,
      'cliente': cliente,
      'clienteId': clienteId,
      'empresaId': empresaId,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      'estado': estado,
      'descripcion': descripcion,
      'costo': costo,
      'esCiclico': esCiclico,
      'activo': activo,
    };

    if (frecuenciaCiclico != null) {
      data['frecuenciaCiclico'] = frecuenciaCiclico;
    }
    if (proximaFecha != null) {
      data['proximaFecha'] = proximaFecha!.toIso8601String();
    }
    if (empleadosAsignados.isNotEmpty) {
      data['empleadosAsignados'] = empleadosAsignados;
    }
    if (clientesAsignados.isNotEmpty) {
      data['clientesAsignados'] = clientesAsignados;
    }
    if (fechaCreacion != null) {
      data['fechaCreacion'] = fechaCreacion!.toIso8601String();
    }
    if (fechaActualizacion != null) {
      data['fechaActualizacion'] = fechaActualizacion!.toIso8601String();
    }
    if (creadoPor.isNotEmpty) {
      data['creadoPor'] = creadoPor;
    }
    if (actualizadoPor.isNotEmpty) {
      data['actualizadoPor'] = actualizadoPor;
    }
    if (latitud != null) {
      data['latitud'] = latitud;
    }
    if (longitud != null) {
      data['longitud'] = longitud;
    }
    if (autoFinalizarHoras != null) {
      data['autoFinalizarHoras'] = autoFinalizarHoras;
    }

    return data;
  }
}

/// Alias de compatibilidad.
typedef Job = Trabajo;
