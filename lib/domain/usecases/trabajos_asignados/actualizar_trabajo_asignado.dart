// Corregimos la ruta para importar el modelo desde la raíz de lib.
import '../../../models/trabajo_asignado.dart';
import '../../repositories/trabajo_asignado_repository.dart';

/// Caso de uso para actualizar un trabajo asignado existente.
class ActualizarTrabajoAsignado {
  final TrabajoAsignadoRepository _repo;
  ActualizarTrabajoAsignado(this._repo);

  Future<void> call(TrabajoAsignado trabajoAsignado) async {
    await _repo.actualizarTrabajoAsignado(trabajoAsignado);
  }
}