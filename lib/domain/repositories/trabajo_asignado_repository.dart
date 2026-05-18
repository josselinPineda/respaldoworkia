// La ruta relativa para importar el modelo debe subir dos niveles
// desde la carpeta `domain/repositories` hasta `lib/models`.
// La ruta relativa para importar el modelo debe subir dos niveles
// desde la carpeta `domain/repositories` hasta `lib/models`.
import '../../models/trabajo_asignado.dart';

/// Contrato abstracto para gestionar la colección `trabajosAsignados` en
/// la capa de dominio. Define las operaciones de negocio básicas
/// relacionadas con las asignaciones de trabajos a clientes.
abstract class TrabajoAsignadoRepository {
  /// Obtiene la lista de todas las asignaciones existentes para una empresa.
  Future<List<TrabajoAsignado>> obtenerTrabajosAsignados(String empresaId);

  /// Auto-finaliza trabajos iniciados expirados según una tolerancia en horas.
  /// Regla: si `estado == INICIADO` y `sesionesActivas == 0` y ya pasó
  /// `fechaFin + horasTolerancia`, se marca como `FINALIZADO`.
  /// Devuelve cuántos documentos se actualizaron.
  Future<int> autoFinalizarTrabajosExpirados(
    String empresaId, {
    required int horasTolerancia,
    DateTime? now,
  });

  /// Agrega una nueva asignación. Si el campo [TrabajoAsignado.id] está
  /// vacío, la implementación debe generar un identificador único.
  Future<void> agregarTrabajoAsignado(TrabajoAsignado trabajoAsignado);

  /// Actualiza una asignación existente. La implementación debe
  /// verificar que el [id] no esté vacío antes de proceder.
  Future<void> actualizarTrabajoAsignado(TrabajoAsignado trabajoAsignado);

  /// Marca una asignación como cancelada. La implementación puede
  /// actualizar el campo `estado` y establecer `activo` en `false`.
  Future<void> cancelarTrabajoAsignado(String id, String actualizadoPor);

  /// Devuelve las asignaciones de una empresa cuyo identificador de trabajo, cliente o
  /// estado coincida con la [consulta] (sin distinción entre mayúsculas
  /// y minúsculas). Si la consulta es vacía, devuelve todas las
  /// asignaciones.
  Future<List<TrabajoAsignado>> buscarTrabajosAsignados(
    String consulta,
    String empresaId,
  );
}
