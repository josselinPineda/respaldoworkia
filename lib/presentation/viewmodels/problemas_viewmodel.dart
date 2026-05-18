import 'package:flutter/foundation.dart';

import '../../domain/usecases/problemas/obtener_problemas.dart';
import '../../domain/usecases/problemas/agregar_problema.dart';
import '../../domain/usecases/problemas/ignorar_problema.dart';
import '../../domain/usecases/problemas/resolver_problema.dart';
import '../../domain/usecases/problemas/actualizar_problema.dart';
import '../../domain/usecases/problemas/eliminar_problema.dart';
import '../../models/problem.dart';

/// ViewModel para gestionar problemas reportados por técnicos.
class ProblemasViewModel extends ChangeNotifier {
  final ObtenerProblemas _obtenerProblemas;
  final AgregarProblema _agregarProblema;
  final IgnorarProblema _ignorarProblema;
  final ResolverProblema _resolverProblema;
  final ActualizarProblema _actualizarProblema;
  final EliminarProblema _eliminarProblema;

  ProblemasViewModel(
    this._obtenerProblemas,
    this._agregarProblema,
    this._ignorarProblema,
    this._resolverProblema,
    this._actualizarProblema,
    this._eliminarProblema,
  );

  List<Problema> _problemas = [];
  bool _cargando = false;

  List<Problema> get problemas => _problemas;
  bool get cargando => _cargando;

  Future<void> cargarProblemas(String empresaId) async {
    _cargando = true;
    notifyListeners();
    final todos = await _obtenerProblemas(empresaId);
    _problemas = todos.where((p) => p.activo).toList();
    _cargando = false;
    notifyListeners();
  }

  Future<void> agregar(Problema problema) async {
    try {
      _cargando = true;
      notifyListeners();
      await _agregarProblema(problema);
      if (problema.empresaId.isNotEmpty) {
        await cargarProblemas(problema.empresaId);
      }
      _cargando = false;
      notifyListeners();
    } catch (e) {
      _cargando = false;
      notifyListeners();
      print('Error FATAL al guardar problema: $e');
      rethrow;
    }
  }

  Future<void> actualizar(Problema problema) async {
    await _actualizarProblema(problema);
    if (problema.empresaId.isNotEmpty) {
      await cargarProblemas(problema.empresaId);
    }
  }

  Future<void> ignorar(String id, String empresaId, String userName) async {
    await _ignorarProblema(id, empresaId, userName);
    await cargarProblemas(empresaId);
  }

  Future<void> resolver(
    String id,
    String empresaId,
    String userId,
    String userRole,
  ) async {
    await _resolverProblema(id, empresaId, userId, userRole);
    await cargarProblemas(empresaId);
  }

  void limpiar() {
    _problemas = [];
    _cargando = false;
    notifyListeners();
  }

  Future<void> eliminarProblema(
    String id,
    String empresaId,
    String userId,
  ) async {
    _cargando = true;
    notifyListeners();
    try {
      await _eliminarProblema(id, userId);
      await cargarProblemas(empresaId);
    } catch (e) {
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
