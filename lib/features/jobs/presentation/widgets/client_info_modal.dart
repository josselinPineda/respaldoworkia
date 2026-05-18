import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/models/cliente.dart';
import 'package:workia/models/job.dart';
import 'package:workia/models/trabajo_asignado.dart';
import 'package:workia/models/usuario.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/presentation/viewmodels/sesiones_viewmodel.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';
import 'package:workia/widgets/cliente_mini_map_section.dart';
import 'package:workia/widgets/tech_sessions_modal.dart';
import 'package:workia/utils/ui_utils.dart';

/// Modal que muestra información detallada de un cliente.
///
/// Incluye datos de contacto, fechas de la asignación, técnicos asignados
/// y un mini mapa si hay coordenadas disponibles.
class ClientInfoModal extends StatefulWidget {
  const ClientInfoModal({
    super.key,
    required this.client,
    required this.assignment,
    required this.job,
  });

  final Cliente client;
  final TrabajoAsignado assignment;
  final Trabajo job;

  @override
  State<ClientInfoModal> createState() => _ClientInfoModalState();
}

class _ClientInfoModalState extends State<ClientInfoModal> {
  Set<String> _selectedSegment = {'tecnicos'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SesionesViewModel>().init(widget.assignment.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.client.nombre,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Contenido
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Datos del cliente
                        _ClientDataSection(client: widget.client),
                        const SizedBox(height: 8),

                        // Fechas de la asignación
                        _AssignmentDatesSection(assignment: widget.assignment),

                        // Segmented Button
                        Center(
                          child: SegmentedButton<String>(
                            segments: [
                              ButtonSegment<String>(
                                value: 'tecnicos',
                                label: Text(t.techniciansLabel),
                                icon: const Icon(Icons.people),
                              ),
                              ButtonSegment<String>(
                                value: 'mapa',
                                label: Text(t.mapTabLabel),
                                icon: const Icon(Icons.map),
                              ),
                            ],
                            selected: _selectedSegment,
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _selectedSegment = newSelection;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Contenido según selección
                        if (_selectedSegment.contains('tecnicos'))
                          _TechniciansSection(
                            assignment: widget.assignment,
                            job: widget.job,
                          )
                        else
                          _MapSection(client: widget.client),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientDataSection extends StatelessWidget {
  const _ClientDataSection({required this.client});

  final Cliente client;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (client.razonSocial.isNotEmpty)
          _DataRow(icon: Icons.business_outlined, text: client.razonSocial),
        if (client.personaContacto.isNotEmpty)
          _DataRow(icon: Icons.person_outline, text: client.personaContacto),
        if (client.correo.isNotEmpty)
          _DataRow(icon: Icons.email_outlined, text: client.correo),
        if (client.telefono.isNotEmpty)
          _DataRow(icon: Icons.phone_outlined, text: client.telefono),
        if (client.direccion.isNotEmpty)
          _DataRow(icon: Icons.location_on_outlined, text: client.direccion),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentDatesSection extends StatelessWidget {
  const _AssignmentDatesSection({required this.assignment});

  final TrabajoAsignado assignment;

  @override
  Widget build(BuildContext context) {
    final start = assignment.fechaInicio;
    final next = assignment.proximaFecha;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: Colors.black54,
            ),
            const SizedBox(width: 8),
            Text(
              'Fecha Realización: ${start.day}/${start.month}/${start.year}',
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (next != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                const Icon(Icons.event_repeat, size: 16, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  'Próxima: ${next.day}/${next.month}/${next.year}',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _TechniciansSection extends StatelessWidget {
  const _TechniciansSection({required this.assignment, required this.job});

  final TrabajoAsignado assignment;
  final Trabajo job;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final usuariosVM = context.watch<UsuariosViewModel>();
    final userProvider = context.read<UserSessionProvider>();

    // Obtener técnicos asignados
    final List<Usuario> techs = [];
    for (final id in assignment.tecnicosAsignados) {
      final user = usuariosVM.usuarios.firstWhere(
        (u) => u.id == id,
        orElse: () => Usuario(
          id: id,
          authUid: '',
          nombre: id,
          email: '',
          idEmpresa: '',
          perfilId: '',
        ),
      );
      techs.add(user);
    }
    techs.sort((a, b) => a.nombre.compareTo(b.nombre));

    // Consolidar horas de la asignación
    Map<String, dynamic> logs = {};
    if (assignment.horasAcumuladas.isNotEmpty) {
      assignment.horasAcumuladas.forEach((userId, horas) {
        logs[userId] = {'horas': horas};
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.assignedTechniciansLabel,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _TechniciansList(
          techs: techs,
          executionLogs: logs,
          currentUserId: userProvider.userId,
          userRole: userProvider.userRole,
          trabajoAsignadoId: assignment.id,
          empresaId: userProvider.empresaId,
          assignment: assignment,
        ),
      ],
    );
  }
}

class _TechniciansList extends StatefulWidget {
  const _TechniciansList({
    required this.techs,
    required this.executionLogs,
    required this.currentUserId,
    required this.userRole,
    required this.trabajoAsignadoId,
    required this.empresaId,
    required this.assignment,
  });

  final List<Usuario> techs;
  final Map<String, dynamic> executionLogs;
  final String currentUserId;
  final String userRole;
  final String trabajoAsignadoId;
  final String empresaId;
  final TrabajoAsignado assignment;

  @override
  State<_TechniciansList> createState() => _TechniciansListState();
}

class _TechniciansListState extends State<_TechniciansList> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final filteredTechs = widget.techs
        .where((u) => u.nombre.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    final isAdminOrCompany =
        widget.userRole == 'PERF_ADMIN' || widget.userRole == 'PERF_EMPRESA';

    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: t.searchTechnicianLabel,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (val) => setState(() => _search = val),
        ),
        const SizedBox(height: 8),
        if (filteredTechs.isEmpty)
          Text(
            t.noTechniciansAssignedMessage,
            style: const TextStyle(color: Colors.black54),
          )
        else
          ...filteredTechs.map((tech) {
            final isMe = tech.id == widget.currentUserId;
            final canViewDetails = isMe || isAdminOrCompany;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: () {
                  showWorkiaBottomSheet(
                    context: context,
                    builder: (context) => TechnicianSessionsModal(
                      tecnicoId: tech.id,
                      tecnicoNombre: tech.nombre,
                      trabajoAsignadoId: widget.trabajoAsignadoId,
                      empresaId: widget.empresaId,
                    ),
                  );
                },
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(tech.nombre),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tech.email.isNotEmpty)
                        Text(
                          '${t.emailPrefix}${tech.email}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      if (tech.telefono.isNotEmpty)
                        Text(
                          '${t.phonePrefix}${tech.telefono}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  // Se eliminó el acceso a "Actividades" desde este modal.
                  trailing: canViewDetails ? const Icon(Icons.chevron_right) : null,
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _MapSection extends StatelessWidget {
  const _MapSection({required this.client});

  final Cliente client;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Enlace a Google Maps
        if (client.lat != null &&
            client.lng != null &&
            (client.lat != 0 || client.lng != 0))
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              onTap: () async {
                final uri = Uri.parse(
                  'https://www.google.com/maps/search/?api=1&query=${client.lat},${client.lng}',
                );
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Row(
                children: [
                  const Icon(Icons.map, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    t.openInGoogleMaps,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Mini mapa
        ClienteMiniMapSection(clienteId: client.id, useCard: false),
      ],
    );
  }
}
