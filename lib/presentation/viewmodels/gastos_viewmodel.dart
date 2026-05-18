import 'package:flutter/foundation.dart';

import '../../domain/usecases/gastos/obtener_gastos.dart';
import '../../domain/usecases/gastos/agregar_gasto.dart';
import '../../domain/usecases/gastos/actualizar_gasto.dart';
import '../../domain/usecases/gastos/eliminar_gasto.dart';
import '../../domain/usecases/gastos/gastos_por_tipo.dart';
import '../../domain/usecases/gastos/gastos_por_rango.dart';
import '../../domain/usecases/gastos/obtener_tipos_gasto.dart';
import '../../domain/usecases/gastos/agregar_tipo_gasto.dart';
import '../../domain/usecases/gastos/actualizar_tipo_gasto.dart';
import '../../domain/usecases/gastos/eliminar_tipo_gasto.dart';
import '../../models/gasto.dart';
import '../../models/tipo_gasto.dart';

/// ViewModel para gestionar la lista y operaciones de gastos.
class GastosViewModel extends ChangeNotifier {
  final ObtenerGastos _obtenerGastos;
  final AgregarGasto _agregarGasto;
  final ActualizarGasto _actualizarGasto;
  final EliminarGasto _eliminarGasto;
  final GastosPorTipo _gastosPorTipo;
  final GastosPorRango _gastosPorRango;

  // Caso de uso adicional para gestionar tipos de gasto.
  final ObtenerTiposGasto? _obtenerTiposGasto;
  final AgregarTipoGasto? _agregarTipoGasto;
  final ActualizarTipoGasto? _actualizarTipoGasto;
  final EliminarTipoGasto? _eliminarTipoGasto;

  /// Constructor.
  GastosViewModel(
    this._obtenerGastos,
    this._agregarGasto,
    this._actualizarGasto,
    this._eliminarGasto,
    this._gastosPorTipo,
    this._gastosPorRango, {
    ObtenerTiposGasto? obtenerTiposGasto,
    AgregarTipoGasto? agregarTipoGasto,
    ActualizarTipoGasto? actualizarTipoGasto,
    EliminarTipoGasto? eliminarTipoGasto,
  })  : _obtenerTiposGasto = obtenerTiposGasto,
        _agregarTipoGasto = agregarTipoGasto,
        _actualizarTipoGasto = actualizarTipoGasto,
        _eliminarTipoGasto = eliminarTipoGasto;

  List<Gasto> _gastos = [];
  bool _cargando = false;
  String? _lastEmpresaId;

  // Lista de tipos de gastos.
  List<TipoGasto> _tipos = [];

  List<Gasto> get gastos => _gastos;
  bool get cargando => _cargando;

  List<TipoGasto> get tipos => _tipos;

  Future<void> cargarGastos(String empresaId) async {
    _cargando = true;
    notifyListeners();
    final todos = await _obtenerGastos(empresaId);
    _gastos = todos.where((g) => g.activo).toList();
    _cargando = false;
    notifyListeners();
  }

  /// Carga la lista de tipos de gasto disponibles.  Si no se
  /// proporcionó el caso de uso correspondiente, la lista
  /// permanecerá vacía.
  Future<void> cargarTipos(String empresaId) async {
    _lastEmpresaId = empresaId;
    if (_obtenerTiposGasto != null) {
      _cargando = true;
      notifyListeners();
      try {
        _tipos = await _obtenerTiposGasto(empresaId);
      } finally {
        _cargando = false;
        notifyListeners();
      }
    }
  }

  Future<void> agregarTipo(TipoGasto tipo) async {
    if (_agregarTipoGasto != null) {
      await _agregarTipoGasto(tipo);
      if (tipo.empresaId.isNotEmpty) {
        await cargarTipos(tipo.empresaId);
      }
    }
  }

  Future<void> actualizarTipo(TipoGasto tipo) async {
    if (_actualizarTipoGasto != null) {
      await _actualizarTipoGasto(tipo);
      if (tipo.empresaId.isNotEmpty) {
        await cargarTipos(tipo.empresaId);
      }
    }
  }

  Future<void> eliminarTipo(String id) async {
    if (_eliminarTipoGasto != null) {
      await _eliminarTipoGasto(id);
      if (_lastEmpresaId != null) {
        await cargarTipos(_lastEmpresaId!);
      }
    }
  }

  Future<void> agregar(Gasto gasto) async {
    await _agregarGasto(gasto);
    await cargarGastos(gasto.empresaId);
  }

  Future<void> actualizar(Gasto gasto) async {
    await _actualizarGasto(gasto);
    await cargarGastos(gasto.empresaId);
  }

  Future<void> eliminar(
    String id,
    String empresaId,
    String actualizadoPor,
  ) async {
    // Usamos el caso de uso de eliminar, que ya implementa el borrado lógico
    // en el repositorio.
    try {
      await _eliminarGasto(id, actualizadoPor);
      await cargarGastos(empresaId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Gasto>> obtenerPorTipo(String tipoId, String empresaId) {
    return _gastosPorTipo(tipoId, empresaId);
  }

  Future<List<Gasto>> obtenerPorRango(
    DateTime inicio,
    DateTime fin,
    String empresaId,
  ) {
    return _gastosPorRango(inicio, fin, empresaId);
  }

  /// Limpia el estado del ViewModel.
  void limpiar() {
    _gastos = [];
    _cargando = false;
    // No limpiamos _tipos porque suelen ser globales o estáticos,
    // pero si fueran por empresa, deberían limpiarse también.
    // Asumimos que los tipos pueden ser recargados si es necesario.
    notifyListeners();
  }
}
