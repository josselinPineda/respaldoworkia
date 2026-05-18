import 'package:flutter/foundation.dart';

import '../../domain/usecases/trabajos/obtener_trabajos.dart';
import '../../domain/usecases/trabajos/agregar_trabajo.dart';
import '../../domain/usecases/trabajos/actualizar_trabajo.dart';
import '../../domain/usecases/trabajos/cancelar_trabajo.dart';
import '../../domain/usecases/trabajos/buscar_trabajos.dart';
import '../../models/job.dart';
import '../../features/activities/domain/entities/actividad.dart';

/// ViewModel para gestionar operaciones sobre trabajos.
class TrabajosViewModel extends ChangeNotifier {
  final ObtenerTrabajos _obtenerTrabajos;
  final AgregarTrabajo _agregarTrabajo;
  final ActualizarTrabajo _actualizarTrabajo;
  final CancelarTrabajo _cancelarTrabajo;
  final BuscarTrabajos _buscarTrabajos;

  // Mapa para almacenar las actividades asociadas a cada trabajo en
  // memoria. La clave es el ID del trabajo y el valor es una lista de
  // actividades registradas. No se persiste automáticamente; se usa para
  // mostrar datos en la UI y calcular totales de cada trabajo.
  final Map<String, List<Actividad>> _actividadesPorTrabajo = {};

  /// Mapa público de actividades por trabajo.
  ///
  /// Permite leer las actividades ya cargadas para cada trabajo sin tener
  /// que volver a consultarlas desde el repositorio. Se hace así para
  /// optimizar la interfaz y evitar recargas innecesarias.
  Map<String, List<Actividad>> get actividadesPorTrabajo =>
      _actividadesPorTrabajo;

  TrabajosViewModel(
    this._obtenerTrabajos,
    this._agregarTrabajo,
    this._actualizarTrabajo,
    this._cancelarTrabajo,
    this._buscarTrabajos,
  );

  /// Lista completa de trabajos activos cargados desde el repositorio.
  List<Trabajo> _trabajos = [];

  /// Resultados filtrados cuando el usuario busca por texto.
  List<Trabajo> _filtrados = [];

  /// Indicador de carga de datos.
  bool _cargando = false;

  /// Indica si el ViewModel está mostrando resultados de búsqueda.
  bool _buscando = false;

  /// Consulta de búsqueda más reciente usada para evitar resultados obsoletos.
  String _lastQuery = '';

  List<Trabajo> get trabajos => _buscando ? _filtrados : _trabajos;
  bool get cargando => _cargando;

  /// Carga todos los trabajos activos para la empresa.
  ///
  /// Mientras dura la carga se activa el indicador de progreso y al terminar
  /// se notifica a la UI para que se actualice la lista mostrada.
  Future<void> cargarTrabajos(String empresaId) async {
    _cargando = true;
    notifyListeners();
    final todos = await _obtenerTrabajos(empresaId);
    _trabajos = todos.where((t) => t.activo).toList();
    _filtrados = [];
    _buscando = false;
    _cargando = false;
    notifyListeners();
  }

  Future<void> agregar(Trabajo trabajo) async {
    await _agregarTrabajo(trabajo);
    await cargarTrabajos(trabajo.empresaId);
  }

  Future<void> actualizar(Trabajo trabajo) async {
    await _actualizarTrabajo(trabajo);
    await cargarTrabajos(trabajo.empresaId);
  }

  Future<void> cancelar(String id, String empresaId, String userId) async {
    await _cancelarTrabajo(id, userId);
    await cargarTrabajos(empresaId);
  }

  /// Busca trabajos según el texto ingresado por el usuario.
  ///
  /// Si la consulta está vacía, restaura la lista completa. Si hay texto,
  /// realiza la búsqueda en el repositorio y solo actualiza los resultados
  /// cuando la consulta actual sigue siendo la última solicitada.
  Future<void> buscar(String query, String empresaId) async {
    _lastQuery = query;
    if (query.trim().isEmpty) {
      _filtrados = [];
      _buscando = false;
      notifyListeners();
    } else {
      _buscando = true;
      // No notificamos aquí para evitar parpadeos, esperamos al resultado
      final resultados = await _buscarTrabajos(query, empresaId);
      // Solo actualizamos si la consulta sigue siendo la última realizada
      if (_lastQuery == query) {
        _filtrados = resultados;
        notifyListeners();
      }
    }
  }

  /// Agrega una actividad a la lista de un trabajo y notifica a los
  /// escuchas. Si no hay una lista previa se crea una nueva.
  ///
  /// Esta lista es solo de memoria y se usa para mostrar actividades
  /// asociadas a un trabajo sin necesidad de recargar toda la colección.
  void agregarActividad(String trabajoId, Actividad actividad) {
    final lista = _actividadesPorTrabajo.putIfAbsent(trabajoId, () => []);
    lista.add(actividad);
    notifyListeners();
  }

  /// Limpia el estado del ViewModel.
  void limpiar() {
    _trabajos = [];
    _filtrados = [];
    _cargando = false;
    _buscando = false;
    _lastQuery = '';
    _actividadesPorTrabajo.clear();
    notifyListeners();
  }
}
