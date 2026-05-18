import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa la asignación de un trabajo a un cliente y los
/// técnicos responsables de realizarlo. Este modelo se utiliza en la
/// colección `trabajosAsignados` de Firestore para registrar cada
/// combinación concreta de trabajo, cliente y técnico(s) junto con
/// información de programación y estado. Almacenar las asignaciones
/// separadas de la definición del catálogo de trabajos permite
/// asociar múltiples clientes y técnicos a un mismo trabajo sin
/// duplicar la definición general del servicio.
class TrabajoAsignado {
  /// Identificador único del documento en Firestore. Puede ser vacío
  /// cuando la asignación aún no ha sido persistida.
  final String id;

  /// Identificador del trabajo de catálogo al que pertenece esta asignación.
  final String trabajoId;

  /// Título descriptivo del trabajo. Este campo no se persiste en
  /// Firestore, pero se conserva en memoria para mostrarlo en la UI.
  final String tituloTrabajo;

  /// Costo base del trabajo según el catálogo. Este valor sirve como
  /// referencia y tampoco se almacena en Firestore.
  final double precioBase;

  /// Costo final cobrado al cliente por esta asignación. Puede ser
  /// diferente al precio base si se aplican descuentos o cargos
  /// adicionales. Este valor se persiste en Firestore.
  final double precioFinal;

  /// Identificador del cliente al que se asigna el trabajo.
  final String clienteId;

  /// Estado actual de la asignación (por ejemplo: 'Pendiente',
  /// 'En_progreso', 'Finalizado', 'Cancelado').
  final String estado;

  /// Fecha y hora de inicio programada para la ejecución del trabajo.
  final DateTime fechaInicio;

  /// Fecha y hora de finalización programada para la ejecución del trabajo.
  final DateTime fechaFin;

  /// Próxima fecha de ejecución en caso de trabajos recurrentes. Nulo
  /// cuando no aplica.
  final DateTime? proximaFecha;

  /// Indica si el trabajo es de naturaleza cíclica (recurrente).
  final bool esCiclico;

  /// Frecuencia de repetición en caso de trabajos cíclicos (por
  /// ejemplo: 'Mensual', 'Anual'). Nulo cuando no aplica.
  final String? frecuenciaCiclico;

  /// Lista de identificadores de técnicos asignados a este trabajo.
  final List<String> tecnicosAsignados;

  /// Identificador de la empresa a la que pertenece esta asignación.
  final String empresaId;

  /// Indica si la asignación está activa. Las asignaciones canceladas
  /// deben marcarse como inactivas para no aparecer en listados.
  final bool activo;

  /// Fecha de creación del documento. Puede ser nula hasta que se
  /// persista en Firestore.
  final DateTime? fechaCreacion;

  /// Fecha de la última actualización del documento. Puede ser nula
  /// hasta que se persista en Firestore.
  final DateTime? fechaActualizacion;

  /// Identificador del usuario que creó la asignación. Puede ser una
  /// cadena vacía si no se registra.
  final String creadoPor;

  /// Identificador del usuario que actualizó por última vez la asignación.
  /// Puede ser una cadena vacía si no se registra.
  final String actualizadoPor;

  /// Caché de horas acumuladas por técnico.
  /// Se actualiza automáticamente cuando se cierra una sesión de trabajo.
  /// { 'techId': totalHoras }
  final Map<String, double> horasAcumuladas;

  /// Horas de tolerancia para auto-finalizar la asignaciÃ³n cuando estÃ© INICIADO,
  /// no tenga sesiones activas y ya pasÃ³ `fechaFin + autoFinalizarHoras`.
  final int? autoFinalizarHoras;

  /// Tiempos configurables (manuales) por fase, en minutos.
  /// No automatizan el flujo; sirven como referencia/configuraciÃ³n para el admin.
  final int? tiempoEnEsperaMin;
  final int? tiempoIniciadoMin;
  final int? tiempoFinalizadoMin;
  final int? tiempoCerradoMin;

  const TrabajoAsignado({
    required this.id,
    required this.trabajoId,
    required this.tituloTrabajo,
    required this.precioBase,
    required this.precioFinal,
    required this.clienteId,
    required this.estado,
    required this.fechaInicio,
    required this.fechaFin,
    this.proximaFecha,
    required this.esCiclico,
    this.frecuenciaCiclico,
    required this.tecnicosAsignados,
    required this.empresaId,
    required this.activo,
    this.fechaCreacion,
    this.fechaActualizacion,
    required this.creadoPor,
    required this.actualizadoPor,
    this.horasAcumuladas = const {},
    this.autoFinalizarHoras,
    this.tiempoEnEsperaMin,
    this.tiempoIniciadoMin,
    this.tiempoFinalizadoMin,
    this.tiempoCerradoMin,
  });

  /// Construye una instancia a partir de un mapa de datos.
  ///
  /// El JSON puede venir de Firestore o de otras fuentes. Las fechas
  /// pueden estar en formato `Timestamp` o `DateTime`, y se convierten
  /// correctamente para usarlas en la aplicación.
  factory TrabajoAsignado.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return TrabajoAsignado(
      id: (json['id'] as String?) ?? '',
      trabajoId: (json['trabajoId'] as String?) ?? '',
      tituloTrabajo: (json['tituloTrabajo'] as String?) ?? '',
      precioBase: (json['precioBase'] as num?)?.toDouble() ?? 0.0,
      precioFinal: (json['precioFinal'] as num?)?.toDouble() ?? 0.0,
      clienteId: (json['clienteId'] as String?) ?? '',
      estado: (json['estado'] as String?) ?? '',
      fechaInicio:
          _parseDate(json['fechaInicio'] ?? json['startDate']) ??
          DateTime.now(),
      fechaFin:
          _parseDate(json['fechaFin'] ?? json['endDate']) ?? DateTime.now(),
      proximaFecha: _parseDate(json['proximaFecha']),
      esCiclico: (json['esCiclico'] as bool?) ?? false,
      frecuenciaCiclico: json['frecuenciaCiclico'] as String?,
      tecnicosAsignados:
          (json['tecnicosAsignados'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[],
      empresaId: (json['empresaId'] as String?) ?? '',
      activo: (json['activo'] as bool?) ?? true,
      fechaCreacion: _parseDate(json['fechaCreacion']),
      fechaActualizacion: _parseDate(json['fechaActualizacion']),
      creadoPor: (json['creadoPor'] as String?) ?? '',
      actualizadoPor: (json['actualizadoPor'] as String?) ?? '',
      horasAcumuladas: json['horasAcumuladas'] != null
          ? Map<String, double>.from(
              (json['horasAcumuladas'] as Map).map(
                (k, v) => MapEntry(k as String, (v as num).toDouble()),
              ),
            )
          : const {},
      autoFinalizarHoras: (json['autoFinalizarHoras'] as num?)?.toInt(),
      tiempoEnEsperaMin: (json['tiempoEnEsperaMin'] as num?)?.toInt(),
      tiempoIniciadoMin: (json['tiempoIniciadoMin'] as num?)?.toInt(),
      tiempoFinalizadoMin: (json['tiempoFinalizadoMin'] as num?)?.toInt(),
      tiempoCerradoMin: (json['tiempoCerradoMin'] as num?)?.toInt(),
    );
  }

  /// Convierte esta instancia a un mapa para almacenar en Firestore.
  ///
  /// Solo persiste los campos que forman parte de la asignación real.
  /// Los datos redundantes del catálogo (como título y precio base)
  /// se omiten porque se pueden obtener del trabajo original.
  Map<String, dynamic> toJson() {
    return {
      'trabajoId': trabajoId,
      'clienteId': clienteId,
      'precioFinal': precioFinal,
      'estado': estado,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': Timestamp.fromDate(fechaFin),
      if (proximaFecha != null)
        'proximaFecha': Timestamp.fromDate(proximaFecha!),
      'esCiclico': esCiclico,
      if (frecuenciaCiclico != null) 'frecuenciaCiclico': frecuenciaCiclico,
      'tecnicosAsignados': tecnicosAsignados,
      'empresaId': empresaId,
      'activo': activo,
      'fechaCreacion': fechaCreacion != null
          ? Timestamp.fromDate(fechaCreacion!)
          : Timestamp.fromDate(DateTime.now()),
      'fechaActualizacion': fechaActualizacion != null
          ? Timestamp.fromDate(fechaActualizacion!)
          : Timestamp.fromDate(DateTime.now()),
      if (creadoPor.isNotEmpty) 'creadoPor': creadoPor,
      if (actualizadoPor.isNotEmpty) 'actualizadoPor': actualizadoPor,
      'horasAcumuladas': horasAcumuladas,
      if (autoFinalizarHoras != null) 'autoFinalizarHoras': autoFinalizarHoras,
      if (tiempoEnEsperaMin != null) 'tiempoEnEsperaMin': tiempoEnEsperaMin,
      if (tiempoIniciadoMin != null) 'tiempoIniciadoMin': tiempoIniciadoMin,
      if (tiempoFinalizadoMin != null)
        'tiempoFinalizadoMin': tiempoFinalizadoMin,
      if (tiempoCerradoMin != null) 'tiempoCerradoMin': tiempoCerradoMin,
    };
  }

  /// Crea una copia de este trabajo asignado con los campos modificados.
  TrabajoAsignado copyWith({
    String? id,
    String? trabajoId,
    String? tituloTrabajo,
    double? precioBase,
    double? precioFinal,
    String? clienteId,
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    DateTime? proximaFecha,
    bool? esCiclico,
    String? frecuenciaCiclico,
    List<String>? tecnicosAsignados,
    String? empresaId,
    bool? activo,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? creadoPor,
    String? actualizadoPor,
    Map<String, double>? horasAcumuladas,
    int? autoFinalizarHoras,
    int? tiempoEnEsperaMin,
    int? tiempoIniciadoMin,
    int? tiempoFinalizadoMin,
    int? tiempoCerradoMin,
  }) {
    return TrabajoAsignado(
      id: id ?? this.id,
      trabajoId: trabajoId ?? this.trabajoId,
      tituloTrabajo: tituloTrabajo ?? this.tituloTrabajo,
      precioBase: precioBase ?? this.precioBase,
      precioFinal: precioFinal ?? this.precioFinal,
      clienteId: clienteId ?? this.clienteId,
      estado: estado ?? this.estado,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      proximaFecha: proximaFecha ?? this.proximaFecha,
      esCiclico: esCiclico ?? this.esCiclico,
      frecuenciaCiclico: frecuenciaCiclico ?? this.frecuenciaCiclico,
      tecnicosAsignados:
          tecnicosAsignados ?? List<String>.from(this.tecnicosAsignados),
      empresaId: empresaId ?? this.empresaId,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      creadoPor: creadoPor ?? this.creadoPor,
      actualizadoPor: actualizadoPor ?? this.actualizadoPor,
      horasAcumuladas: horasAcumuladas ?? Map.from(this.horasAcumuladas),
      autoFinalizarHoras: autoFinalizarHoras ?? this.autoFinalizarHoras,
      tiempoEnEsperaMin: tiempoEnEsperaMin ?? this.tiempoEnEsperaMin,
      tiempoIniciadoMin: tiempoIniciadoMin ?? this.tiempoIniciadoMin,
      tiempoFinalizadoMin: tiempoFinalizadoMin ?? this.tiempoFinalizadoMin,
      tiempoCerradoMin: tiempoCerradoMin ?? this.tiempoCerradoMin,
    );
  }
}
