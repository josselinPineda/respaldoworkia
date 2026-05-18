import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workia/presentation/viewmodels/sesiones_viewmodel.dart';
import 'package:workia/l10n/app_localizations.dart';

class TechnicianSessionsModal extends StatefulWidget {
  final String tecnicoId;
  final String tecnicoNombre;
  final String trabajoAsignadoId;
  final String empresaId;

  const TechnicianSessionsModal({
    super.key,
    required this.tecnicoId,
    required this.tecnicoNombre,
    required this.trabajoAsignadoId,
    required this.empresaId,
  });

  @override
  State<TechnicianSessionsModal> createState() =>
      _TechnicianSessionsModalState();
}

class _TechnicianSessionsModalState extends State<TechnicianSessionsModal> {
  @override
  void initState() {
    super.initState();
    // Iniciar la escucha de sesiones para esta asignación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SesionesViewModel>().init(widget.trabajoAsignadoId);
    });
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(double hours) {
    if (hours <= 0) return '0m';
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${t.timeLogTitle}: ${widget.tecnicoNombre}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          Flexible(
            child: Consumer<SesionesViewModel>(
              builder: (context, sesionesVM, child) {
                if (sesionesVM.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // Filtrar sesiones por técnico
                final sesiones = sesionesVM.sesiones
                    .where((s) => s.tecnicoId == widget.tecnicoId)
                    .toList();

                if (sesiones.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            t.noActivitiesMessage,
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: sesiones.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final sesion = sesiones[index];
                    final isRunning = sesion.fin == null;

                    // Calcular duración en tiempo real si está corriendo
                    double displayHours = sesion.horas;
                    if (isRunning) {
                      final duration = DateTime.now().difference(sesion.inicio);
                      displayHours = duration.inMinutes / 60.0;
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isRunning
                              ? Colors.green.shade50
                              : Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isRunning ? Icons.play_arrow : Icons.access_time,
                          color: isRunning ? Colors.green : Colors.blue,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '${sesion.inicio.day}/${sesion.inicio.month}/${sesion.inicio.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            isRunning
                                ? '${_formatTime(sesion.inicio)} - ...'
                                : '${_formatTime(sesion.inicio)} - ${_formatTime(sesion.fin!)}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          if (isRunning) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'EN VIVO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: Text(
                        _formatDuration(displayHours),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isRunning ? Colors.green : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
