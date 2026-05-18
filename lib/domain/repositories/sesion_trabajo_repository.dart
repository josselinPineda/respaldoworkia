import 'package:workia/models/sesion_trabajo.dart';

abstract class SesionTrabajoRepository {
  Stream<List<SesionTrabajo>> getSesionesPorAsignacion(
    String trabajoAsignadoId,
  );
  String generateId();
  Future<void> iniciarSesion(
    String trabajoAsignadoId,
    String tecnicoId,
    String trabajoId, {
    String? sesionId,
    required String empresaId,
  });
  Future<void> finalizarSesion(String sesionId, String trabajoAsignadoId);
  Future<SesionTrabajo?> obtenerSesionActiva(
    String trabajoAsignadoId,
    String tecnicoId,
  );
  Future<List<SesionTrabajo>> obtenerSesionesPorEmpresaYFecha(
    String empresaId,
    DateTime fecha,
  );
  Future<List<SesionTrabajo>> obtenerTodasSesionesPorEmpresa(String empresaId);
}
