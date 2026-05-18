import '../../repositories/usuario_repository.dart';
import '../../../models/usuario.dart';

/// Caso de uso para actualizar un usuario existente.
class ActualizarUsuario {
  final UsuarioRepository _repository;
  ActualizarUsuario(this._repository);

  Future<void> call(Usuario usuario) {
    return _repository.actualizarUsuario(usuario);
  }
}