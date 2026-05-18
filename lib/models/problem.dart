import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

/// A model representing a problem reported by a technician.
///
/// Refactored to match the simplified schema:
/// - empresaId: string
/// - trabajoAsignadoId: string
/// - titulo: string
/// - descripcion: string
/// - direccion: string | null
/// - fotoUrl: string | null
/// - reportadoPorId: string
/// - estado: 'pendiente' | 'resuelto'
/// - activo: boolean
/// - creadoPorId: string
/// - actualizadoPorId: string
/// - fechaCreacion: Timestamp
/// - fechaActualizacion: Timestamp
class Problema {
  /// Identificador único del problema.
  final String id;

  /// Título breve que describe el problema.
  final String titulo;

  /// Descripción detallada del problema (antes detalles).
  final String descripcion;

  /// ID del usuario que reportó el problema.
  final String reportadoPorId;

  /// Estado del problema: 'pendiente' | 'resuelto'.
  final String estado;

  /// Fecha en que se creó el problema.
  final DateTime? fechaCreacion;

  /// Fecha de la última actualización.
  final DateTime? fechaActualizacion;

  /// Identificador de la asignación de trabajo.
  final String trabajoAsignadoId;

  /// Identificador de la empresa.
  final String empresaId;

  /// Indica si el registro está activo.
  final bool activo;

  /// ID del usuario que creó el registro.
  final String creadoPorId;

  /// ID del usuario que actualizó por última vez el registro.
  final String actualizadoPorId;

  /// ID del usuario que resolvió el problema.
  final String resueltoPorId;

  // --- Campos Transitorios (No guardados en DB, usados en UI) ---
  // Estos campos se mantienen para compatibilidad con la UI actual,
  // pero no se guardan directamente en la colección 'problemas' bajo este nombre
  // o se derivan de los IDs.

  final String nombreReportante;
  final String rolReportante;
  final String? rolResueltoPor;
  final String referenciaTipo;
  final String? referenciaId;
  final String trabajoId;
  final String clienteId;

  Problema({
    this.id = '',
    String? titulo,
    String? descripcion,
    String? reportadoPorId,
    String? estado,
    this.fechaCreacion,
    this.fechaActualizacion,
    this.trabajoAsignadoId = '',
    this.empresaId = '',
    this.activo = true,
    String? creadoPorId,
    String? actualizadoPorId,
    this.resueltoPorId = '',
    // Campos transitorios / compatibilidad
    String? detalles, // Alias para descripcion

    bool? ignorado, // Alias para estado
    bool? resuelto, // Alias para estado
    this.nombreReportante = '',
    this.rolReportante = '',
    this.rolResueltoPor,
    this.referenciaTipo = 'Otro',
    this.referenciaId,
    this.trabajoId = '',
    this.clienteId = '',
    // Compatibilidad inglés
    String? title,
    String? details,
    String? reporterName,
    String? reporterRole,
  }) : titulo = titulo ?? title ?? '',
       descripcion = descripcion ?? details ?? detalles ?? '',
       reportadoPorId = reportadoPorId ?? '',
       estado =
           estado ??
           ((resuelto == true)
               ? 'resuelto'
               : (ignorado == true ? 'ignorado' : 'pendiente')),

       // Si no se pasa creadoPorId, usamos reportadoPorId como fallback o vacío
       creadoPorId = creadoPorId ?? '',
       actualizadoPorId = actualizadoPorId ?? '';

  // -------------------------------------------------------------------------
  // Getters de compatibilidad
  // -------------------------------------------------------------------------

  String get title => titulo;
  String get details => descripcion;
  String get detalles => descripcion;
  String get reporterName => nombreReportante;
  String get reporterRole => rolReportante;

  bool get ignored => estado == 'ignorado';
  bool get ignorado => estado == 'ignorado';
  bool get resolved => estado == 'resuelto';
  bool get resuelto => estado == 'resuelto';
  String get creadoPor => creadoPorId;
  String get actualizadoPor => actualizadoPorId;

  // Setters de compatibilidad (actualizan estado, pero Problema es inmutable,
  // así que esto solo sirve si se usa en lógica mutable que no debería existir)
  set ignored(bool value) {
    // No-op en objeto inmutable, usar copyWith
  }
  set resuelto(bool value) {
    // No-op
  }

  /// Crea una copia del objeto actual con los campos modificados.
  Problema copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    String? reportadoPorId,
    String? estado,

    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? trabajoAsignadoId,
    String? empresaId,
    bool? activo,
    String? creadoPorId,
    String? actualizadoPorId,
    String? resueltoPorId,
    // Transitorios
    String? nombreReportante,
    String? rolReportante,
    String? rolResueltoPor,
    String? referenciaTipo,
    String? referenciaId,
    String? trabajoId,
    String? clienteId,
    // Compatibilidad
    String? detalles,

    bool? ignorado,
    bool? resuelto,
    String? creadoPor,
    String? actualizadoPor,
  }) {
    // Lógica para estado
    String? nuevoEstado = estado;
    if (resuelto != null) {
      nuevoEstado = resuelto ? 'resuelto' : 'pendiente';
    } else if (ignorado != null) {
      nuevoEstado = ignorado ? 'ignorado' : 'pendiente';
    }

    return Problema(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? detalles ?? this.descripcion,
      reportadoPorId: reportadoPorId ?? this.reportadoPorId,
      estado: nuevoEstado ?? this.estado,

      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      trabajoAsignadoId: trabajoAsignadoId ?? this.trabajoAsignadoId,
      empresaId: empresaId ?? this.empresaId,
      activo: activo ?? this.activo,
      creadoPorId: creadoPorId ?? creadoPor ?? this.creadoPorId,
      actualizadoPorId:
          actualizadoPorId ?? actualizadoPor ?? this.actualizadoPorId,
      resueltoPorId: resueltoPorId ?? this.resueltoPorId,
      nombreReportante: nombreReportante ?? this.nombreReportante,
      rolReportante: rolReportante ?? this.rolReportante,
      rolResueltoPor: rolResueltoPor ?? this.rolResueltoPor,
      referenciaTipo: referenciaTipo ?? this.referenciaTipo,
      referenciaId: referenciaId ?? this.referenciaId,
      trabajoId: trabajoId ?? this.trabajoId,
      clienteId: clienteId ?? this.clienteId,
    );
  }

  /// Crea una instancia [Problema] a partir de un mapa JSON.
  /// Soporta tanto el esquema nuevo como el antiguo para migración suave.
  factory Problema.fromJson(Map<String, dynamic> json) {
    // Mapeo de campos antiguos a nuevos
    final String titulo =
        json['titulo'] as String? ?? json['title'] as String? ?? '';
    final String descripcion =
        json['descripcion'] as String? ??
        json['detalles'] as String? ??
        json['details'] as String? ??
        '';
    '';

    // Estado
    String estado = json['estado'] as String? ?? 'pendiente';
    if (json.containsKey('resuelto') && json['resuelto'] == true) {
      estado = 'resuelto';
    } else if (json.containsKey('ignorado') && json['ignorado'] == true) {
      estado = 'ignorado';
    }

    // IDs de usuario
    // Si no existe reportadoPorId, intentamos usar el nombre como fallback temporal
    // o lo dejamos vacío.
    final String reportadoPorId =
        json['reportadoPorId'] as String? ??
        json['creadoPorId'] as String? ??
        ''; // Fallback
    final String creadoPorId =
        json['creadoPorId'] as String? ??
        json['creadoPor'] as String? ??
        reportadoPorId;
    final String actualizadoPorId =
        json['actualizadoPorId'] as String? ??
        json['actualizadoPor'] as String? ??
        '';

    // Campos transitorios (si existen en DB antigua o se pasan)
    final String nombreReportante =
        json['nombreReportante'] as String? ??
        json['reporterName'] as String? ??
        '';
    final String rolReportante =
        json['rolReportante'] as String? ??
        json['reporterRole'] as String? ??
        '';
    final String? rolResueltoPor = json['rolResueltoPor'] as String?;

    return Problema(
      id: json['id'] as String? ?? '',
      titulo: titulo,
      descripcion: descripcion,
      reportadoPorId: reportadoPorId,
      estado: estado,

      fechaCreacion: _parseProblemaFecha(
        json['fechaCreacion'] ?? json['createdAt'],
      ),
      fechaActualizacion: _parseProblemaFecha(
        json['fechaActualizacion'] ?? json['updatedAt'],
      ),
      trabajoAsignadoId:
          json['trabajoAsignadoId'] as String? ??
          json['trabajo_asignado_id'] as String? ??
          '',
      empresaId:
          json['empresaId'] as String? ?? json['id_empresa'] as String? ?? '',
      activo: json['activo'] as bool? ?? true,
      creadoPorId: creadoPorId,
      actualizadoPorId: actualizadoPorId,
      resueltoPorId:
          json['resueltoPorId'] as String? ??
          json['resuelto_por'] as String? ??
          '',
      // Transitorios
      nombreReportante: nombreReportante,
      rolReportante: rolReportante,
      rolResueltoPor: rolResueltoPor,
      referenciaTipo: (json['trabajoAsignadoId'] as String? ?? '').isNotEmpty
          ? 'Trabajo'
          : (json['referenciaTipo'] as String? ?? 'Otro'),
      referenciaId: (json['trabajoAsignadoId'] as String? ?? '').isNotEmpty
          ? (json['trabajoAsignadoId'] as String?)
          : (json['referenciaId'] as String?),
      trabajoId:
          json['trabajoId'] as String? ?? json['id_trabajo'] as String? ?? '',
      clienteId:
          json['clienteId'] as String? ?? json['id_cliente'] as String? ?? '',
    );
  }

  /// Convierte esta instancia en un mapa JSON siguiendo ESTRICTAMENTE el nuevo esquema.
  Map<String, dynamic> toJson() {
    return {
      'empresaId': empresaId,
      'trabajoAsignadoId': trabajoAsignadoId,
      'trabajoId': trabajoId,
      'titulo': titulo,
      'descripcion': descripcion,
      'reportadoPorId': reportadoPorId,
      'estado': estado,
      'activo': activo,
      'creadoPorId': creadoPorId,
      'actualizadoPorId': actualizadoPorId,
      'resueltoPorId': resueltoPorId,
    };
  }
}

DateTime? _parseProblemaFecha(dynamic valor) {
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
