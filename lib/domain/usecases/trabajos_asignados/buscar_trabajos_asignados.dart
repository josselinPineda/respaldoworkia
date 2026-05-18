// Corregimos la ruta para importar el modelo desde la raíz de lib.
import '../../../models/trabajo_asignado.dart';
import '../../repositories/trabajo_asignado_repository.dart';

/// Caso de uso para buscar trabajos asignados según una cadena de búsqueda.
class BuscarTrabajosAsignados {
  final TrabajoAsignadoRepository _repo;
  BuscarTrabajosAsignados(this._repo);

  Future<List<TrabajoAsignado>> call(String consulta, String empresaId) async {
    return _repo.buscarTrabajosAsignados(consulta, empresaId);
  }
}
