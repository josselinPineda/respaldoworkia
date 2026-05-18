import '../../repositories/usuario_repository.dart';
import '../../../models/usuario.dart';

/// Caso de uso para autenticar a un usuario.
class LoginUsuario {
  final UsuarioRepository _repository;
  LoginUsuario(this._repository);

  Future<Usuario?> call(String email, String password) {
    return _repository.login(email, password);
  }
}