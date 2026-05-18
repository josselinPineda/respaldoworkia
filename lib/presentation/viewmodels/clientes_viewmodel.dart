import 'package:flutter/foundation.dart';

import '../../domain/usecases/clientes/obtener_clientes.dart';
import '../../domain/usecases/clientes/agregar_cliente.dart';
import '../../domain/usecases/clientes/actualizar_cliente.dart';
import '../../domain/usecases/clientes/inactivar_cliente.dart';
import '../../domain/usecases/clientes/buscar_clientes.dart';
import '../../models/cliente.dart';

/// ViewModel para gestionar el listado y operaciones sobre clientes.
class ClientesViewModel extends ChangeNotifier {
  final ObtenerClientes _obtenerClientes;
  final AgregarCliente _agregarCliente;
  final ActualizarCliente _actualizarCliente;
  final InactivarCliente _inactivarCliente;
  final BuscarClientes _buscarClientes;

  ClientesViewModel(
    this._obtenerClientes,
    this._agregarCliente,
    this._actualizarCliente,
    this._inactivarCliente,
    this._buscarClientes,
  );

  /// Lista completa de clientes recuperados desde el repositorio.
  ///
  /// Esta lista representa el catálogo actual de clientes activos de la empresa.
  List<Cliente> _clientes = [];

  /// Lista filtrada según la consulta de búsqueda.
  ///
  /// Solo se usa cuando el usuario está buscando clientes, para no alterar
  /// la lista completa original.
  List<Cliente> _filtrados = [];

  /// Indica si el ViewModel está realizando una operación de carga.
  bool _cargando = false;

  /// Indica si el ViewModel está mostrando resultados de búsqueda.
  bool _buscando = false;

  List<Cliente> get clientes => _buscando ? _filtrados : _clientes;
  bool get cargando => _cargando;

  /// Carga la lista completa de clientes para la empresa.
  ///
  /// Además de obtener los clientes, actualiza el estado de carga y
  /// notifica a la interfaz para mostrar indicadores o refrescar la vista.
  Future<void> cargarClientes(String empresaId) async {
    _cargando = true;
    notifyListeners();
    final todos = await _obtenerClientes(empresaId);
    _clientes = todos.where((c) => c.activo).toList();
    _filtrados = [];
    _buscando = false;
    _cargando = false;
    notifyListeners();
  }

  /// Agrega un nuevo cliente y recarga la lista principal.
  ///
  /// Siempre recargamos la lista completa al finalizar para mantener
  /// el estado sincronizado con la base de datos.
  Future<void> agregar(Cliente cliente) async {
    await _agregarCliente(cliente);
    await cargarClientes(cliente.empresaId);
  }

  /// Actualiza un cliente existente y recarga la lista principal.
  Future<void> actualizar(Cliente cliente) async {
    await _actualizarCliente(cliente);
    await cargarClientes(cliente.empresaId);
  }

  /// Inactiva lógicamente un cliente por id y recarga la lista.
  Future<void> eliminar(String id, String empresaId, String userId) async {
    await _inactivarCliente(id, userId);
    await cargarClientes(empresaId);
  }

  /// Filtra la lista de clientes en función de la [consulta].
  ///
  /// Si la consulta está vacía, vuelve a la lista completa. Si hay texto,
  /// usa el caso de uso de búsqueda y actualiza los resultados mostrados.
  Future<void> buscar(String consulta, String empresaId) async {
    if (consulta.trim().isEmpty) {
      _filtrados = [];
      _buscando = false;
    } else {
      _buscando = true;
      _filtrados = await _buscarClientes(consulta, empresaId);
    }
    notifyListeners();
  }

  /// Limpia el estado del ViewModel.
  void limpiar() {
    _clientes = [];
    _filtrados = [];
    _cargando = false;
    _buscando = false;
    notifyListeners();
  }
}
