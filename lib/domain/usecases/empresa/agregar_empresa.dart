import '../../repositories/empresa_repository.dart';
import '../../../models/empresa.dart';

class AgregarEmpresa {
  final EmpresaRepository _repository;

  AgregarEmpresa(this._repository);

  Future<String> call(Empresa empresa) {
    return _repository.agregarEmpresa(empresa);
  }
}
