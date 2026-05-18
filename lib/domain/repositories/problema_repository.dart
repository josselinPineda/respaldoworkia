import '../../models/problem.dart';

/// Contrato para gestionar problemas reportados.
abstract class ProblemaRepository {
  /// Devuelve la lista de todos los problemas (pendientes, ignorados y resueltos).
  Future<List<Problema>> obtenerTodosLosProblemas(String empresaId);

  /// Devuelve la lista de problemas que no han sido ni ignorados ni
  /// resueltos.  Se utiliza para mostrar únicamente los pendientes.
  Future<List<Problema>> obtenerProblemasPendientes(String empresaId);

  /// Agrega un nuevo problema al repositorio.
  Future<void> agregarProblema(Problema problema);

  /// Actualiza un problema existente.
  Future<void> actualizarProblema(Problema problema);

  /// Marca el problema con [id] como ignorado.
  /// [userName] se guarda en el campo actualizadoPor.
  Future<void> ignorarProblemaPorId(String id, String empresaId, String userId);

  /// Marca el problema con [id] como resuelto.
  /// [userName] se guarda en el campo actualizadoPor.
  Future<void> resolverProblemaPorId(
    String id,
    String empresaId,
    String userId,
    String userRole,
  );

  /// DEPRECATED: Use ignorarProblemaPorId instead.
  Future<void> ignorarProblema(int indice, String empresaId, String userName);

  /// DEPRECATED: Use resolverProblemaPorId instead.
  Future<void> resolverProblema(int indice, String empresaId, String userName);

  /// Elimina (lógicamente) un problema dado su ID.
  Future<void> eliminarProblema(String id, String actualizadoPor);
}
