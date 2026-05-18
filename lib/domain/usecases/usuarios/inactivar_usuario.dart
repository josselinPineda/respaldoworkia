import '../../repositories/usuario_repository.dart';

/// Caso de uso para inactivar lógicamente un usuario.
class InactivarUsuario {
  final UsuarioRepository _repository;
  InactivarUsuario(this._repository);

  Future<void> call(String id, String actualizadoPor) {
    return _repository.inactivarUsuario(id, actualizadoPor);
  }
}
