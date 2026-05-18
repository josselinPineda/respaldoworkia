import '../../models/gasto.dart';
import '../../models/tipo_gasto.dart';

/// Contrato para gestionar gastos.
abstract class GastoRepository {
  Future<List<Gasto>> obtenerGastos(String empresaId);
  Future<void> agregarGasto(Gasto gasto);
  Future<void> actualizarGasto(Gasto gasto);
  Future<void> eliminarGasto(String id, String actualizadoPor);
  Future<List<Gasto>> gastosPorTipo(String tipoId, String empresaId);
  Future<List<Gasto>> gastosPorRango(
    DateTime inicio,
    DateTime fin,
    String empresaId,
  );

  /// Devuelve la lista de tipos de gasto disponibles para una empresa.
  Future<List<TipoGasto>> obtenerTipos(String empresaId);

  /// Agrega un nuevo tipo de gasto.
  Future<void> agregarTipoGasto(TipoGasto tipo);

  /// Actualiza un tipo de gasto existente.
  Future<void> actualizarTipoGasto(TipoGasto tipo);

  /// Elimina (o desactiva) un tipo de gasto.
  Future<void> eliminarTipoGasto(String id);
}
