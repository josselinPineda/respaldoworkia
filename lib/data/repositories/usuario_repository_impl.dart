import 'package:flutter/foundation.dart';
import '../../domain/repositories/usuario_repository.dart';
import '../../models/usuario.dart';

/// Implementación en memoria del repositorio de usuarios.
class UsuarioRepositoryImpl implements UsuarioRepository {
  final List<_UsuarioConClave> _usuarios = [];

  @override
  Future<List<Usuario>> obtenerUsuarios(String empresaId) async {
    return _usuarios
        .map((u) => u.usuario)
        .where((u) => u.idEmpresa == empresaId || u.idEmpresa.isEmpty)
        .toList();
  }

  @override
  Future<void> agregarUsuario(Usuario usuario, String password) async {
    final normalized = usuario.email.trim().toLowerCase();
    final exists = _usuarios.any(
      (u) => u.usuario.email.trim().toLowerCase() == normalized,
    );
    if (exists) {
      throw StateError('email-already-in-use');
    }
    final id = usuario.id.isNotEmpty
        ? usuario.id
        : DateTime.now().millisecondsSinceEpoch.toString();
    final nuevoUsuario = usuario.copyWith(id: id);
    _usuarios.add(_UsuarioConClave(nuevoUsuario, password));
  }

  @override
  Future<void> actualizarUsuario(Usuario usuario) async {
    final index = _usuarios.indexWhere((u) => u.usuario.id == usuario.id);
    if (index != -1) {
      final claveActual = _usuarios[index].password;
      _usuarios[index] = _UsuarioConClave(usuario, claveActual);
    }
  }

  @override
  Future<void> inactivarUsuario(String id, String actualizadoPor) async {
    final index = _usuarios.indexWhere((u) => u.usuario.id == id);
    if (index != -1) {
      final existente = _usuarios[index];
      final usuarioInactivo = existente.usuario.copyWith(
        activo: false,
        actualizadoPor: actualizadoPor,
      );
      _usuarios[index] = _UsuarioConClave(usuarioInactivo, existente.password);
    }
  }

  @override
  Future<Usuario?> login(String email, String password) async {
    try {
      final encontrado = _usuarios.firstWhere(
        (u) => u.usuario.email == email.trim() && u.password == password.trim(),
      );
      return encontrado.usuario;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> emailExistente(String email) async {
    final normalized = email.trim();
    return _usuarios.any((u) => u.usuario.email == normalized);
  }

}

/// Clase interna para asociar un [Usuario] con su contraseña.
class _UsuarioConClave {
  final Usuario usuario;
  final String password;
  _UsuarioConClave(this.usuario, this.password);
}
