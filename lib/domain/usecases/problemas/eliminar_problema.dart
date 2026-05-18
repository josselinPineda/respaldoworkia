import '../../repositories/problema_repository.dart';

class EliminarProblema {
  final ProblemaRepository _repository;

  EliminarProblema(this._repository);

  Future<void> call(String id, String actualizadoPor) async {
    return _repository.eliminarProblema(id, actualizadoPor);
  }
}
