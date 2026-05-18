import '../../repositories/usuario_repository.dart';

/// Caso de uso para verificar si un correo ya está registrado.
class EmailExistente {
  final UsuarioRepository _repository;
  EmailExistente(this._repository);

  Future<bool> call(String email) {
    return _repository.emailExistente(email);
  }
}