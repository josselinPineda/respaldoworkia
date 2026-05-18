import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/utils/ui_utils.dart'; // For showWorkiaBottomSheet if needed
import 'package:intl/intl.dart';

// Models
import 'package:workia/models/cliente.dart';
import 'package:workia/models/job.dart';
import 'package:workia/models/trabajo_asignado.dart';

// ViewModels
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/features/clients/presentation/viewmodels/client_detail_viewmodel.dart';

// Views/Widgets
import 'package:workia/features/clients/presentation/views/client_edit_screen.dart';
import 'package:workia/widgets/mini_map.dart';

class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({
    super.key,
    required this.clientId, // Pass ID instead of object to force fresh data usage
    required this.userId,
    required this.empresaId,
    required this.role,
  });

  final String clientId;
  final String userId;
  final String empresaId;
  final String role;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final empresaId = widget.empresaId;
    // Cargamos los datos principales que usa esta pantalla:
    // - trabajos asignados al cliente
    // - trabajos disponibles en la empresa
    // - usuarios/técnicos del mismo empresa
    // - lista de clientes actualizada
    context.read<TrabajosAsignadosViewModel>().cargarTrabajosAsignados(
      empresaId,
    );
    context.read<TrabajosViewModel>().cargarTrabajos(empresaId);
    context.read<UsuariosViewModel>().cargarUsuarios(empresaId);
    context.read<ClientesViewModel>().cargarClientes(empresaId);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // Obtener el cliente actualizado desde el ViewModel
    // Buscamos el cliente actual dentro del ViewModel de clientes.
    // Usamos select para que solo se reconstruya este widget cuando cambie
    // la lista de clientes.
    final client = context.select<ClientesViewModel, Cliente?>((vm) {
      try {
        return vm.clientes.firstWhere((c) => c.id == widget.clientId);
      } catch (_) {
        return null;
      }
    });

    if (client == null) {
      // Si el cliente aún no está disponible, mostramos un indicador de carga.
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider(
      // Se crea un ViewModel local para esta pantalla de detalle de cliente.
      // Este ViewModel maneja filtros, búsqueda y estado de las pestañas.
      create: (_) => ClientDetailViewModel(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(client.nombre),
            bottom: TabBar(
              tabs: [
                Tab(text: t.infoTab),
                Tab(text: t.jobsTab),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _ClientInfoTab(
                client: client,
                userId: widget.userId,
                empresaId: widget.empresaId,
              ),
              _ClientJobsTab(client: client, empresaId: widget.empresaId),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientInfoTab extends StatelessWidget {
  const _ClientInfoTab({
    required this.client,
    required this.userId,
    required this.empresaId,
  });

  final Cliente client;
  final String userId;
  final String empresaId;

  Future<void> _deleteClient(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final clientesVM = context.read<ClientesViewModel>();
    final navigator = Navigator.of(context);

    final confirm = await showWorkiaBottomSheet<bool>(
      context: context,
      builder: (dialogContext) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.deleteClientTitle,
                style: Theme.of(
                  dialogContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(t.deleteClientConfirmation),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(t.cancelButton),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: Text(t.deleteButton),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirm == true) {
      await clientesVM.eliminar(client.id, empresaId, userId);
      if (navigator.mounted) navigator.pop(); // Volver atrÃ¡s
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MiniMap(lat: client.lat ?? 0, lng: client.lng ?? 0, height: 220),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (client.lat != null && client.lng != null) {
                  final uri = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=${client.lat},${client.lng}',
                  );
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.map),
              label: Text(t.openInGoogleMapsButton),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(context, t.nameLabel, client.nombre),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, t.legalNameLabel, client.razonSocial),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    t.contactPersonLabel,
                    client.personaContacto,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, t.emailLabel, client.correo),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, t.phoneLabel, client.telefono),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, t.addressLabel, client.direccion),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: t.editButton,
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClientEditScreen(
                                client: client,
                                userId: userId,
                                empresaId: empresaId,
                              ),
                            ),
                          );
                          if (!context.mounted) return;
                          context.read<ClientesViewModel>().cargarClientes(
                            empresaId,
                          );
                        },
                      ),
                      IconButton(
                        tooltip: t.deleteButton,
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteClient(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String? value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          (value == null || value.isEmpty) ? '-' : value,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
        ),
      ],
    );
  }
}

class _ClientJobsTab extends StatelessWidget {
  const _ClientJobsTab({required this.client, required this.empresaId});

  final Cliente client;
  final String empresaId;

  String _formatDate(DateTime dt) {
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  void _showAssignJobDialog(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final trabajosVM = context.read<TrabajosViewModel>();
    final asignadosVM = context.read<TrabajosAsignadosViewModel>();
    final trabajos = List<Trabajo>.from(trabajosVM.trabajos);
    final tempSelected = <String>{};

    await showWorkiaBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.assignJobsToClientTitle,
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: trabajos.length,
                        itemBuilder: (ctx, index) {
                          final job = trabajos[index];
                          return CheckboxListTile(
                            title: Text(job.titulo),
                            value: tempSelected.contains(job.id),
                            onChanged: (val) {
                              setStateDialog(() {
                                if (val == true)
                                  tempSelected.add(job.id);
                                else
                                  tempSelected.remove(job.id);
                              });
                            },
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        for (final id in tempSelected) {
                          final job = trabajos.firstWhere((j) => j.id == id);
                          final asignado = TrabajoAsignado(
                            id: '',
                            clienteId: client.id,
                            trabajoId: job.id,
                            tituloTrabajo: job.titulo,
                            precioBase: job.costo,
                            precioFinal: job.costo,
                            estado: 'Pendiente',
                            fechaInicio: DateTime.now(),
                            fechaFin: DateTime.now(),
                            esCiclico: job.esCiclico,
                            frecuenciaCiclico: job.frecuenciaCiclico,
                            empresaId: empresaId,
                            tecnicosAsignados: [],
                            activo: true,
                            fechaCreacion: DateTime.now(),
                            fechaActualizacion: DateTime.now(),
                            creadoPor: '',
                            actualizadoPor: '',
                            // Handle missing fields if any
                          );
                          await asignadosVM.agregar(asignado);
                        }
                        if (context.mounted) {
                          context
                              .read<TrabajosAsignadosViewModel>()
                              .cargarTrabajosAsignados(empresaId);
                        }
                      },
                      child: Text(t.assignButton),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final detailVM = context.watch<ClientDetailViewModel>();
    final asignadosVM = context.watch<TrabajosAsignadosViewModel>();
    final trabajosVM = context.watch<TrabajosViewModel>();

    final assignments = detailVM.filterAssignments(
      asignadosVM.trabajos,
      trabajosVM.trabajos,
      client.id,
    );

    return Column(
      children: [
        // Filter UI
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: t.searchJobPlaceholder,
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: detailVM.setSearchQuery,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      detailVM.filtersVisible
                          ? Icons.filter_alt_off
                          : Icons.filter_alt,
                    ),
                    onPressed: detailVM.toggleFilters,
                  ),
                ],
              ),
              if (detailVM.filtersVisible) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: detailVM.statusFilter,
                  items:
                      [
                            'Todos',
                            'En espera',
                            'Iniciado',
                            'Finalizado',
                            'Cerrado',
                          ]
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (v) => detailVM.setStatusFilter(v ?? 'Todos'),
                  decoration: InputDecoration(labelText: t.filterByStatusLabel),
                ),
                // Date picker button simplified
                TextButton(
                  onPressed: () async {
                    final results = await showCalendarDatePicker2Dialog(
                      context: context,
                      config: CalendarDatePicker2WithActionButtonsConfig(
                        calendarType: CalendarDatePicker2Type.range,
                      ),
                      dialogSize: const Size(325, 400),
                      value: [detailVM.startDate, detailVM.endDate],
                    );
                    if (results != null && results.isNotEmpty) {
                      detailVM.setDateRange(results.first, results.last);
                    }
                  },
                  child: Text(
                    detailVM.startDate == null
                        ? t.selectDateRangeButton
                        : '${_formatDate(detailVM.startDate!)} - ${_formatDate(detailVM.endDate!)}',
                  ),
                ),
              ],
            ],
          ),
        ),
        // Add Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAssignJobDialog(context),
              icon: const Icon(Icons.add),
              label: Text(t.newAssignedJobButton),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await context
                  .read<TrabajosAsignadosViewModel>()
                  .cargarTrabajosAsignados(empresaId);
            },
            child: assignments.isEmpty
                ? Center(child: Text(t.noAssignedJobsMessage))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: assignments.length,
                    itemBuilder: (context, index) {
                      final assignment = assignments[index];
                      return Card(
                        child: ListTile(
                          title: Text(assignment.tituloTrabajo),
                          subtitle: Text(assignment.estado),
                          trailing: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: detailVM.getStatusColor(
                                assignment.estado,
                                context,
                              ),
                            ),
                          ),
                          onTap: () {
                            // Can show assignment detail or edit status
                          },
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
