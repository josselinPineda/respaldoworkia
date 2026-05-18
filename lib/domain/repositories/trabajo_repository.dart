import '../../models/job.dart';

/// Contrato para gestionar trabajos (servicios) de la empresa.
abstract class TrabajoRepository {
  Future<List<Trabajo>> obtenerTrabajos(String empresaId);
  Future<void> agregarTrabajo(Trabajo trabajo);
  Future<void> actualizarTrabajo(Trabajo trabajo);
  Future<void> cancelarTrabajo(String id, String actualizadoPor);
  Future<List<Trabajo>> buscarTrabajos(String consulta, String empresaId);
}
