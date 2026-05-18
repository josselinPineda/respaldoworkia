import '../../domain/repositories/gasto_repository.dart';
import '../../models/gasto.dart';
import '../../models/tipo_gasto.dart';

/// Implementación en memoria del repositorio de gastos.
class GastoRepositoryImpl implements GastoRepository {
  final List<Gasto> _gastos = [];
  final List<TipoGasto> _tipos = [
    const TipoGasto(
      id: 'TG001',
      codigo: 'TG001',
      nombre: 'Materiales',
      descripcion: 'Compras de repuestos, filtros, y materiales varios',
    ),
    const TipoGasto(
      id: 'TG002',
      codigo: 'TG002',
      nombre: 'Combustible',
      descripcion: 'Transporte, gasolina, mantenimiento de vehículos',
    ),
    const TipoGasto(
      id: 'TG003',
      codigo: 'TG003',
      nombre: 'Salarios',
      descripcion: 'Pagos a técnicos o personal operativo',
    ),
    const TipoGasto(
      id: 'TG004',
      codigo: 'TG004',
      nombre: 'Oficina',
      descripcion: 'Papelería, servicios, suministros de oficina',
    ),
  ];

  String _generarId() => DateTime.now().millisecondsSinceEpoch.toString();

  @override
  Future<List<Gasto>> obtenerGastos(String empresaId) async {
    return List.unmodifiable(_gastos.where((g) => g.empresaId == empresaId));
  }

  @override
  Future<void> agregarGasto(Gasto gasto) async {
    final nuevo = gasto.id.isEmpty
        ? Gasto(
            id: _generarId(),
            fechaGasto: gasto.fechaGasto,
            monto: gasto.monto,
            empresaId: gasto.empresaId,
            activo: gasto.activo,
            urlComprobante: gasto.urlComprobante,
            creadoPor: gasto.creadoPor,
            idTipoGasto: gasto.idTipoGasto,
            actualizadoPor: gasto.actualizadoPor,
          )
        : gasto;
    _gastos.add(nuevo);
  }

  @override
  Future<void> actualizarGasto(Gasto actualizado) async {
    final index = _gastos.indexWhere((e) => e.id == actualizado.id);
    if (index != -1) {
      _gastos[index] = actualizado;
    }
  }

  @override
  Future<void> eliminarGasto(String id, String actualizadoPor) async {
    final index = _gastos.indexWhere((e) => e.id == id);
    if (index != -1) {
      _gastos[index] = _gastos[index].copyWith(
        activo: false,
        actualizadoPor: actualizadoPor,
        fechaActualizacion: DateTime.now(),
      );
    }
  }

  @override
  Future<List<Gasto>> gastosPorTipo(String tipoId, String empresaId) async {
    return _gastos
        .where((e) => e.idTipoGasto == tipoId && e.empresaId == empresaId)
        .toList();
  }

  @override
  Future<List<Gasto>> gastosPorRango(
    DateTime inicio,
    DateTime fin,
    String empresaId,
  ) async {
    return _gastos
        .where(
          (e) =>
              e.empresaId == empresaId &&
              e.fechaGasto.isAfter(
                inicio.subtract(const Duration(seconds: 1)),
              ) &&
              e.fechaGasto.isBefore(fin.add(const Duration(seconds: 1))),
        )
        .toList();
  }

  @override
  Future<List<TipoGasto>> obtenerTipos(String empresaId) async {
    return List.unmodifiable(
      _tipos.where((t) => t.empresaId.isEmpty || t.empresaId == empresaId),
    );
  }

  @override
  Future<void> agregarTipoGasto(TipoGasto tipo) async {
    _tipos.add(tipo);
  }

  @override
  Future<void> actualizarTipoGasto(TipoGasto tipo) async {
    final index = _tipos.indexWhere((t) => t.id == tipo.id);
    if (index != -1) {
      _tipos[index] = tipo;
    }
  }

  @override
  Future<void> eliminarTipoGasto(String id) async {
    _tipos.removeWhere((t) => t.id == id);
  }
}
