import '../../repositories/empresa_repository.dart';

class ExisteEmpresa {
  final EmpresaRepository _repository;

  ExisteEmpresa(this._repository);

  Future<bool> call(String id) {
    return _repository.existeEmpresa(id);
  }
}
