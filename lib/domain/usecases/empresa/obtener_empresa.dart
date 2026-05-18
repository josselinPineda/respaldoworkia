import '../../repositories/empresa_repository.dart';
import '../../../models/empresa.dart';

/// Caso de uso para obtener la información de la empresa.
class ObtenerEmpresa {
  final EmpresaRepository _repository;
  ObtenerEmpresa(this._repository);

  Future<Empresa?> call(String id) {
    return _repository.obtenerEmpresa(id);
  }
}
