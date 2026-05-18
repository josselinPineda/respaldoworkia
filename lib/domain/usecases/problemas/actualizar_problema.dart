import '../../repositories/problema_repository.dart';
import '../../../models/problem.dart';

/// Caso de uso para actualizar un problema existente.
class ActualizarProblema {
  final ProblemaRepository _repository;
  ActualizarProblema(this._repository);

  Future<void> call(Problema problema) {
    return _repository.actualizarProblema(problema);
  }
}
