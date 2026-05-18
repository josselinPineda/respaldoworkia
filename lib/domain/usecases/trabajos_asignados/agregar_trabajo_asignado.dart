// Corregimos la ruta para importar el modelo desde la raíz de lib.
import '../../../models/trabajo_asignado.dart';
import '../../repositories/trabajo_asignado_repository.dart';

/// Caso de uso para agregar un trabajo asignado.
class AgregarTrabajoAsignado {
  final TrabajoAsignadoRepository _repo;
  AgregarTrabajoAsignado(this._repo);

  Future<void> call(TrabajoAsignado trabajoAsignado) async {
    await _repo.agregarTrabajoAsignado(trabajoAsignado);
  }
}