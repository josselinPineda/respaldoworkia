import 'package:flutter/foundation.dart';
import '../../../../domain/usecases/trabajos/obtener_trabajos.dart';
import '../../../../domain/usecases/trabajos_asignados/obtener_trabajos_asignados.dart';
import '../../../../domain/usecases/gastos/obtener_gastos.dart';
import '../../../../models/job.dart';
import '../../../../models/gasto.dart';

/// ViewModel para la pantalla de Balance.
/// Gestiona el cálculo de ingresos, gastos y balance neto en un rango de fechas.
class BalanceViewModel extends ChangeNotifier {
  final ObtenerTrabajos? _obtenerTrabajos;
  final ObtenerTrabajosAsignados? _obtenerTrabajosAsignados;
  final ObtenerGastos _obtenerGastos;

  BalanceViewModel({
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

  // Datos para gráficos
  Map<DateTime, double> _ingresosPorFecha = {};
  Map<DateTime, double> _gastosPorFecha = {};

  double get ingresos => _ingresos;
  double get gastos => _gastos;
  double get balance => _balance;
  double get margen => _ingresos > 0 ? (_balance / _ingresos) * 100 : 0.0;
  bool get cargando => _cargando;
  List<Trabajo> get trabajosCalculados => _trabajosCalculados;
  List<Gasto> get gastosCalculados => _gastosCalculados;
  DateTime? get fechaInicio => _fechaInicio;
  DateTime? get fechaFin => _fechaFin;
  Map<DateTime, double> get ingresosPorFecha => _ingresosPorFecha;
  Map<DateTime, double> get gastosPorFecha => _gastosPorFecha;

  Future<void> calcular(DateTime inicio, DateTime fin, String empresaId) async {
    _cargando = true;
    _fechaInicio = inicio;
    _fechaFin = fin;
    notifyListeners();

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

      final asignados = await _obtenerTrabajosAsignados(empresaId);
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

    _trabajosCalculados = trabajos;
    _gastosCalculados = gastosList;

    // Cálculo Ingresos
    double totalIngresos = 0.0;
    for (final t in trabajos) {
      final estado = t.estado.trim().toLowerCase();
      final esCompletado = [
        'completo',
        'finalizado',
        'completado',
      ].contains(estado);
      final solapa = !t.fechaFin.isBefore(inicio) && !t.fechaFin.isAfter(fin);

      if (esCompletado && solapa) {
        final monto = t.costo > 0 ? t.costo : 0.0;
        totalIngresos += monto;
      }
    }

    // Cálculo Gastos
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

  void _calcularDatosGraficos(
    List<Trabajo> trabajos,
    List<Gasto> gastos,
    DateTime inicio,
    DateTime fin,
  ) {
    _ingresosPorFecha = {};
    _gastosPorFecha = {};

    for (final t in trabajos) {
      final estado = t.estado.trim().toLowerCase();
      if (['completo', 'finalizado', 'completado'].contains(estado)) {
        final fecha = DateTime(
          t.fechaFin.year,
          t.fechaFin.month,
          t.fechaFin.day,
        );
        if (fecha.isAfter(inicio.subtract(const Duration(days: 1))) &&
            fecha.isBefore(fin.add(const Duration(days: 1)))) {
          final monto = t.costo > 0 ? t.costo : 0.0;
          _ingresosPorFecha[fecha] = (_ingresosPorFecha[fecha] ?? 0) + monto;
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
      }
    }
  }

  Map<String, dynamic> obtenerDatosParaExportar() {
    final trabajosCompletados = _trabajosCalculados.where((t) {
      final estado = t.estado.toLowerCase();
      return ['completo', 'finalizado', 'completado'].contains(estado);
    }).toList();

    return {
      'resumen': {
        'ingresos': _ingresos,
        'gastos': _gastos,
        'balance': _balance,
      },
      'trabajos': trabajosCompletados,
      'trabajosTodos': _trabajosCalculados,
      'gastos': _gastosCalculados,
      'periodo': {'inicio': _fechaInicio, 'fin': _fechaFin},
    };
  }
}
