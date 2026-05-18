import '../../repositories/problema_repository.dart';

/// Caso de uso para marcar un problema como resuelto.
class ResolverProblema {
  final ProblemaRepository _repository;
  ResolverProblema(this._repository);

  Future<void> call(
    String id,
    String empresaId,
    String userId,
    String userRole,
  ) {
    return _repository.resolverProblemaPorId(id, empresaId, userId, userRole);
  }
}
