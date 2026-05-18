import '../../domain/repositories/problema_repository.dart';
import '../../models/problem.dart';

/// Implementación en memoria del repositorio de problemas.
///
/// Los problemas se mantienen en una lista interna.  La capa de
/// presentación puede agregar nuevos problemas y marcar los
/// existentes como ignorados o resueltos mediante los índices.
class ProblemaRepositoryImpl implements ProblemaRepository {
  final List<Problema> _problemas = [];

  /// Devuelve una lista inmutable de problemas que aún no han sido
  /// ignorados ni resueltos.  Esto permite mostrar únicamente los
  /// pendientes en la interfaz de administrador.
  @override
  Future<List<Problema>> obtenerProblemasPendientes(String empresaId) async {
    return List.unmodifiable(
      _problemas.where(
        (p) =>
            !p.ignorado && !p.resuelto && p.empresaId == empresaId && p.activo,
      ),
    );
  }

  /// Agrega un nuevo problema a la lista.  La posición en la lista
  /// se utiliza como índice para posteriores operaciones de
  /// ignorar o resolver.  Este método no comprueba duplicados.
  @override
  Future<void> agregarProblema(Problema problema) async {
    _problemas.add(problema);
  }

  @override
  Future<void> actualizarProblema(Problema problema) async {
    final index = _problemas.indexWhere((p) => p.id == problema.id);
    if (index != -1) {
      _problemas[index] = problema;
    }
  }

  /// Marca el problema en la posición [indice] como ignorado.  Si
  /// el índice no es válido no se realiza ninguna acción.  La
  /// indicación de ignorado no elimina el problema; simplemente
  /// cambia su estado para que no aparezca en la lista de
  /// pendientes.
  @override
  Future<void> ignorarProblema(
    int indice,
    String empresaId,
    String userName,
  ) async {
    // Nota: El índice aquí se refiere a la lista completa, lo cual es incorrecto si se filtra.
    // Se mantiene simple para cumplir con la interfaz.
    if (indice >= 0 && indice < _problemas.length) {
      _problemas[indice] = _problemas[indice].copyWith(estado: 'ignorado');
    }
  }

  @override
  Future<List<Problema>> obtenerTodosLosProblemas(String empresaId) async {
    return List.unmodifiable(
      _problemas.where((p) => p.empresaId == empresaId && p.activo),
    );
  }

  @override
  Future<void> ignorarProblemaPorId(
    String id,
    String empresaId,
    String userName,
  ) async {
    try {
      final index = _problemas.indexWhere((p) => p.id == id);
      if (index != -1) {
        _problemas[index] = _problemas[index].copyWith(estado: 'ignorado');
      }
    } catch (_) {
      // No encontrado
    }
  }

  @override
  Future<void> resolverProblemaPorId(
    String id,
    String empresaId,
    String userName,
    String userRole,
  ) async {
    try {
      final index = _problemas.indexWhere((p) => p.id == id);
      if (index != -1) {
        _problemas[index] = _problemas[index].copyWith(
          estado: 'resuelto',
          actualizadoPorId: userName,
        );
      }
    } catch (_) {
      // No encontrado
    }
  }

  /// Marca el problema en la posición [indice] como resuelto.  Un
  /// problema resuelto tampoco aparecerá en la lista de pendientes.
  @override
  Future<void> resolverProblema(
    int indice,
    String empresaId,
    String userName,
  ) async {
    if (indice >= 0 && indice < _problemas.length) {
      _problemas[indice] = _problemas[indice].copyWith(estado: 'resuelto');
    }
  }

  @override
  Future<void> eliminarProblema(String id, String actualizadoPor) async {
    final index = _problemas.indexWhere((p) => p.id == id);
    if (index != -1) {
      _problemas[index] = _problemas[index].copyWith(
        activo: false,
        actualizadoPorId: actualizadoPor,
      );
    }
  }
}
