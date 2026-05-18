import '../../repositories/usuario_repository.dart';
import '../../../models/usuario.dart';

/// Caso de uso para obtener todos los usuarios registrados.
class ObtenerUsuarios {
  final UsuarioRepository _repository;
  ObtenerUsuarios(this._repository);

  Future<List<Usuario>> call(String empresaId) {
    return _repository.obtenerUsuarios(empresaId);
  }
}
