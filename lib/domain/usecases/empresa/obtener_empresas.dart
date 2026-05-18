import '../../repositories/empresa_repository.dart';
import '../../../models/empresa.dart';

class ObtenerEmpresas {
  final EmpresaRepository _repository;

  ObtenerEmpresas(this._repository);

  Future<List<Empresa>> call() {
    return _repository.obtenerEmpresas();
  }
}
