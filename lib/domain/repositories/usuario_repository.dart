import '../../models/usuario.dart';

/// Contrato para gestionar usuarios y autenticación.
abstract class UsuarioRepository {
  Future<List<Usuario>> obtenerUsuarios(String empresaId);
  Future<void> agregarUsuario(Usuario usuario, String password);
  Future<void> actualizarUsuario(Usuario usuario);
  Future<void> inactivarUsuario(String id, String actualizadoPor);
  Future<Usuario?> login(String email, String password);
  Future<bool> emailExistente(String email);
}
