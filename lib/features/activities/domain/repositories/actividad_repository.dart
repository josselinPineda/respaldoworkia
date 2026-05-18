import '../entities/actividad.dart';

/// Contrato para gestionar las actividades registradas sobre trabajos asignados.
abstract class ActividadRepository {
  /// Obtiene las actividades asociadas a un trabajo asignado dentro de una empresa.
  Future<List<Actividad>> obtenerActividades(
    String trabajoAsignadoId,
    String empresaId,
  );

  /// Obtiene todas las actividades de una empresa.
  Future<List<Actividad>> obtenerTodasActividades(String empresaId);

  /// Registra una nueva actividad.
  Future<void> agregarActividad(Actividad actividad);

  /// Actualiza una actividad existente.
  Future<void> actualizarActividad(Actividad actividad);

  /// Elimina una actividad por su ID (borrado lógico).
  Future<void> eliminarActividad(String id, String actualizadoPor);
}
