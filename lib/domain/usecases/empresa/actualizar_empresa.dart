import '../../repositories/empresa_repository.dart';
import '../../../models/empresa.dart';

/// Caso de uso para guardar o actualizar la información de la empresa.
class ActualizarEmpresa {
  final EmpresaRepository _repository;
  ActualizarEmpresa(this._repository);

  Future<void> call(Empresa empresa) {
    return _repository.actualizarEmpresa(empresa);
  }
}