import 'package:flutter/foundation.dart';

import '../../domain/usecases/trabajos/obtener_trabajos.dart';
import '../../domain/usecases/trabajos_asignados/obtener_trabajos_asignados.dart';
import '../../domain/usecases/gastos/obtener_gastos.dart';
import '../../models/job.dart';
import '../../models/gasto.dart';

/// ViewModel para calcular reportes financieros (ingresos, gastos y balance).
///
/// Esta clase utiliza los casos de uso [ObtenerTrabajos] y
/// [ObtenerGastos] para recuperar los datos de trabajos y gastos.  A
/// partir de estos datos se calculan los totales de ingresos
/// (basados en los trabajos completados), los gastos y el balance neto
/// para un rango de fechas determinado.  Los resultados se exponen
/// mediante getters reactivos que notifican a los oyentes cuando
/// cambian.
class ReportesViewModel extends ChangeNotifier {
  final ObtenerTrabajos? _obtenerTrabajos;
  final ObtenerTrabajosAsignados? _obtenerTrabajosAsignados;
  final ObtenerGastos _obtenerGastos;

  /// Crea una instancia del viewmodel de reportes.  Se pueden pasar
  /// opcionalmente los casos de uso para obtener trabajos del catálogo
  /// y trabajos asignados.  Se requiere siempre el caso de uso para
  /// obtener gastos.  Usamos parámetros con nombre para evitar
  /// confusiones y asegurar que los valores se asignan al campo
  /// correcto.  Si [obtenerTrabajosAsignados] es distinto de null se
  /// utilizarán las asignaciones para calcular los ingresos; de lo
  /// contrario, se utilizan los trabajos del catálogo.
  ReportesViewModel({
    ObtenerTrabajos? obtenerTrabajos,
    required ObtenerGastos obtenerGastos,
    ObtenerTrabajosAsignados? obtenerTrabajosAsignados,
  }) : _obtenerTrabajos = obtenerTrabajos,
       _obtenerTrabajosAsignados = obtenerTrabajosAsignados,
       _obtenerGastos = obtenerGastos;

  double _ingresos = 0.0;
  double _gastos = 0.0;
  double _balance = 0.0;
  bool _cargando = false;

  // Datos detallados para exportación
  List<Trabajo> _trabajosCalculados = [];
  List<Gasto> _gastosCalculados = [];
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  double get ingresos => _ingresos;
  double get gastos => _gastos;
  double get balance => _balance;
  double get margen => _ingresos > 0 ? (_balance / _ingresos) * 100 : 0.0;
  bool get cargando => _cargando;
  List<Trabajo> get trabajosCalculados => _trabajosCalculados;
  List<Gasto> get gastosCalculados => _gastosCalculados;
  DateTime? get fechaInicio => _fechaInicio;
  DateTime? get fechaFin => _fechaFin;

  /// Calcula los ingresos, gastos y balance para el rango
  /// comprendido entre [inicio] y [fin] (incluyendo ambas fechas).  Un
  /// trabajo aporta su campo [Trabajo.costo] a los ingresos si su
  /// estado es 'Completo' y si sus fechas de inicio y fin se solapan
  /// con el rango dado.  Los gastos se suman según su fecha de
  /// registro.  Tras el cálculo se notifican los cambios.
  Future<void> calcular(DateTime inicio, DateTime fin, String empresaId) async {
    _cargando = true;
    _fechaInicio = inicio;
    _fechaFin = fin;
    notifyListeners();
    // Si el cálculo se basa en trabajos asignados, obtenerlos.  De lo
    // contrario, obtener los trabajos del catálogo.  Esto permite
    // transicionar del esquema antiguo (estado en trabajos) al nuevo
    // (estado en trabajos asignados) sin romper compatibilidad.
    List<Trabajo> trabajos = [];
    if (_obtenerTrabajosAsignados != null) {
      final Map<String, String> tituloCatalogoPorId;
      if (_obtenerTrabajos != null) {
        final catalogo = await _obtenerTrabajos(empresaId);
        tituloCatalogoPorId = {
          for (final t in catalogo) t.id: t.titulo,
        };
      } else {
        tituloCatalogoPorId = const {};
      }

      // Convertir asignaciones a trabajos para reutilizar la lógica de
      // solapamiento de fechas.  El estado y el precio se toman de
      // las asignaciones; el costo de catálogo se ignora.
      final asignados = await _obtenerTrabajosAsignados(empresaId);
      // Para convertir las asignaciones necesitamos acceso al
      // catálogo; en este ViewModel no se dispone del catálogo, por
      // lo que sólo rellenamos los campos esenciales para el cálculo.
      trabajos = asignados
          .map(
            (a) => Trabajo(
              id: a.id.isNotEmpty ? a.id : a.trabajoId,
              titulo: a.tituloTrabajo.trim().isNotEmpty
                  ? a.tituloTrabajo
                  : (tituloCatalogoPorId[a.trabajoId] ?? a.trabajoId),
              cliente: '',
              clienteId: a.clienteId,
              fechaInicio: a.fechaInicio,
              fechaFin: a.fechaFin,
              // Normalizamos el estado reemplazando guiones bajos por espacios
              estado: a.estado.replaceAll('_', ' '),
              descripcion: '',
              costo: a.precioFinal,
              esCiclico: a.esCiclico,
              frecuenciaCiclico: a.frecuenciaCiclico,
              proximaFecha: a.proximaFecha,
              empleadosAsignados: a.tecnicosAsignados,
              clientesAsignados: const [],
              empresaId: a.empresaId,
            ),
          )
          .toList();
    } else if (_obtenerTrabajos != null) {
      trabajos = await _obtenerTrabajos(empresaId);
    }
    final List<Gasto> gastosList = await _obtenerGastos(empresaId);

    // Guardar listas completas para exportación
    _trabajosCalculados = trabajos;
    _gastosCalculados = gastosList;

    // --- CÁLCULO DE INGRESOS ---
    double totalIngresos = 0.0;

    for (final t in trabajos) {
      // Normalización para comparación
      final estadoNormalizado = t.estado.trim().toLowerCase();
      final esCompletado = [
        'completo',
        'finalizado',
        'completado',
      ].contains(estadoNormalizado);

      // Verificación de fecha (solapamiento)
      final solapa = !t.fechaFin.isBefore(inicio) && !t.fechaFin.isAfter(fin);

      if (esCompletado && solapa) {
        // Usar precioFinal si está disponible en el objeto original (aquí 'costo' ya viene mapeado)
        // Asegurar que sea positivo
        final monto = t.costo > 0 ? t.costo : 0.0;
        totalIngresos += monto;
      }
    }

    // --- CÁLCULO DE GASTOS ---
    double totalGastos = 0.0;

    for (final g in gastosList) {
      final dentro =
          !g.fechaGasto.isBefore(inicio) && !g.fechaGasto.isAfter(fin);

      if (dentro) {
        totalGastos += g.monto;
      }
    }

    _ingresos = totalIngresos;
    _gastos = totalGastos;
    _balance = totalIngresos - totalGastos;
    _calcularDatosGraficos(trabajos, gastosList, inicio, fin);
    _cargando = false;
    notifyListeners();
  }

  // Datos para gráficos
  Map<DateTime, double> _ingresosPorFecha = {};
  Map<DateTime, double> _gastosPorFecha = {};
  Map<String, double> _ingresosPorTecnico = {};
  Map<String, double> _gastosPorTipo = {};
  Map<String, double> _ingresosPorCliente = {};
  Map<String, int> _trabajosFrecuentes = {};

  Map<DateTime, double> get ingresosPorFecha => _ingresosPorFecha;
  Map<DateTime, double> get gastosPorFecha => _gastosPorFecha;
  Map<String, double> get ingresosPorTecnico => _ingresosPorTecnico;
  Map<String, double> get gastosPorTipo => _gastosPorTipo;
  Map<String, double> get ingresosPorCliente => _ingresosPorCliente;
  Map<String, int> get trabajosFrecuentes => _trabajosFrecuentes;

  /// Obtiene todos los datos calculados en formato estructurado para exportación.
  ///
  /// Retorna un mapa con:
  /// - resumen: ingresos, gastos y balance totales
  /// - trabajos: lista de trabajos completados en el período
  /// - gastos: lista de gastos en el período
  /// - periodo: fechas de inicio y fin
  Map<String, dynamic> obtenerDatosParaExportar() {
    final inicio = _fechaInicio;
    final fin = _fechaFin;

    bool dentroRango(DateTime d) {
      if (inicio == null || fin == null) return true;
      return !d.isBefore(inicio) && !d.isAfter(fin);
    }

    final trabajosCompletados = _trabajosCalculados.where((t) {
      final estado = t.estado.toLowerCase();
      final esCompletado =
          estado == 'completo' || estado == 'finalizado' || estado == 'completado';
      return esCompletado && dentroRango(t.fechaFin);
    }).toList();

    final gastosEnRango = _gastosCalculados.where((g) {
      return dentroRango(g.fechaGasto);
    }).toList();

    return {
      'resumen': {
        'ingresos': _ingresos,
        'gastos': _gastos,
        'balance': _balance,
      },
      'trabajos': trabajosCompletados,
      'trabajosTodos': _trabajosCalculados,
      'gastos': gastosEnRango,
      'periodo': {'inicio': _fechaInicio, 'fin': _fechaFin},
    };
  }

  void _calcularDatosGraficos(
    List<Trabajo> trabajos,
    List<Gasto> gastos,
    DateTime inicio,
    DateTime fin,
  ) {
    _ingresosPorFecha = {};
    _gastosPorFecha = {};
    _ingresosPorTecnico = {};
    _gastosPorTipo = {};
    _ingresosPorCliente = {};
    _trabajosFrecuentes = {};

    for (final t in trabajos) {
      final estado = t.estado.trim().toLowerCase();
      if (estado == 'completo' ||
          estado == 'finalizado' ||
          estado == 'completado') {
        // Usamos fechaFin como fecha de ingreso
        final fecha = DateTime(
          t.fechaFin.year,
          t.fechaFin.month,
          t.fechaFin.day,
        );
        if (fecha.isAfter(inicio.subtract(const Duration(days: 1))) &&
            fecha.isBefore(fin.add(const Duration(days: 1)))) {
          final monto = t.costo > 0 ? t.costo : 0.0;
          _ingresosPorFecha[fecha] = (_ingresosPorFecha[fecha] ?? 0) + monto;
          
          if (t.empleadosAsignados.isNotEmpty) {
            final montoPorTecnico = monto / t.empleadosAsignados.length;
            for (final techId in t.empleadosAsignados) {
              _ingresosPorTecnico[techId] = (_ingresosPorTecnico[techId] ?? 0) + montoPorTecnico;
            }
          } else {
            _ingresosPorTecnico['Sin Asignar'] = (_ingresosPorTecnico['Sin Asignar'] ?? 0) + monto;
          }
          
          final clienteId = t.clienteId.isNotEmpty ? t.clienteId : 'Sin Cliente';
          _ingresosPorCliente[clienteId] = (_ingresosPorCliente[clienteId] ?? 0) + monto;
          
          final titulo = t.titulo.isNotEmpty ? t.titulo : 'Sin Título';
          _trabajosFrecuentes[titulo] = (_trabajosFrecuentes[titulo] ?? 0) + 1;
        }
      }
    }

    for (final g in gastos) {
      final fecha = DateTime(
        g.fechaGasto.year,
        g.fechaGasto.month,
        g.fechaGasto.day,
      );
      if (fecha.isAfter(inicio.subtract(const Duration(days: 1))) &&
          fecha.isBefore(fin.add(const Duration(days: 1)))) {
        _gastosPorFecha[fecha] = (_gastosPorFecha[fecha] ?? 0) + g.monto;
        
        final tipoId = g.idTipoGasto.isNotEmpty ? g.idTipoGasto : 'Sin Clasificar';
        _gastosPorTipo[tipoId] = (_gastosPorTipo[tipoId] ?? 0) + g.monto;
      }
    }
  }
}
