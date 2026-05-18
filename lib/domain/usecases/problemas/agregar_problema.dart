import '../../repositories/problema_repository.dart';
import '../../../models/problem.dart';

/// Caso de uso para reportar un nuevo problema.
class AgregarProblema {
  final ProblemaRepository _repository;
  AgregarProblema(this._repository);

  Future<void> call(Problema problema) {
    return _repository.agregarProblema(problema);
  }
}