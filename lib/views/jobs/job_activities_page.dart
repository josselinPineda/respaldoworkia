import 'package:flutter/material.dart';
import 'package:workia/utils/ui_utils.dart';
import 'package:provider/provider.dart';

import 'package:workia/models/trabajo_asignado.dart';
import 'package:workia/features/activities/presentation/viewmodels/actividades_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/presentation/viewmodels/sesiones_viewmodel.dart';
import 'package:workia/widgets/activity_item.dart';
import 'package:workia/widgets/activity_dialog.dart';
import 'package:workia/l10n/app_localizations.dart';

/// Página que muestra las actividades registradas para una
/// asignación de trabajo y permite registrar nuevas actividades.
class JobActivitiesPage extends StatefulWidget {
  const JobActivitiesPage({
    super.key,
    required this.asignacion,
    required this.tituloTrabajo,
    required this.role,
    required this.userId,
    this.technicianId,
    this.technicianName,
  });

  /// Asignación de trabajo sobre la cual se mostrarán y
  /// registrarán actividades.
  final TrabajoAsignado asignacion;

  /// Título del trabajo original, utilizado para mostrar en la
  /// AppBar.
  final String tituloTrabajo;

  /// Rol del usuario actual.
  final String role;

  /// Identificador del usuario autenticado.
  final String userId;

  /// Identificador del técnico para filtrar actividades (opcional).
  final String? technicianId;

  /// Nombre del técnico para mostrar en el título (opcional).
  final String? technicianName;

  @override
  State<JobActivitiesPage> createState() => _JobActivitiesPageState();
}

class _JobActivitiesPageState extends State<JobActivitiesPage> {
  @override
  void initState() {
    super.initState();
    // Cargar actividades para la asignación actual cuando se crea la página.
    final actividadesVM = context.read<ActividadesViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      actividadesVM.cargarActividades(
        widget.asignacion.id,
        widget.asignacion.empresaId,
      );
      // Asegurar que la lista de usuarios esté cargada para mostrar
      // el nombre del técnico.
      final usuariosVM = context.read<UsuariosViewModel>();
      if (usuariosVM.usuarios.isEmpty) {
        usuariosVM.cargarUsuarios(widget.asignacion.empresaId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final asig = widget.asignacion;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.technicianName != null
              ? t.activitiesForJobTitle(widget.technicianName!)
              : t.activitiesForJobTitle(widget.tituloTrabajo),
        ),
      ),
      body: Consumer<ActividadesViewModel>(
        builder: (context, actividadesVM, _) {
          var actividades = actividadesVM.obtenerActividades(asig.id);

          // Filtrar por técnico si se proporciona un ID
          if (widget.technicianId != null) {
            actividades = actividades
                .where((a) => a.tecnicoId == widget.technicianId)
                .toList();
          }

          if (actividadesVM.cargando) {
            return const Center(child: CircularProgressIndicator());
          }
          if (actividades.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                await actividadesVM.cargarActividades(asig.id, asig.empresaId);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Center(child: Text(t.noActivitiesMessage)),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              await actividadesVM.cargarActividades(asig.id, asig.empresaId);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: actividades.length,
              itemBuilder: (context, index) {
                final act = actividades[index];
                final canEdit =
                    widget.role == 'PERF_ADMIN' ||
                    (widget.role == 'PERF_TEC' &&
                        act.tecnicoId == widget.userId);

                return ActivityItem(
                  actividad: act,
                  showClient: false,
                  onEdit: canEdit
                      ? () {
                          showWorkiaBottomSheet(
                            context: context,
                            builder: (_) => ActivityDialog(
                              trabajoId: widget.asignacion.trabajoId,
                              trabajoAsignadoId: widget.asignacion.id,
                              clienteId: widget.asignacion.clienteId,
                              empresaId: widget.asignacion.empresaId,
                              userId: widget.userId,
                              userName: widget.userId,
                              existingActivity: act,
                            ),
                          );
                        }
                      : null,
                  onDelete: canEdit
                      ? () {
                          showWorkiaBottomSheet(
                            context: context,
                            builder: (ctx) => Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    t.confirmDeleteTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    t.confirmDeleteActivityMessage.replaceAll(
                                      'activdad',
                                      'actividad',
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(t.cancelButton),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            Navigator.pop(ctx);
                                            await actividadesVM.eliminar(
                                              act.id,
                                              widget.asignacion.id,
                                              widget.asignacion.empresaId,
                                              widget.userId,
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(t.deleteButton),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      : null,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddActivityDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Muestra un cuadro de diálogo para registrar una nueva actividad
  /// vinculada al trabajo asignado.
  void _showAddActivityDialog(BuildContext context) {
    // 1. Validar estado del trabajo (Admin enable)
    final estado = widget.asignacion.estado.toLowerCase().replaceAll('_', ' ');
    final isAdminStarted = estado == 'iniciado' || estado == 'en progreso';

    if (!isAdminStarted) {
      String message;
      if (estado == 'pendiente' || estado == 'en espera') {
        message = 'El trabajo aún no ha sido iniciado por el administrador.';
      } else {
        message = 'El trabajo ya está finalizado o cerrado.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Validar sesión activa del técnico (Technician started)
    // El técnico debe tener una sesión activa para ESTA asignación (cronómetro corriendo).
    final sesionesVM = context.read<SesionesViewModel>();
    final activeSession = sesionesVM.getActiveSessionFor(widget.userId);
    final isWorkingOnThis =
        activeSession != null &&
        activeSession.trabajoAsignadoId == widget.asignacion.id;

    if (!isWorkingOnThis) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar el trabajo para registrar actividades.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showWorkiaBottomSheet(
      context: context,
      builder: (context) {
        return ActivityDialog(
          trabajoId: widget.asignacion.trabajoId,
          trabajoAsignadoId: widget.asignacion.id,
          clienteId: widget.asignacion.clienteId,
          empresaId: widget.asignacion.empresaId,
          userId: widget.userId,
          // Si estamos filtrando por técnico y el usuario actual no es ese técnico
          // (ej admin), tal vez deberíamos preseleccionar ese técnico?
          // Por simplicidad, usamos el usuario actual como creador.
          userName: widget.userId,
        );
      },
    );
  }
}
