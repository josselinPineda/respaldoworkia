import '../../repositories/problema_repository.dart';
import '../../../models/problem.dart';

/// Caso de uso para obtener la lista de todos los problemas.
class ObtenerProblemas {
  final ProblemaRepository _repository;
  ObtenerProblemas(this._repository);

  Future<List<Problema>> call(String empresaId) {
    return _repository.obtenerTodosLosProblemas(empresaId);
  }
}
