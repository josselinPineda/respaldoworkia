import '../../repositories/usuario_repository.dart';
import '../../../models/usuario.dart';

/// Caso de uso para registrar un nuevo usuario con su contraseña.
class AgregarUsuario {
  final UsuarioRepository _repository;
  AgregarUsuario(this._repository);

  Future<void> call(Usuario usuario, String password) {
    return _repository.agregarUsuario(usuario, password);
  }
}