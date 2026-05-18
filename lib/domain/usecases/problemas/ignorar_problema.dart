import '../../repositories/problema_repository.dart';

/// Caso de uso para ignorar un problema existente.
class IgnorarProblema {
  final ProblemaRepository _repository;
  IgnorarProblema(this._repository);

  Future<void> call(String id, String empresaId, String userName) {
    return _repository.ignorarProblemaPorId(id, empresaId, userName);
  }
}
