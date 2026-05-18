// Corregimos la ruta para importar el modelo desde la raíz de lib.
import '../../../models/trabajo_asignado.dart';
import '../../repositories/trabajo_asignado_repository.dart';

/// Caso de uso para obtener todos los trabajos asignados.
class ObtenerTrabajosAsignados {
  final TrabajoAsignadoRepository _repo;
  ObtenerTrabajosAsignados(this._repo);

  Future<List<TrabajoAsignado>> call(String empresaId) async {
    return _repo.obtenerTrabajosAsignados(empresaId);
  }
}
