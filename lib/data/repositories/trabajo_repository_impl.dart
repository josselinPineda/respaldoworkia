import '../../domain/repositories/trabajo_repository.dart';
import '../../models/job.dart';

/// Implementación en memoria del repositorio de trabajos.
class TrabajoRepositoryImpl implements TrabajoRepository {
  final List<Trabajo> _trabajos = [
    // Datos de ejemplo para mostrar en la agenda y otras vistas.  Estos
    // trabajos deberían cargarse desde un backend en una aplicación real.
    Trabajo(
      id: '1',
      titulo: 'Mantenimiento Preventivo',
      cliente: 'Cliente A',
      fechaInicio: DateTime(2024, 11, 1),
      fechaFin: DateTime(2024, 11, 3),
      estado: 'Pendiente',
      descripcion: '',
      costo: 500.0,
    ),
    Trabajo(
      id: '2',
      titulo: 'Instalación Nueva',
      cliente: 'Cliente B',
      fechaInicio: DateTime(2024, 11, 5),
      fechaFin: DateTime(2024, 11, 6),
      estado: 'En Progreso',
      descripcion: '',
      costo: 750.0,
    ),
    Trabajo(
      id: '3',
      titulo: 'Revisión General',
      cliente: 'Cliente C',
      fechaInicio: DateTime(2024, 11, 7),
      fechaFin: DateTime(2024, 11, 7),
      estado: 'Completo',
      descripcion: '',
      costo: 300.0,
    ),
  ];

  String _generarId() => DateTime.now().millisecondsSinceEpoch.toString();

  @override
  Future<List<Trabajo>> obtenerTrabajos(String empresaId) async {
    return List.unmodifiable(
      _trabajos.where(
        (t) => t.activo && (t.empresaId == empresaId || t.empresaId.isEmpty),
      ),
    );
  }

  @override
  Future<void> agregarTrabajo(Trabajo trabajo) async {
    final nuevo = trabajo.id.isEmpty
        ? Trabajo(
            id: _generarId(),
            titulo: trabajo.titulo,
            cliente: trabajo.cliente,
            fechaInicio: trabajo.fechaInicio,
            fechaFin: trabajo.fechaFin,
            estado: trabajo.estado,
            descripcion: trabajo.descripcion,
            costo: trabajo.costo,
            esCiclico: trabajo.esCiclico,
            frecuenciaCiclico: trabajo.frecuenciaCiclico,
            proximaFecha: trabajo.proximaFecha,
            empleadosAsignados: trabajo.empleadosAsignados,
            clientesAsignados: trabajo.clientesAsignados,
            activo: true,
            empresaId: trabajo.empresaId,
          )
        : trabajo;
    _trabajos.add(nuevo);
  }

  @override
  Future<void> actualizarTrabajo(Trabajo actualizado) async {
    final index = _trabajos.indexWhere((t) => t.id == actualizado.id);
    if (index != -1) {
      _trabajos[index] = actualizado;
    }
  }

  @override
  Future<void> cancelarTrabajo(String id, String actualizadoPor) async {
    final index = _trabajos.indexWhere((j) => j.id == id);
    if (index != -1) {
      final trabajo = _trabajos[index];
      _trabajos[index] = trabajo.copyWith(
        activo: false,
        actualizadoPor: actualizadoPor,
        fechaActualizacion: DateTime.now(),
      );
    }
  }

  @override
  Future<List<Trabajo>> buscarTrabajos(
    String consulta,
    String empresaId,
  ) async {
    final lower = consulta.toLowerCase();
    return _trabajos
        .where(
          (j) =>
              j.activo &&
              (j.empresaId == empresaId || j.empresaId.isEmpty) &&
              (j.titulo.toLowerCase().contains(lower) ||
                  j.cliente.toLowerCase().contains(lower) ||
                  j.estado.toLowerCase().contains(lower)),
        )
        .toList();
  }
}
