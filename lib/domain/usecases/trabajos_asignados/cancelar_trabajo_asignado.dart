import '../../repositories/trabajo_asignado_repository.dart';

/// Caso de uso para cancelar un trabajo asignado.
class CancelarTrabajoAsignado {
  final TrabajoAsignadoRepository _repo;
  CancelarTrabajoAsignado(this._repo);

  Future<void> call(String id, String actualizadoPor) async {
    await _repo.cancelarTrabajoAsignado(id, actualizadoPor);
  }
}
