import 'package:flutter/foundation.dart';

import '../../domain/usecases/usuarios/obtener_usuarios.dart';
import '../../domain/usecases/usuarios/agregar_usuario.dart';
import '../../domain/usecases/usuarios/actualizar_usuario.dart';
import '../../domain/usecases/usuarios/inactivar_usuario.dart';
import '../../domain/usecases/usuarios/login_usuario.dart';
import '../../domain/usecases/usuarios/email_existente.dart';
import '../../models/usuario.dart';

/// ViewModel para gestionar cuentas de usuarios y autenticación.
class UsuariosViewModel extends ChangeNotifier {
  final ObtenerUsuarios _obtenerUsuarios;
  final AgregarUsuario _agregarUsuario;
  final ActualizarUsuario _actualizarUsuario;
  final InactivarUsuario _inactivarUsuario;
  final LoginUsuario _loginUsuario;
  final EmailExistente _emailExistente;

  UsuariosViewModel(
    this._obtenerUsuarios,
    this._agregarUsuario,
    this._actualizarUsuario,
    this._inactivarUsuario,
    this._loginUsuario,
    this._emailExistente,
  );

  List<Usuario> _usuarios = [];
  bool _cargando = false;

  List<Usuario> get usuarios => _usuarios;
  bool get cargando => _cargando;

  Future<void> cargarUsuarios(String empresaId) async {
    _cargando = true;
    notifyListeners();
    final todos = await _obtenerUsuarios(empresaId);
    _usuarios = todos.where((u) => u.activo).toList();
    _cargando = false;
    notifyListeners();
  }

  Future<void> agregar(Usuario usuario, String password) async {
    await _agregarUsuario(usuario, password);
    await cargarUsuarios(usuario.idEmpresa);
  }

  Future<void> actualizar(Usuario usuario) async {
    await _actualizarUsuario(usuario);
    await cargarUsuarios(usuario.idEmpresa);
  }

  Future<void> inactivar(String id, String empresaId, String userId) async {
    await _inactivarUsuario(id, userId);
    await cargarUsuarios(empresaId);
  }

  Future<Usuario?> login(String email, String password) {
    return _loginUsuario(email, password);
  }

  Future<bool> emailExistente(String email) {
    return _emailExistente(email);
  }

  Future<void> actualizarIdioma(String userId, String nuevoIdioma) async {
    try {
      // Buscar el usuario en la lista local
      final index = _usuarios.indexWhere((u) => u.id == userId);
      if (index != -1) {
        // Crear copia con el nuevo idioma
        final usuario = _usuarios[index].copyWith(idioma: nuevoIdioma);
        // Actualizar en backend
        await actualizar(usuario);
      }
    } catch (e) {}
  }

  /// Limpia el estado del ViewModel.
  void limpiar() {
    _usuarios = [];
    _cargando = false;
    notifyListeners();
  }
}
