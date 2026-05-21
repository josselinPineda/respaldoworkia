import 'package:flutter/material.dart';
import 'package:workia/utils/ui_utils.dart';
import 'package:provider/provider.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:url_launcher/url_launcher.dart';
// Fallback para obtener usuario autenticado
import 'package:firebase_auth/firebase_auth.dart';

import 'package:workia/models/cliente.dart';
import 'package:workia/models/job.dart';
import 'package:workia/models/trabajo_asignado.dart';
import 'package:workia/models/usuario.dart';

import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';

import 'package:workia/views/clients/client_edit_page.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/widgets/currency_text.dart';
import 'package:intl/intl.dart';

import 'package:workia/widgets/mini_map.dart';

import 'package:dropdown_search/dropdown_search.dart';

/// Vista detallada de un cliente con pestañas para mostrar la
/// información general y los trabajos asignados.
class ClientTabsPage extends StatefulWidget {
  const ClientTabsPage({
    super.key,
    required this.client,
    required this.userId,
    required this.empresaId,
    required this.role,
  });

  final Cliente client;
  final String userId;
  final String empresaId;
  final String role;

  @override
  State<ClientTabsPage> createState() => _ClientTabsPageState();
}

class _ClientTabsPageState extends State<ClientTabsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Cliente _currentClient;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentClient = widget.client;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrabajosAsignadosViewModel>().cargarTrabajosAsignados(
        widget.empresaId,
      );
      context.read<TrabajosViewModel>().cargarTrabajos(widget.empresaId);
      context.read<UsuariosViewModel>().cargarUsuarios(widget.empresaId);
    });
  }

  // Variables para búsqueda y filtro en la pestaña de trabajos
  final TextEditingController _jobSearchController = TextEditingController();
  String _jobStatusFilter = 'Todos';
  bool _showFilters = false;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  void dispose() {
    _tabController.dispose();
    _jobSearchController.dispose();
    super.dispose();
  }

  String _normalizeStatus(String status) {
    // Normalizamos cadenas para comparaciones seguras.
    final lower = status.replaceAll('_', ' ').toLowerCase().trim();
    if (lower == 'pendiente' ||
        lower == 'pending' ||
        lower == 'on hold' ||
        lower == 'en espera')
      return 'en espera';
    if (lower == 'iniciado' || lower == 'started') return 'iniciado';
    if (lower == 'finalizado' || lower == 'finished') return 'finalizado';
    if (lower == 'cerrado' || lower == 'closed') return 'cerrado';
    return lower;
  }

  Color _getStatusColor(String status) {
    final normalized = _normalizeStatus(status);
    switch (normalized) {
      case 'iniciado':
        return Colors.orange;
      case 'finalizado':
        return Colors.green;
      case 'en espera':
        return Theme.of(context).primaryColor;
      case 'cerrado':
        return Colors.grey.shade700;
      default:
        return Colors.grey;
    }
  }

  List<DropdownMenuItem<String>> _buildUniqueStatusFilterItems(
    AppLocalizations t,
  ) {
    final raw = <MapEntry<String, String>>[
      MapEntry('Todos', t.allOption),
      MapEntry('En espera', t.jobStatusOnHold),
      MapEntry('Iniciado', t.jobStatusStarted),
      MapEntry('Finalizado', t.jobStatusFinished),
      MapEntry('Cerrado', t.jobStatusClosed),
    ];

    final seenLabels = <String>{};
    final items = <DropdownMenuItem<String>>[];
    for (final e in raw) {
      final labelKey = e.value.toLowerCase().trim();
      if (seenLabels.add(labelKey)) {
        items.add(DropdownMenuItem(value: e.key, child: Text(e.value)));
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentClient.nombre),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t.infoTab),
            Tab(text: t.jobsTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildInfoTab(), _buildJobsTab()],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB INFO
  // ---------------------------------------------------------------------------

  Widget _buildInfoTab() {
    final cliente = _currentClient;
    // Localization instance for this tab
    final t = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MiniMap(lat: cliente.lat ?? 0, lng: cliente.lng ?? 0, height: 220),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=${cliente.lat},${cliente.lng}',
                  );
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.map),
                label: Text(t.openInGoogleMapsButton),
              ),
            ),
            const SizedBox(height: 24),

            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(t.nameLabel, cliente.nombre),
                    const SizedBox(height: 12),
                    _buildInfoRow(t.legalNameLabel, cliente.razonSocial),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      t.contactPersonLabel,
                      cliente.personaContacto,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(t.emailLabel, cliente.correo),
                    const SizedBox(height: 12),
                    _buildInfoRow(t.phoneLabel, cliente.telefono),
                    const SizedBox(height: 12),
                    _buildInfoRow(t.addressLabel, cliente.direccion),
                    const SizedBox(height: 16),

                    // Botones tipo icono alineados a la derecha (como en tarjeta de trabajos)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: AppLocalizations.of(context)!.editButton,
                          icon: const Icon(Icons.edit),
                          onPressed: _editClient,
                        ),
                        IconButton(
                          tooltip: AppLocalizations.of(context)!.deleteButton,
                          icon: const Icon(Icons.delete),
                          onPressed: _deleteClient,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
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

  Future<void> _editClient() async {
    final clientesVM = context.read<ClientesViewModel>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientEditPage(
          client: _currentClient,
          userId: widget.userId,
          empresaId: widget.empresaId,
        ),
      ),
    );
    if (!mounted) return;
    await clientesVM.cargarClientes(widget.empresaId);
    final updated = clientesVM.clientes.firstWhere(
      (c) => c.id == _currentClient.id,
      orElse: () => _currentClient,
    );
    setState(() {
      _currentClient = updated;
    });
  }

  Future<void> _deleteClient() async {
    final clientesVM = context.read<ClientesViewModel>();
    final confirm = await showWorkiaBottomSheet<bool>(
      context: context,
      builder: (dialogContext) {
        final t = AppLocalizations.of(dialogContext)!;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.deleteClientTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(t.deleteClientConfirmation),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(t.cancelButton),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

    if (confirm ?? false) {
      if (!mounted) return;
      // Fix: Ensure we use the current session ID for audit
      String currentUserId = widget.userId;
      try {
        // 1. Try Session Provider
        final session = context.read<UserSessionProvider>();
        if (session.userId.isNotEmpty) {
          currentUserId = session.userId;
        }
      } catch (_) {}

      // 2. Fallback to FirebaseAuth if still empty
      if (currentUserId.isEmpty) {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          currentUserId = firebaseUser.uid;
        }
      }

      await clientesVM.eliminar(
        _currentClient.id,
        widget.empresaId,
        currentUserId,
      );
      if (!context.mounted) return;
      Navigator.of(context).pop();
    }
  }

  // ---------------------------------------------------------------------------
  // TAB TRABAJOS (igual que lo tenías, sólo armonizado con el estilo)
  // ---------------------------------------------------------------------------

  Widget _buildJobsTab() {
    return Consumer<TrabajosAsignadosViewModel>(
      builder: (context, asignadosVM, _) {
        final trabajosVM = context.read<TrabajosViewModel>();
        // Filtrar únicamente las asignaciones activas del cliente.
        var lista = asignadosVM.trabajos
            .where((a) => a.clienteId == _currentClient.id && a.activo)
            .toList();

        // Aplicar filtros de búsqueda y estado
        final query = _jobSearchController.text.trim().toLowerCase();
        if (query.isNotEmpty) {
          lista = lista.where((a) {
            final trabajo = trabajosVM.trabajos.firstWhere(
              (t) => t.id == a.trabajoId,
              orElse: () => Trabajo(
                id: '',
                titulo: '',
                cliente: '',
                clienteId: '',
                fechaInicio: DateTime.now(),
                fechaFin: DateTime.now(),
                estado: '',
                descripcion: '',
                costo: 0,
                empleadosAsignados: const [],
                clientesAsignados: const [],
                esCiclico: false,
                empresaId: '',
              ),
            );
            return trabajo.titulo.toLowerCase().contains(query) ||
                a.tituloTrabajo.toLowerCase().contains(query);
          }).toList();
        }

        if (_jobStatusFilter != 'Todos') {
          lista = lista.where((a) => a.estado == _jobStatusFilter).toList();
        }

        if (_filterStartDate != null && _filterEndDate != null) {
          lista = lista.where((a) {
            // Normalizar fechas para comparar solo día/mes/año
            final start = DateTime(
              _filterStartDate!.year,
              _filterStartDate!.month,
              _filterStartDate!.day,
            );
            final end = DateTime(
              _filterEndDate!.year,
              _filterEndDate!.month,
              _filterEndDate!.day,
              23,
              59,
              59,
            );
            return a.fechaInicio.isAfter(start) && a.fechaInicio.isBefore(end);
          }).toList();
        }

        // Localization helper
        final t = AppLocalizations.of(context)!;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fila de búsqueda y botón de filtro
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _jobSearchController,
                      decoration: InputDecoration(
                        labelText: t.searchJobPlaceholder,
                        prefixIcon: const Icon(Icons.search),

                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _showFilters ? Icons.filter_alt_off : Icons.filter_alt,
                    ),
                    tooltip: _showFilters
                        ? t.hideFiltersTooltip
                        : t.showFiltersTooltip,
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                  ),
                ],
              ),

              // Panel de filtros (Acordeón)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1.0,
                    child: child,
                  );
                },
                child: _showFilters
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _jobStatusFilter,
                              decoration: InputDecoration(
                                labelText: t.filterByStatusLabel,

                                isDense: true,
                              ),
                              items: _buildUniqueStatusFilterItems(t),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _jobStatusFilter = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () async {
                                final results = await showCalendarDatePicker2Dialog(
                                  context: context,
                                  config:
                                      CalendarDatePicker2WithActionButtonsConfig(
                                        calendarType:
                                            CalendarDatePicker2Type.range,
                                      ),
                                  dialogSize: const Size(325, 400),
                                  value: [_filterStartDate, _filterEndDate],
                                );
                                if (!mounted) return;
                                if (results != null && results.length >= 2) {
                                  setState(() {
                                    _filterStartDate = results[0];
                                    _filterEndDate = results[1];
                                  });
                                } else if (results != null && results.isEmpty) {
                                  // Limpiar filtro si se selecciona nada (cancelar o limpiar)
                                  // Depende de la implementación de calendar2, pero asumimos
                                  // que si devuelve lista vacía es limpiar.
                                  // Si el usuario cancela devuelve null.
                                  // Para limpiar explícitamente podríamos agregar un botón de limpiar.
                                }
                              },
                              child: Text(
                                (_filterStartDate != null &&
                                        _filterEndDate != null)
                                    ? '${t.rangeLabel}: ${_formatDate(_filterStartDate!)} - ${_formatDate(_filterEndDate!)}'
                                    : t.selectDateRangeButton,
                              ),
                            ),
                            if (_filterStartDate != null)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _filterStartDate = null;
                                    _filterEndDate = null;
                                  });
                                },
                                child: Text(t.cleanDatesButton),
                              ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showAssignJobDialog,
                icon: const Icon(Icons.add),
                label: Text(t.newAssignedJobButton),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    final trabajosAsignadosVM = context
                        .read<TrabajosAsignadosViewModel>();
                    final trabajosVM = context.read<TrabajosViewModel>();
                    final usuariosVM = context.read<UsuariosViewModel>();
                    // Recargar la data necesaria
                    await Future.wait([
                      trabajosAsignadosVM.cargarTrabajosAsignados(
                        widget.empresaId,
                      ),
                      trabajosVM.cargarTrabajos(widget.empresaId),
                      usuariosVM.cargarUsuarios(widget.empresaId),
                    ]);
                  },
                  child: lista.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(child: Text(t.noAssignedJobsMessage)),
                          ),
                        )
                      : ListView.builder(
                          itemCount: lista.length,
                          itemBuilder: (context, index) {
                            final a = lista[index];
                            final trabajo = trabajosVM.trabajos.firstWhere(
                              (t) => t.id == a.trabajoId,
                              orElse: () => Trabajo(
                                id: a.trabajoId,
                                titulo: a.trabajoId,
                                cliente: '',
                                clienteId: '',
                                fechaInicio: a.fechaInicio,
                                fechaFin: a.fechaFin,
                                estado: a.estado,
                                descripcion: '',
                                costo: 0,
                                empleadosAsignados: const [],
                                clientesAsignados: const [],
                                esCiclico: a.esCiclico,
                                frecuenciaCiclico: a.frecuenciaCiclico,
                                proximaFecha: a.proximaFecha,
                                empresaId: a.empresaId,
                              ),
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      trabajo.titulo,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    if (a.esCiclico)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).primaryColor.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.loop, size: 10),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Cíclico',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '${t.statusLabel}: ',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                        PopupMenuButton<String>(
                                          initialValue: a.estado,
                                          onSelected: (String newStatus) {
                                            if (newStatus != a.estado) {
                                              final updatedAssignment = a
                                                  .copyWith(estado: newStatus);
                                              context
                                                  .read<
                                                    TrabajosAsignadosViewModel
                                                  >()
                                                  .actualizar(
                                                    updatedAssignment,
                                                  );
                                            }
                                          },
                                          itemBuilder: (BuildContext context) =>
                                              <PopupMenuEntry<String>>[
                                                PopupMenuItem<String>(
                                                  value: 'EN ESPERA',
                                                  child: Text(
                                                    t.jobStatusOnHold,
                                                    style: TextStyle(
                                                      color: _getStatusColor(
                                                        'EN ESPERA',
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                PopupMenuItem<String>(
                                                  value: 'INICIADO',
                                                  child: Text(
                                                    t.jobStatusStarted,
                                                    style: TextStyle(
                                                      color: _getStatusColor(
                                                        'INICIADO',
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                PopupMenuItem<String>(
                                                  value: 'FINALIZADO',
                                                  child: Text(
                                                    t.jobStatusFinished,
                                                    style: TextStyle(
                                                      color: _getStatusColor(
                                                        'FINALIZADO',
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                PopupMenuItem<String>(
                                                  value: 'CERRADO',
                                                  child: Text(
                                                    t.jobStatusClosed,
                                                    style: TextStyle(
                                                      color: _getStatusColor(
                                                        'CERRADO',
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                a.estado,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _getStatusColor(
                                                  a.estado,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  a.estado.replaceAll('_', ' '),
                                                  style: TextStyle(
                                                    color: _getStatusColor(
                                                      a.estado,
                                                    ),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.arrow_drop_down,
                                                  size: 16,
                                                  color: _getStatusColor(
                                                    a.estado,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_formatDate(a.fechaInicio)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (widget.role == 'PERF_ADMIN')
                                      CurrencyText(
                                        a.precioFinal,
                                        prefix: AppLocalizations.of(
                                          context,
                                        )!.pricePrefix,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.tertiary,
                                        ),
                                      ),
                                    if (a.proximaFecha != null)
                                      Text(
                                        '${AppLocalizations.of(context)!.nextDatePrefix}${_formatDate(a.proximaFecha!)}',
                                      ),
                                    // Mostrar los nombres de los t?cnicos asignados.  Si
                                    // Mostrar los nombres de los técnicos asignados.  Si
                                    // alguno no se encuentra en la lista de usuarios,
                                    // se muestra su id como nombre.
                                    Builder(
                                      builder: (context) {
                                        final usuariosVM = context
                                            .read<UsuariosViewModel>();
                                        final nombresTecs = a.tecnicosAsignados
                                            .map((id) {
                                              final u = usuariosVM.usuarios
                                                  .firstWhere(
                                                    (user) => user.id == id,
                                                    orElse: () => Usuario(
                                                      id: '',
                                                      authUid: '',
                                                      nombre: id,
                                                      email: '',
                                                      idEmpresa: '',
                                                      perfilId: '',
                                                    ),
                                                  );
                                              return u.nombre;
                                            })
                                            .toList();
                                        return Text(
                                          '${t.techniciansLabel}: ${nombresTecs.join(', ')}',
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          tooltip: AppLocalizations.of(
                                            context,
                                          )!.editButton,
                                          onPressed: () {
                                            _showEditAssignmentDialog(a);
                                          },
                                        ),
                                        // Button to unassign (cancel) the assigned job.
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          tooltip: AppLocalizations.of(
                                            context,
                                          )!.unassignTooltip,
                                          onPressed: () async {
                                            final confirm = await showWorkiaBottomSheet<bool>(
                                              context: context,
                                              builder: (ctx) {
                                                final t = AppLocalizations.of(
                                                  ctx,
                                                )!;
                                                return Padding(
                                                  padding: const EdgeInsets.all(
                                                    16.0,
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      Text(
                                                        t.unassignTooltip,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleLarge
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      Text(
                                                        t.unassignConfirmation(
                                                          trabajo.titulo,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 24,
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: OutlinedButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    ctx,
                                                                    false,
                                                                  ),
                                                              style: OutlinedButton.styleFrom(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      vertical:
                                                                          16,
                                                                    ),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        12,
                                                                      ),
                                                                ),
                                                              ),
                                                              child: Text(
                                                                t.cancelButton,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          Expanded(
                                                            child: ElevatedButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    ctx,
                                                                    true,
                                                                  ),
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors.red,
                                                                foregroundColor:
                                                                    Colors
                                                                        .white,
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      vertical:
                                                                          16,
                                                                    ),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        12,
                                                                      ),
                                                                ),
                                                              ),
                                                              child: Text(
                                                                t.unassignTooltip,
                                                              ),
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
                                              if (!mounted) return;
                                              final asignadosVM = context
                                                  .read<
                                                    TrabajosAsignadosViewModel
                                                  >();
                                              await asignadosVM.cancelar(
                                                a.id,
                                                widget.empresaId,
                                                widget.userId,
                                              );
                                              await asignadosVM
                                                  .cargarTrabajosAsignados(
                                                    widget.empresaId,
                                                  );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.jobUnassignedSuccessfullyMessage,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DIALOGOS PARA NUEVA ASIGNACIÓN Y EDICIÓN (igual que tenías)
  // ---------------------------------------------------------------------------

  void _showAssignJobDialog() async {
    final trabajosVM = context.read<TrabajosViewModel>();
    final usuariosVM = context.read<UsuariosViewModel>();
    final asignadosVM = context.read<TrabajosAsignadosViewModel>();

    // Asegurarse de que la lista de trabajos esté cargada antes de mostrar
    // el diálogo.
    await trabajosVM.cargarTrabajos(widget.empresaId);
    await usuariosVM.cargarUsuarios(widget.empresaId);
    if (!mounted) return;

    List<Trabajo> trabajos = List<Trabajo>.from(trabajosVM.trabajos);
    trabajos = trabajos
        .where((t) => t.empresaId.isEmpty || t.empresaId == widget.empresaId)
        .toList();

    if (trabajos.isEmpty) {
      trabajos = List<Trabajo>.from(trabajosVM.trabajos);
    }

    final tecnicos = usuariosVM.usuarios
        .where(
          (u) => u.perfilId == 'PERF_TEC' && (u.idEmpresa == widget.empresaId),
        )
        .toList();

    // Obtener asignaciones actuales para preselección
    final currentAssignments = asignadosVM.trabajos
        .where((a) => a.clienteId == _currentClient.id && a.activo)
        .toList();
    final assignedJobIds = currentAssignments.map((a) => a.trabajoId).toSet();

    // Filtrar trabajos ya asignados para que no aparezcan en la lista
    trabajos = trabajos.where((t) => !assignedJobIds.contains(t.id)).toList();

    List<Trabajo> selectedJobs = [];

    DateTime? startDate;
    final selectedTechnicians = <String>{};
    final priceController = TextEditingController();

    // Variables para opciones cíclicas
    bool isCyclic = false;
    String frequency = 'mensual';

    await showWorkiaBottomSheet(
      context: context,
      builder: (dialogContext) {
        final t = AppLocalizations.of(dialogContext)!;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t.assignJobsDialogTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ],
                    ),
                    const Divider(),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Selección de trabajos (Multi)
                            DropdownSearch<Trabajo>.multiSelection(
                              items: (String? filter, LoadProps? props) =>
                                  trabajos,
                              itemAsString: (Trabajo t) => t.titulo,
                              selectedItems: selectedJobs,
                              popupProps: PopupPropsMultiSelection.menu(
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    labelText: t.searchJobsLabel,
                                  ),
                                ),
                              ),
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: t.jobsLabel,
                                ),
                              ),
                              compareFn: (item, selectedItem) =>
                                  item.id == selectedItem.id,
                              onChanged: (List<Trabajo> data) {
                                setStateDialog(() {
                                  selectedJobs = data;
                                  // Si se selecciona un solo trabajo y el precio está vacío,
                                  // sugerir el precio de ese trabajo.
                                  if (data.length == 1 &&
                                      priceController.text.isEmpty) {
                                    priceController.text = data.first.costo
                                        .toString();
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 12),

                            // Selección de técnicos
                            DropdownSearch<Usuario>.multiSelection(
                              items: (String? filter, LoadProps? props) =>
                                  tecnicos,
                              itemAsString: (Usuario u) => u.nombre,
                              selectedItems: tecnicos
                                  .where(
                                    (u) => selectedTechnicians.contains(u.id),
                                  )
                                  .toList(),
                              popupProps: const PopupPropsMultiSelection.menu(
                                showSearchBox: true,
                              ),
                              onChanged: (List<Usuario> selected) {
                                setStateDialog(() {
                                  selectedTechnicians
                                    ..clear()
                                    ..addAll(selected.map((u) => u.id));
                                });
                              },
                              compareFn: (Usuario? a, Usuario? b) =>
                                  (a == null || b == null)
                                  ? false
                                  : a.id == b.id,
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: t.techniciansLabel,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Campo de precio final
                            TextField(
                              controller: priceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: t.finalPriceOptionalLabel,
                                hintText: t.useBasePriceHint,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Opciones Cíclicas
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(t.recurringJobTitle),
                              value: isCyclic,
                              onChanged: (val) {
                                setStateDialog(() {
                                  isCyclic = val;
                                });
                              },
                            ),
                            if (isCyclic)
                              DropdownButtonFormField<String>(
                                value: frequency,
                                decoration: InputDecoration(
                                  labelText: t.frequencyLabel,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'mensual',
                                    child: Text(t.monthlyFrequency),
                                  ),
                                  DropdownMenuItem(
                                    value: 'trimestral',
                                    child: Text(t.quarterlyFrequency),
                                  ),
                                  DropdownMenuItem(
                                    value: 'semestral',
                                    child: Text(t.semiannualFrequency),
                                  ),
                                  DropdownMenuItem(
                                    value: 'anual',
                                    child: Text(t.annualFrequency),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setStateDialog(() {
                                      frequency = val;
                                    });
                                  }
                                },
                              ),
                            const SizedBox(height: 12),

                            // Selección de fecha única (Inicio)
                            ElevatedButton(
                              onPressed: () async {
                                final List<DateTime?> initialValues = [];
                                if (startDate != null) {
                                  initialValues.add(startDate);
                                }

                                final config =
                                    CalendarDatePicker2WithActionButtonsConfig(
                                      calendarType:
                                          CalendarDatePicker2Type.single,
                                    );

                                final results =
                                    await showCalendarDatePicker2Dialog(
                                      context: context,
                                      config: config,
                                      dialogSize: const Size(325, 400),
                                      value: initialValues,
                                    );

                                if (!context.mounted) return;

                                if (results != null && results.isNotEmpty) {
                                  setStateDialog(() {
                                    startDate = results[0];
                                  });
                                }
                              },
                              child: Text(
                                startDate != null
                                    ? '${t.startDateLabel} ${_formatDate(startDate!)}'
                                    : t.selectStartDateLabel,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(t.cancelButton),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (selectedJobs.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      t.selectJobAndDateRangeMessage,
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (startDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isCyclic
                                          ? t.selectStartDateError
                                          : t.selectDateRangeError,
                                    ),
                                  ),
                                );
                                return;
                              }

                              // Determinar precio manual si existe
                              double? manualPrice;
                              final txt = priceController.text.trim();
                              if (txt.isNotEmpty) {
                                manualPrice = double.tryParse(txt);
                              }

                              final inicio = DateTime(
                                startDate!.year,
                                startDate!.month,
                                startDate!.day,
                                12,
                              );
                              final fin = DateTime(
                                startDate!.year,
                                startDate!.month,
                                startDate!.day,
                                12,
                              );

                              DateTime? proxima;
                              if (isCyclic) {
                                switch (frequency) {
                                  case 'mensual':
                                    proxima = DateTime(
                                      inicio.year,
                                      inicio.month + 1,
                                      inicio.day,
                                      12,
                                    );
                                    break;
                                  case 'trimestral':
                                    proxima = DateTime(
                                      inicio.year,
                                      inicio.month + 3,
                                      inicio.day,
                                      12,
                                    );
                                    break;
                                  case 'semestral':
                                    proxima = DateTime(
                                      inicio.year,
                                      inicio.month + 6,
                                      inicio.day,
                                      12,
                                    );
                                    break;
                                  case 'anual':
                                    proxima = DateTime(
                                      inicio.year + 1,
                                      inicio.month,
                                      inicio.day,
                                      12,
                                    );
                                    break;
                                  default:
                                    proxima = DateTime(
                                      inicio.year,
                                      inicio.month + 1,
                                      inicio.day,
                                      12,
                                    );
                                }

                                if (!proxima.isAfter(fin)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'La frecuencia es menor a la duración del trabajo. Ajuste el rango de fechas o la frecuencia.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                              }

                              int addedCount = 0;

                              for (final job in selectedJobs) {
                                // Verificar si ya está asignado
                                if (assignedJobIds.contains(job.id)) {
                                  continue;
                                }

                                // Usar precio manual o el costo base del trabajo
                                final finalPrice = manualPrice ?? job.costo;

                                final nuevo = TrabajoAsignado(
                                  id: '',
                                  clienteId: _currentClient.id,
                                  trabajoId: job.id,
                                  tituloTrabajo: job.titulo,
                                  precioBase: job.costo,
                                  precioFinal: finalPrice,
                                  estado: 'En espera',
                                  fechaInicio: inicio,
                                  fechaFin: fin,
                                  proximaFecha: proxima,
                                  esCiclico: isCyclic,
                                  frecuenciaCiclico: isCyclic
                                      ? frequency
                                      : null,
                                  tecnicosAsignados: selectedTechnicians
                                      .toList(),
                                  empresaId: widget.empresaId,
                                  activo: true,
                                  fechaCreacion: DateTime.now(),
                                  fechaActualizacion: DateTime.now(),
                                  creadoPor: widget.userId,
                                  actualizadoPor: widget.userId,
                                );

                                await asignadosVM.agregar(nuevo);
                                addedCount++;
                              }

                              await asignadosVM.cargarTrabajosAsignados(
                                widget.empresaId,
                              );
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              // Show success message using localized text.
                              if (addedCount > 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.jobAssignedSuccessfullyMessage,
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.saveButton,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // End of main Column children
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditAssignmentDialog(TrabajoAsignado asignacion) async {
    final trabajosVM = context.read<TrabajosViewModel>();
    final usuariosVM = context.read<UsuariosViewModel>();
    final asignadosVM = context.read<TrabajosAsignadosViewModel>();

    // Cargar trabajos antes de mostrar el diálogo
    await trabajosVM.cargarTrabajos(widget.empresaId);
    await usuariosVM.cargarUsuarios(widget.empresaId);
    if (!mounted) return;

    List<Trabajo> trabajos = List<Trabajo>.from(trabajosVM.trabajos);
    trabajos = trabajos
        .where((t) => t.empresaId.isEmpty || t.empresaId == widget.empresaId)
        .toList();

    final tecnicos = usuariosVM.usuarios
        .where(
          (u) => u.perfilId == 'PERF_TEC' && (u.idEmpresa == widget.empresaId),
        )
        .toList();

    // Preseleccionar el trabajo actual (Single Selection)
    Trabajo? selectedTrabajo;
    try {
      selectedTrabajo = trabajos.firstWhere(
        (t) => t.id == asignacion.trabajoId,
      );
    } catch (_) {}

    DateTime? startDate = asignacion.fechaInicio;
    final selectedTechnicians = asignacion.tecnicosAsignados.toSet();
    final priceController = TextEditingController(
      text: asignacion.precioFinal.toString(),
    );

    // Variables para opciones cíclicas
    bool isCyclic = asignacion.esCiclico;
    String frequency = asignacion.frecuenciaCiclico ?? 'mensual';

    await showWorkiaBottomSheet(
      context: context,
      builder: (context) {
        final t = AppLocalizations.of(context)!;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t.editAssignmentTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Selección de trabajo (Single Selection)
                            DropdownSearch<Trabajo>(
                              items: (String? filter, LoadProps? props) =>
                                  trabajos,
                              itemAsString: (Trabajo t) => t.titulo,
                              selectedItem: selectedTrabajo,
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    labelText: t.searchJobLabel,
                                  ),
                                ),
                              ),
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: t.jobLabel,
                                ),
                              ),
                              compareFn: (item, selectedItem) =>
                                  item.id == selectedItem.id,
                              onChanged: (Trabajo? data) {
                                setStateDialog(() {
                                  selectedTrabajo = data;
                                  // Si se selecciona un trabajo y el precio está vacío,
                                  // sugerir el precio de ese trabajo.
                                  if (data != null &&
                                      priceController.text.isEmpty) {
                                    priceController.text = data.costo
                                        .toString();
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 12),

                            // Selección de técnicos (Mantiene Multi Selection)
                            DropdownSearch<Usuario>.multiSelection(
                              items: (String? filter, LoadProps? props) =>
                                  tecnicos,
                              itemAsString: (Usuario u) => u.nombre,
                              selectedItems: tecnicos
                                  .where(
                                    (u) => selectedTechnicians.contains(u.id),
                                  )
                                  .toList(),
                              popupProps: const PopupPropsMultiSelection.menu(
                                showSearchBox: true,
                              ),
                              onChanged: (List<Usuario> selected) {
                                setStateDialog(() {
                                  selectedTechnicians
                                    ..clear()
                                    ..addAll(selected.map((u) => u.id));
                                });
                              },
                              compareFn: (Usuario? a, Usuario? b) =>
                                  (a == null || b == null)
                                  ? false
                                  : a.id == b.id,
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: t.techniciansLabel,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Campo de precio final
                            TextField(
                              controller: priceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: t.finalPriceLabel,
                                hintText: t.useBasePriceHint,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Opciones Cíclicas
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(t.recurringJobTitle),
                              value: isCyclic,
                              onChanged: (val) {
                                setStateDialog(() {
                                  isCyclic = val;
                                });
                              },
                            ),
                            if (isCyclic)
                              DropdownButtonFormField<String>(
                                value: frequency,
                                decoration: InputDecoration(
                                  labelText: t.frequencyLabel,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'mensual',
                                    child: Text(t.monthlyFrequency),
                                  ),
                                  DropdownMenuItem(
                                    value: 'trimestral',
                                    child: Text(t.quarterlyFrequency),
                                  ),
                                  DropdownMenuItem(
                                    value: 'semestral',
                                    child: Text(t.semiannualFrequency),
                                  ),
                                  DropdownMenuItem(
                                    value: 'anual',
                                    child: Text(t.annualFrequency),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setStateDialog(() {
                                      frequency = val;
                                    });
                                  }
                                },
                              ),
                            const SizedBox(height: 12),

                            // Selección de fecha única (Inicio)
                            ElevatedButton(
                              onPressed: () async {
                                final List<DateTime?> initialValues = [];
                                if (startDate != null) {
                                  initialValues.add(startDate);
                                }

                                final config =
                                    CalendarDatePicker2WithActionButtonsConfig(
                                      calendarType:
                                          CalendarDatePicker2Type.single,
                                    );

                                final results =
                                    await showCalendarDatePicker2Dialog(
                                      context: context,
                                      config: config,
                                      dialogSize: const Size(325, 400),
                                      value: initialValues,
                                    );

                                if (!context.mounted) return;

                                if (results != null && results.isNotEmpty) {
                                  setStateDialog(() {
                                    startDate = results[0];
                                  });
                                }
                              },
                              child: Text(
                                startDate != null
                                    ? '${t.startDateLabel} ${_formatDate(startDate!)}'
                                    : t.selectStartDateLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(t.cancelButton),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (selectedTrabajo == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(t.mustSelectJobError)),
                                );
                                return;
                              }

                              if (startDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isCyclic
                                          ? t.selectStartDateError
                                          : t.selectDateRangeError,
                                    ),
                                  ),
                                );
                                return;
                              }

                              // Determinar precio manual si existe
                              double? manualPrice;
                              final txt = priceController.text.trim();
                              if (txt.isNotEmpty) {
                                manualPrice = double.tryParse(txt);
                              }

                              final inicio = DateTime(
                                startDate!.year,
                                startDate!.month,
                                startDate!.day,
                                12,
                              );
                              final fin = DateTime(
                                startDate!.year,
                                startDate!.month,
                                startDate!.day,
                                12,
                              );

                              DateTime? proxima;
                              if (isCyclic) {
                                switch (frequency) {
                                  case 'mensual':
                                    proxima = DateTime(
                                      inicio.year,
                                      inicio.month + 1,
                                      inicio.day,
                                      12,
                                    );
                                    break;
                                  case 'trimestral':
                                    proxima = DateTime(
                                      inicio.year,
                                      inicio.month + 3,
                                      inicio.day,
                                      12,
                                    );
                                    break;
                                  case 'semestral':
                                    proxima = DateTime(
                                      inicio.year,
                                      inicio.month + 6,
                                      inicio.day,
                                      12,
                                    );
                                    break;
                                  case 'anual':
                                    proxima = DateTime(
                                      inicio.year + 1,
                                      inicio.month,
                                      inicio.day,
                                      12,
                                    );
                                    break;
                                  default:
                                    proxima = DateTime(
                                      inicio.year,
                                      inicio.month + 1,
                                      inicio.day,
                                      12,
                                    );
                                }

                                if (!proxima.isAfter(fin)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'La frecuencia es menor a la duración del trabajo. Ajuste el rango de fechas o la frecuencia.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                              }

                              // ACTUALIZAR ASIGNACIÓN EXISTENTE
                              final actualizado = asignacion.copyWith(
                                trabajoId: selectedTrabajo!.id,
                                tituloTrabajo: selectedTrabajo!.titulo,
                                precioBase: selectedTrabajo!.costo,
                                precioFinal:
                                    manualPrice ?? selectedTrabajo!.costo,
                                fechaInicio: inicio,
                                fechaFin: fin,
                                proximaFecha: proxima,
                                esCiclico: isCyclic,
                                frecuenciaCiclico: isCyclic ? frequency : null,
                                tecnicosAsignados: selectedTechnicians.toList(),
                                empresaId: widget.empresaId,
                                actualizadoPor: widget.userId,
                                fechaActualizacion: DateTime.now(),
                              );

                              await asignadosVM.actualizar(actualizado);
                              await asignadosVM.cargarTrabajosAsignados(
                                widget.empresaId,
                              );

                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(t.assignmentUpdatedMessage),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(t.saveButton),
                          ),
                        ),
                      ],
                      // End of main Column children
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

  String _formatDate(DateTime date) {
    final locale = AppLocalizations.of(context)!.localeName;
    return DateFormat.yMd(locale).format(date);
  }
}
