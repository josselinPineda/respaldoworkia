import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/models/cliente.dart';
import 'package:workia/models/job.dart';
import 'package:workia/models/trabajo_asignado.dart';
import 'package:workia/features/jobs/presentation/viewmodels/job_detail_viewmodel.dart';
import 'package:workia/features/jobs/presentation/widgets/assign_client_sheet.dart';
import 'package:workia/features/jobs/presentation/widgets/client_info_modal.dart';
import 'package:workia/presentation/viewmodels/sesiones_viewmodel.dart';
import 'package:workia/utils/ui_utils.dart';

/// Tarjeta que muestra un cliente asignado a un trabajo.
///
/// Este widget es puramente visual:
/// - Recibe datos como parámetros.
/// - Dispara callbacks para acciones (mostrar info, editar).
/// - No contiene lógica de negocio.
class JobClientCard extends StatelessWidget {
  const JobClientCard({
    super.key,
    required this.client,
    required this.assignment,
    required this.role,
    required this.job,
  });

  final Cliente client;
  final TrabajoAsignado assignment;
  final String role;
  final Trabajo job;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showClientInfo(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  client.nombre.isNotEmpty
                      ? client.nombre[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info del cliente
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.nombre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (assignment.esCiclico) _CyclicBadge(),
                    if (client.telefono.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _InfoRow(icon: Icons.phone, text: client.telefono),
                    ],
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.calendar_today,
                      text: _formatDate(assignment.fechaInicio),
                    ),
                    if (assignment.proximaFecha != null) ...[
                      const SizedBox(height: 4),
                      _InfoRow(
                        icon: Icons.event_repeat,
                        text: _formatDate(assignment.proximaFecha!),
                      ),
                    ],
                  ],
                ),
              ),

              // Acciones de estado
              if (role == 'PERF_TEC')
                _TechnicianStatusAction(assignment: assignment, job: job)
              else
                _AdminStatusDropdown(assignment: assignment),

              const SizedBox(width: 8),

              // Botón de editar (solo para admin)
              if (role != 'PERF_TEC')
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditSheet(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showClientInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) =>
          ClientInfoModal(client: client, assignment: assignment, job: job),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<JobDetailViewModel>(),
        child: AssignClientSheet(existingAssignment: assignment),
      ),
    );
  }
}

class _CyclicBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).primaryColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.loop, size: 10),
          const SizedBox(width: 4),
          Text(
            'Cíclico',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.black54),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}

class _AdminStatusDropdown extends StatelessWidget {
  const _AdminStatusDropdown({required this.assignment});

  final TrabajoAsignado assignment;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final vm = context.read<JobDetailViewModel>();

    return PopupMenuButton<String>(
      initialValue: assignment.estado,
      onSelected: (String newStatus) {
        // Delegamos al ViewModel
        vm.updateAssignmentStatus(assignment, newStatus);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'EN ESPERA',
          child: Text(
            t.jobStatusOnHold,
            style: TextStyle(color: _getStatusColor(context, 'EN ESPERA')),
          ),
        ),
        PopupMenuItem<String>(
          value: 'INICIADO',
          child: Text(
            t.jobStatusStarted,
            style: TextStyle(color: _getStatusColor(context, 'INICIADO')),
          ),
        ),
        PopupMenuItem<String>(
          value: 'FINALIZADO',
          child: Text(
            t.jobStatusFinished,
            style: TextStyle(color: _getStatusColor(context, 'FINALIZADO')),
          ),
        ),
        PopupMenuItem<String>(
          value: 'CERRADO',
          child: Text(
            t.jobStatusClosed,
            style: TextStyle(color: _getStatusColor(context, 'CERRADO')),
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            assignment.estado.replaceAll('_', ' '),
            style: TextStyle(
              color: _getStatusColor(context, assignment.estado),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Icon(
            Icons.arrow_drop_down,
            color: _getStatusColor(context, assignment.estado),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BuildContext context, String status) {
    final e = status.replaceAll('_', ' ').toLowerCase();
    final scheme = Theme.of(context).colorScheme;
    switch (e) {
      case 'en espera':
      case 'pendiente':
        return scheme.primary.withOpacity(0.5);
      case 'iniciado':
      case 'en progreso':
        return Colors.orange;
      case 'finalizado':
      case 'completo':
        return Colors.green;
      case 'cerrado':
        return Colors.grey.shade700;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _TechnicianStatusAction extends StatelessWidget {
  const _TechnicianStatusAction({required this.assignment, required this.job});

  final TrabajoAsignado assignment;
  final Trabajo job;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final vm = context.watch<JobDetailViewModel>();
    final sesionesVM = context.watch<SesionesViewModel>();

    // Verificar si el usuario actual está asignado
    final isAssigned = vm.isCurrentUserAssignedTo(assignment);
    if (!isAssigned) return const SizedBox.shrink();

    // Precargar estado de sesión para evitar que tras re-login se muestre "Iniciar"
    // momentáneamente antes de conocer el estado real.
    if (!vm.hasHydratedSessionForAssignment(assignment.id) &&
        !vm.isHydratingSessionForAssignment(assignment.id)) {
      Future.microtask(() => vm.ensureSessionHydratedForAssignment(assignment.id));
    }

    final isSessionActive = sesionesVM.isSessionActiveFor(vm.currentUserId);
    final isHydrating =
        vm.isHydratingSessionForAssignment(assignment.id) && !isSessionActive;
    final normalized = assignment.estado.replaceAll('_', ' ').toLowerCase();

    if (isHydrating) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // Si no hay sesión activa y no está iniciado, mostrar badge
    if (normalized != 'iniciado' && !isSessionActive) {
      return _StatusBadge(status: assignment.estado);
    }

    // Si está cerrado o finalizado sin sesión activa, mostrar badge
    if ((normalized == 'cerrado' || normalized == 'finalizado') &&
        !isSessionActive) {
      return _StatusBadge(status: assignment.estado);
    }

    if (normalized == 'cerrado') {
      return _StatusBadge(status: assignment.estado);
    }

    // Botón de acción según sesión
    if (isSessionActive) {
      return ElevatedButton.icon(
        onPressed: () => vm.stopCurrentSession(assignment),
        icon: const Icon(Icons.stop, size: 16),
        label: Text(t.finishButton),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: () => _startSession(context, vm),
        icon: const Icon(Icons.play_arrow, size: 16),
        label: Text(t.startButton),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    }
  }

  Future<void> _startSession(
    BuildContext context,
    JobDetailViewModel vm,
  ) async {
    final result = await vm.startSessionForAssignment(assignment);

    if (!context.mounted) return;

    if (!result.success) {
      if (result.isOutOfRange) {
        // Mostrar modal de fuera de rango
        showWorkiaBottomSheet(
          context: context,
          builder: (context) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Fuera de rango',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Estás a ${result.distance} metros del trabajo. Debes estar a menos de ${result.maxDistance} m.',
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        );
      } else {
        // Mostrar snackbar con error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Error desconocido')),
        );
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(context, status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(context, status)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(context, status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, String status) {
    final e = status.replaceAll('_', ' ').toLowerCase();
    final scheme = Theme.of(context).colorScheme;
    switch (e) {
      case 'en espera':
      case 'pendiente':
        return scheme.primary.withOpacity(0.5);
      case 'iniciado':
      case 'en progreso':
        return Colors.orange;
      case 'finalizado':
      case 'completo':
        return Colors.green;
      case 'cerrado':
        return Colors.grey.shade700;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
