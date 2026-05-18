import 'dart:async';
import 'package:workia/models/usuario.dart';

import 'package:provider/provider.dart';

import 'package:workia/models/job.dart';
// Importar el modelo de TrabajoAsignado para poder crear instancias de
// asignaciones y utilizarlas como tipo genÃ©rico en mapas y listas.
import 'package:workia/models/trabajo_asignado.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
// Importar ViewModel y modelos para gestionar actividades.
import 'package:workia/features/activities/presentation/viewmodels/actividades_viewmodel.dart';
import 'package:workia/presentation/viewmodels/sesiones_viewmodel.dart';

import 'package:workia/models/cliente.dart';
import 'package:workia/widgets/cliente_mini_map_section.dart';
import 'package:workia/views/jobs/job_form_page.dart';

import 'package:workia/l10n/app_localizations.dart';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';
import 'package:workia/views/jobs/job_activities_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workia/utils/ui_utils.dart';
import 'package:workia/widgets/tech_sessions_modal.dart';

class JobDetailPage extends StatefulWidget {
  const JobDetailPage({
    super.key,
    required this.job,
    required this.role,
    required this.userName,
  });

  final Trabajo job;
  final String role;
  final String userName;

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  // Variables para bÃºsqueda y filtro de clientes
  final TextEditingController _clientSearchController = TextEditingController();
  String _clientStatusFilter = 'Todos';
  bool _showClientFilters = false;
  DateTime? _clientFilterStartDate;
  DateTime? _clientFilterEndDate;
  final Map<String, Timer> _autoFinishTimers = {};

  @override
  void initState() {
    super.initState();
    // Cargar clientes y trabajos asignados para poder mostrar los
    // clientes asignados y filtrar actividades.  Se utiliza una
    // llamada postâ€‘frame para garantizar que el contexto estÃ©
    // disponible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final clientesVM = context.read<ClientesViewModel>();
      final asignadosVM = context.read<TrabajosAsignadosViewModel>();
      clientesVM.cargarClientes(widget.job.empresaId);
      asignadosVM.cargarTrabajosAsignados(widget.job.empresaId);
      // Cargar usuarios (tÃ©cnicos) para poder mostrar los nombres en la
      // pestaÃ±a de tÃ©cnicos.  Esto se hace sÃ³lo una vez al mostrar
      // el detalle para no recargar datos innecesarios en cada rebuild.
      final usuariosVM = context.read<UsuariosViewModel>();
      if (usuariosVM.usuarios.isEmpty) {
        usuariosVM.cargarUsuarios(widget.job.empresaId);
      }
    });
  }

  @override
  void dispose() {
    _clientSearchController.dispose();
    for (final timer in _autoFinishTimers.values) {
      timer.cancel();
    }
    _autoFinishTimers.clear();
    super.dispose();
  }

  void _ensureAutoFinishScheduled({
    required TrabajoAsignado assignment,
    required String tecnicoId,
    required SesionesViewModel sesionesVM,
    required TrabajosAsignadosViewModel asignadosVM,
  }) {
    final maxMinutes = assignment.tiempoIniciadoMin;
    if (maxMinutes == null || maxMinutes <= 0) return;

    final session = sesionesVM.getActiveSessionFor(tecnicoId);
    if (session == null) return;
    if (session.trabajoAsignadoId != assignment.id) return;
    if (session.fin != null) return;

    if (_autoFinishTimers.containsKey(session.id)) return;

    final endAt = session.inicio.add(Duration(minutes: maxMinutes));
    final remaining = endAt.difference(DateTime.now());

    Future<void> autoFinish() async {
      final active = sesionesVM.getActiveSessionFor(tecnicoId);
      if (active == null || active.id != session.id || active.fin != null) {
        _autoFinishTimers.remove(session.id)?.cancel();
        return;
      }

      // Requerimiento: NO cerrar sesiÃ³n automÃ¡ticamente.
      // Solo marcar el trabajo como FINALIZADO por tiempo (mientras el usuario estÃ¡ dentro).
      try {
        // Optimistic: reflejar en UI que ya finalizó este técnico.
        asignadosVM.actualizarEstadoLocal(
          assignment.id,
          'FINALIZADO',
          tecnicoIdConHoras: tecnicoId,
        );
        // Cerrar la sesión para registrar horas.
        await sesionesVM.finalizarSesion(session.id, assignment.id);
      } catch (_) {}
      _autoFinishTimers.remove(session.id)?.cancel();
    }

    if (remaining <= Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          autoFinish();
        }
      });
      return;
    }

    _autoFinishTimers[session.id] = Timer(remaining, () {
      if (mounted) {
        autoFinish();
      } else {
        _autoFinishTimers.remove(session.id)?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final job = widget.job;
    if (widget.role == 'PERF_TEC') {}
    return Scaffold(
      appBar: AppBar(
        title: Text(job.titulo),
        actions: [
          // Botón de edición visible solo para roles distintos de técnico.
          if (widget.role != 'PERF_TEC')
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: t.editJobTooltip,
              onPressed: () async {
                // Recargamos los trabajos asignados antes de navegar al formulario.
                final asignadosVM = context.read<TrabajosAsignadosViewModel>();
                await asignadosVM.cargarTrabajosAsignados(widget.job.empresaId);
                final trabajosVM = context.read<TrabajosViewModel>();
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => JobFormPage(job: job, role: widget.role),
                  ),
                );
                if (!mounted) return;
                // Después de volver del formulario, recargamos la lista de trabajos
                // para reflejar cualquier cambio realizado.
                await trabajosVM.cargarTrabajos(widget.job.empresaId);
                setState(() {});
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final clientesVM = context.read<ClientesViewModel>();
          final asignadosVM = context.read<TrabajosAsignadosViewModel>();
          await Future.wait([
            clientesVM.cargarClientes(widget.job.empresaId),
            asignadosVM.cargarTrabajosAsignados(widget.job.empresaId),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: _buildClientsTab(),
        ),
      ),
    );
  }

  /// Muestra un diÃ¡logo para asignar un cliente al trabajo o editar una asignaciÃ³n existente.
  /// [assignment] es la asignaciÃ³n a editar (null si es nueva).
  /// [preselectedClient] es el cliente a preseleccionar (Ãºtil si venimos de una tarjeta de cliente).
  Future<void> _showAssignClientDialog({
    TrabajoAsignado? assignment,
    Cliente? preselectedClient,
  }) async {
    final t = AppLocalizations.of(context)!;
    final clientesVM = context.read<ClientesViewModel>();
    final usuariosVM = context.read<UsuariosViewModel>();
    final asignadosVM = context.read<TrabajosAsignadosViewModel>();

    // Cargar datos necesarios
    await usuariosVM.cargarUsuarios(widget.job.empresaId);

    // Preparar listas de selecciÃ³n
    final clientes = clientesVM.clientes;
    final tecnicos = usuariosVM.usuarios
        .where((u) => u.perfilId == 'PERF_TEC')
        .toList();

    // Variables de estado
    List<Cliente> selectedClients = [];
    List<String> selectedTechIds = [];
    List<Cliente> availableClients = [];

    // Inicializar valores
    if (assignment != null) {
      // MODO EDICIÃ“N: Mostrar todos los clientes (o al menos el actual)
      availableClients = clientes;
      try {
        final client = clientes.firstWhere((c) => c.id == assignment.clienteId);
        selectedClients.add(client);
      } catch (_) {}
      selectedTechIds = List.from(assignment.tecnicosAsignados);
    } else {
      // MODO CREACIÃ“N: Filtrar clientes ya asignados
      final currentAssignments = asignadosVM.trabajos
          .where((a) => a.trabajoId == widget.job.id || a.id == widget.job.id)
          .toList();
      final assignedIds = currentAssignments.map((a) => a.clienteId).toSet();

      availableClients = clientes
          .where((c) => !assignedIds.contains(c.id))
          .toList();

      if (preselectedClient != null &&
          !assignedIds.contains(preselectedClient.id)) {
        selectedClients.add(preselectedClient);
      }
    }

    DateTime? startDate = assignment?.fechaInicio ?? DateTime.now();

    bool isCyclic = assignment?.esCiclico ?? false;
    String frequency = assignment?.frecuenciaCiclico ?? 'mensual';

    final priceController = TextEditingController(
      text: assignment?.precioFinal.toString() ?? '',
    );
    

    // Helper para formatear fecha
    String _formatDate(DateTime date) {
      return '${date.day}/${date.month}/${date.year}';
    }

    await showWorkiaBottomSheet(
      context: context,
      builder: (context) {
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
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t.manageAssignmentsTitle,
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
                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // SelecciÃ³n de Clientes
                            if (assignment == null)
                              // MODO CREACIÃ“N: Multi SelecciÃ³n
                              DropdownSearch<Cliente>.multiSelection(
                                items: (String? filter, LoadProps? props) =>
                                    availableClients,
                                itemAsString: (Cliente c) => c.nombre,
                                selectedItems: selectedClients,
                                popupProps: PopupPropsMultiSelection.menu(
                                  showSearchBox: true,
                                  searchFieldProps: TextFieldProps(
                                    decoration: InputDecoration(
                                      labelText: t.searchClientsLabel,
                                    ),
                                  ),
                                ),
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: t.clientsTab,
                                  ),
                                ),
                                compareFn: (item, selectedItem) =>
                                    item.id == selectedItem.id,
                                onChanged: (List<Cliente> data) {
                                  setStateDialog(() {
                                    selectedClients = data;
                                  });
                                },
                              )
                            else
                              // MODO EDICIÃ“N: SelecciÃ³n Simple
                              DropdownSearch<Cliente>(
                                items: (String? filter, LoadProps? props) =>
                                    availableClients,
                                itemAsString: (Cliente c) => c.nombre,
                                selectedItem: selectedClients.isNotEmpty
                                    ? selectedClients.first
                                    : null,
                                popupProps: PopupProps.menu(
                                  showSearchBox: true,
                                  searchFieldProps: TextFieldProps(
                                    decoration: InputDecoration(
                                      labelText: t.searchClientsLabel,
                                    ),
                                  ),
                                ),
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: t.clientsTab,
                                  ),
                                ),
                                compareFn: (item, selectedItem) =>
                                    item.id == selectedItem.id,
                                onChanged: (Cliente? data) {
                                  setStateDialog(() {
                                    selectedClients = data != null
                                        ? [data]
                                        : [];
                                  });
                                },
                              ),
                            const SizedBox(height: 12),
                            

                            // SelecciÃ³n de TÃ©cnicos (Multi Selection)
                            DropdownSearch<Usuario>.multiSelection(
                              items: (String? filter, LoadProps? props) =>
                                  tecnicos,
                              itemAsString: (Usuario u) => u.nombre,
                              selectedItems: tecnicos
                                  .where((t) => selectedTechIds.contains(t.id))
                                  .toList(),
                              popupProps: const PopupPropsMultiSelection.menu(
                                showSearchBox: true,
                              ),
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: t.selectTechniciansLabel,
                                ),
                              ),
                              compareFn: (item, selectedItem) =>
                                  item.id == selectedItem.id,
                              onChanged: (List<Usuario> data) {
                                setStateDialog(() {
                                  selectedTechIds = data
                                      .map((u) => u.id)
                                      .toList();
                                });
                              },
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
                                hintText: t.emptyForBasePriceHint,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Opciones CÃ­clicas
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(t.cyclicalJobLabel),
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

                            // SelecciÃ³n de fecha Ãºnica (Inicio)
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
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    // Actions
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
                              if (selectedClients.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      t.selectAtLeastOneClientError,
                                    ),
                                  ),
                                );
                                return;
                              }

                              // Validaciones de fecha
                              if (startDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isCyclic
                                          ? 'Seleccione una fecha de inicio'
                                          : 'Seleccione la fecha de trabajo',
                                    ),
                                  ),
                                );
                                return;
                              }

                              // Calcular fechas
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
                              }

                              // Determinar precio manual
                              double? manualPrice;
                              final txt = priceController.text.trim();
                              if (txt.isNotEmpty) {
                                manualPrice = double.tryParse(txt);
                              }

                              

                              int processedCount = 0;
                              final currentAssignments = asignadosVM.trabajos
                                  .where((a) => a.trabajoId == widget.job.id)
                                  .toList();

                              // Procesar asignaciones
                              for (final client in selectedClients) {
                                TrabajoAsignado? existingAssignment;
                                try {
                                  existingAssignment = currentAssignments
                                      .firstWhere(
                                        (a) => a.clienteId == client.id,
                                      );
                                } catch (_) {}

                                final finalPrice =
                                    manualPrice ?? widget.job.costo;

                                if (existingAssignment != null) {
                                  // Actualizar
                                  final updated = existingAssignment.copyWith(
                                    fechaInicio: inicio,
                                    fechaFin: fin,
                                    esCiclico: isCyclic,
                                    frecuenciaCiclico: isCyclic
                                        ? frequency
                                        : null,
                                    proximaFecha: proxima,
                                    tecnicosAsignados: selectedTechIds,
                                    precioFinal: finalPrice,
                                    
                                    fechaActualizacion: DateTime.now(),
                                    actualizadoPor: widget.userName,
                                  );
                                  await asignadosVM.actualizar(updated);
                                } else {
                                  // Crear nuevo
                                  final newAssignment = TrabajoAsignado(
                                    id: '',
                                    trabajoId: widget.job.id,
                                    tituloTrabajo: widget.job.titulo,
                                    precioBase: widget.job.costo,
                                    precioFinal: finalPrice,
                                    clienteId: client.id,
                                    estado: 'EN ESPERA',
                                    fechaInicio: inicio,
                                    fechaFin: fin,
                                    proximaFecha: proxima,
                                    esCiclico: isCyclic,
                                    frecuenciaCiclico: isCyclic
                                        ? frequency
                                        : null,
                                    tecnicosAsignados: selectedTechIds,
                                    empresaId: widget.job.empresaId,
                                    activo: true,
                                    fechaCreacion: DateTime.now(),
                                    fechaActualizacion: DateTime.now(),
                                    creadoPor: widget.userName,
                                    actualizadoPor: widget.userName,
                                    
                                  );
                                  await asignadosVM.agregar(newAssignment);
                                }
                                processedCount++;
                              }

                              if (mounted) {
                                Navigator.of(context).pop();
                                asignadosVM.cargarTrabajosAsignados(
                                  widget.job.empresaId,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      t.assignmentsProcessedMessage(
                                        processedCount,
                                      ),
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
                            child: Text(t.saveButton),
                          ),
                        ),
                      ],
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

  // ---------------------------------------------------------------------------
  // MAPA DEL TRABAJO (usa latitud / longitud del modelo Trabajo)
  // ---------------------------------------------------------------------------

  // Eliminado _buildMapSection: el detalle de mapa ha sido reemplazado por la secciÃ³n de clientes asignados.

  // ---------------------------------------------------------------------------
  // LISTA DE ACTIVIDADES
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // FORMULARIO PARA AGREGAR ACTIVIDAD
  // ---------------------------------------------------------------------------

  /// Muestra un diÃ¡logo para agregar una nueva actividad asociada
  /// al trabajo actual.  A diferencia de la implementaciÃ³n
  /// anterior, esta versiÃ³n delega el guardado en el
  /// [ActividadesViewModel], lo que asegura que se asignen los
  /// campos `empresaId`, `trabajoId` y `clienteId` correctamente.

  // ---------------------------------------------------------------------------
  // SECCIÃ“N DE CLIENTES ASIGNADOS
  // ---------------------------------------------------------------------------

  /// Construye la secciÃ³n que muestra la lista de clientes asignados al
  /// trabajo.  Utiliza el ViewModel de trabajos asignados para
  /// determinar quÃ© clientes estÃ¡n asociados a este trabajo y el
  /// ViewModel de clientes para obtener los datos completos de
  /// cada cliente.  Al tocar un cliente se despliega un modal con
  /// su informaciÃ³n y un miniâ€‘mapa.
  // PestaÃ±a de clientes.  Muestra la lista de clientes asignados al
  // trabajo.  Si el usuario tiene rol de tÃ©cnico sÃ³lo se muestran
  // los clientes de las asignaciones en las que participa ese tÃ©cnico.
  Widget _buildClientsTab() {
    final t = AppLocalizations.of(context)!;
    final asignadosVM = context.watch<TrabajosAsignadosViewModel>();
    final clientesVM = context.watch<ClientesViewModel>();
    final usuariosVM = context.watch<UsuariosViewModel>();
    // Obtener todas las asignaciones asociadas a este trabajo.
    var asignaciones = asignadosVM.trabajos.where((a) {
      final matchesId = a.trabajoId == widget.job.id || a.id == widget.job.id;
      final matchesTitle = a.tituloTrabajo == widget.job.titulo;
      return matchesId || matchesTitle;
    }).toList();
    // Si el usuario es tÃ©cnico, filtrar sÃ³lo aquellas asignaciones en las
    // que participa.
    String currentUserId = '';
    if (widget.role == 'PERF_TEC') {
      final currentUser = usuariosVM.usuarios.firstWhere(
        (u) => u.nombre == widget.userName,
        orElse: () => Usuario(
          id: '',
          authUid: '',
          nombre: widget.userName,
          email: '',
          idEmpresa: '',
          perfilId: '',
        ),
      );
      currentUserId = currentUser.id;
      if (currentUserId.isNotEmpty) {
        asignaciones = asignaciones
            .where((a) => a.tecnicosAsignados.contains(currentUserId))
            .toList();
      }
    }

    if (widget.role == 'PERF_TEC') {}

    // Determinar la mejor asignaciÃ³n (segÃºn estado) por cada cliente.
    final Map<String, TrabajoAsignado> bestByClient = {};
    final Map<String, int> rankingIndexByClient = {};

    int _indexOfStatus(String status) {
      final normalized = status.replaceAll('_', ' ').toLowerCase();
      switch (normalized) {
        case 'iniciado':
        case 'en progreso': // Legacy
          return 0;
        case 'en espera':
        case 'pendiente': // Legacy
          return 1;
        case 'finalizado':
        case 'completo': // Legacy
          return 2;
        case 'cerrado':
          return 3;
        case 'cancelado':
          return 4;
        default:
          return 5;
      }
    }

    for (final a in asignaciones) {
      final clientId = a.clienteId;
      final idx = _indexOfStatus(a.estado);
      if (!bestByClient.containsKey(clientId)) {
        bestByClient[clientId] = a;
        rankingIndexByClient[clientId] = idx;
      } else {
        final currentIdx = rankingIndexByClient[clientId]!;
        if (idx < currentIdx) {
          bestByClient[clientId] = a;
          rankingIndexByClient[clientId] = idx;
        }
      }
    }

    void _addCatalogClient(String id) {
      if (id.isEmpty) return;
      String resolvedId = id;
      try {
        final client = clientesVM.clientes.firstWhere(
          (c) => c.id == id || c.nombre == id,
        );
        resolvedId = client.id;
      } catch (_) {}

      if (!bestByClient.containsKey(resolvedId)) {
        bestByClient[resolvedId] = TrabajoAsignado(
          id: '',
          trabajoId: widget.job.id,
          tituloTrabajo: widget.job.titulo,
          precioBase: 0.0,
          precioFinal: 0.0,
          clienteId: resolvedId,
          estado: 'EN ESPERA',
          fechaInicio: DateTime.now(),
          fechaFin: DateTime.now(),
          proximaFecha: null,
          esCiclico: false,
          frecuenciaCiclico: null,
          tecnicosAsignados: const [],
          empresaId: widget.job.empresaId,
          activo: true,
          fechaCreacion: null,
          fechaActualizacion: null,
          creadoPor: '',
          actualizadoPor: '',
        );
        rankingIndexByClient[resolvedId] = _indexOfStatus('EN ESPERA');
      }
    }

    if (widget.job.clienteId.isNotEmpty &&
        !widget.job.clientesAsignados.contains(widget.job.clienteId)) {
      _addCatalogClient(widget.job.clienteId);
    }

    for (final c in widget.job.clientesAsignados) {
      _addCatalogClient(c);
    }

    final List<Map<String, dynamic>> items = [];
    bestByClient.forEach((clientId, assign) {
      final client = clientesVM.clientes.firstWhere(
        (c) => c.id == clientId || c.nombre == clientId,
        orElse: () => Cliente(
          id: clientId,
          nombre: clientId,
          razonSocial: '',
          personaContacto: '',
          telefono: '',
          correo: '',
          direccion: '',
        ),
      );
      items.add({'client': client, 'assignment': assign});
    });

    items.sort((a, b) {
      final ca =
          rankingIndexByClient[(a['assignment'] as TrabajoAsignado)
              .clienteId] ??
          4;
      final cb =
          rankingIndexByClient[(b['assignment'] as TrabajoAsignado)
              .clienteId] ??
          4;
      if (ca != cb) return ca.compareTo(cb);
      final c1 = (a['client'] as Cliente).nombre;
      final c2 = (b['client'] as Cliente).nombre;
      return c1.compareTo(c2);
    });

    // Aplicar filtros a la lista de items
    final query = _clientSearchController.text.trim().toLowerCase();
    final filteredItems = items.where((item) {
      final client = item['client'] as Cliente;
      final assign = item['assignment'] as TrabajoAsignado;

      // Filtro de texto (nombre del cliente)
      if (query.isNotEmpty && !client.nombre.toLowerCase().contains(query)) {
        return false;
      }

      // Filtro de estado
      if (_clientStatusFilter != 'Todos') {
        // Normalizar estado para comparaciÃ³n
        String assignStatus = assign.estado;
        if (assignStatus == 'En_progreso') assignStatus = 'En progreso';

        String filterStatus = _clientStatusFilter;
        if (filterStatus == 'En_progreso') filterStatus = 'En progreso';

        if (assignStatus.toLowerCase() != filterStatus.toLowerCase()) {
          return false;
        }
      }

      // Filtro de fecha
      if (_clientFilterStartDate != null && _clientFilterEndDate != null) {
        final start = DateTime(
          _clientFilterStartDate!.year,
          _clientFilterStartDate!.month,
          _clientFilterStartDate!.day,
        );
        final end = DateTime(
          _clientFilterEndDate!.year,
          _clientFilterEndDate!.month,
          _clientFilterEndDate!.day,
          23,
          59,
          59,
        );

        // Usar fechaInicio de la asignaciÃ³n
        if (assign.fechaInicio.isBefore(start) ||
            assign.fechaInicio.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Buscador y filtros
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _clientSearchController,
                decoration: InputDecoration(
                  labelText: t.searchClientLabel,
                  prefixIcon: Icon(Icons.search),

                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                _showClientFilters ? Icons.filter_alt_off : Icons.filter_alt,
              ),
              tooltip: _showClientFilters
                  ? t.hideFiltersTooltip
                  : t.showFiltersTooltip,
              onPressed: () {
                setState(() {
                  _showClientFilters = !_showClientFilters;
                });
              },
            ),
          ],
        ),

        // Panel de filtros
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1.0,
              child: child,
            );
          },
          child: _showClientFilters
              ? Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _clientStatusFilter,
                        decoration: InputDecoration(
                          labelText: t.statusLabel,

                          isDense: true,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Todos',
                            child: Text(t.allOption),
                          ),
                          DropdownMenuItem(
                            value: 'EN ESPERA',
                            child: Text(t.jobStatusOnHold),
                          ),
                          DropdownMenuItem(
                            value: 'INICIADO',
                            child: Text(t.jobStatusStarted),
                          ),
                          DropdownMenuItem(
                            value: 'FINALIZADO',
                            child: Text(t.jobStatusFinished),
                          ),
                          DropdownMenuItem(
                            value: 'CERRADO',
                            child: Text(t.jobStatusClosed),
                          ),
                          DropdownMenuItem(
                            value: 'CANCELADO',
                            child: Text(t.jobStatusCancelled),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _clientStatusFilter = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final results = await showCalendarDatePicker2Dialog(
                            context: context,
                            config: CalendarDatePicker2WithActionButtonsConfig(
                              calendarType: CalendarDatePicker2Type.range,
                            ),
                            dialogSize: const Size(325, 400),
                            value: [
                              _clientFilterStartDate,
                              _clientFilterEndDate,
                            ],
                          );
                          if (!mounted) return;
                          if (results != null && results.length >= 2) {
                            setState(() {
                              _clientFilterStartDate = results[0];
                              _clientFilterEndDate = results[1];
                            });
                          }
                        },
                        child: Text(
                          (_clientFilterStartDate != null &&
                                  _clientFilterEndDate != null)
                              ? '${t.rangeLabel}: ${_clientFilterStartDate!.day}/${_clientFilterStartDate!.month} - ${_clientFilterEndDate!.day}/${_clientFilterEndDate!.month}'
                              : t.selectDateRangeButton,
                        ),
                      ),
                      if (_clientFilterStartDate != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _clientFilterStartDate = null;
                              _clientFilterEndDate = null;
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

        if (widget.role != 'PERF_TEC') ...[
          ElevatedButton.icon(
            onPressed: () => _showAssignClientDialog(),
            icon: const Icon(Icons.person_add),
            label: Text(t.assignClientLabel),
          ),
          const SizedBox(height: 16),
        ],
        if (filteredItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              items.isEmpty
                  ? t.noClientsAssignedMessage
                  : t.noClientsFoundMessage,
            ),
          )
        else
          ...filteredItems.map((item) {
            final client = item['client'] as Cliente;
            final assignment = item['assignment'] as TrabajoAsignado;
            return JobClientCard(
              client: client,
              assignment: assignment,
              role: widget.role,
              job: widget.job,
              onShowInfo: _showClientInfoModal,
              onEditAssignment: (a) => _showAssignClientDialog(assignment: a),
            );
          }),
      ],
    );
  }

  /// Muestra un modal inferior con la informaciÃ³n detallada del
  /// [client], incluyendo un mini mapa si hay coordenadas
  /// disponibles.  Utiliza el widget [ClienteMiniMapSection] para
  /// mostrar la ubicaciÃ³n y presenta los datos bÃ¡sicos en un
  /// formato legible.
  /// Muestra un modal inferior con la informaciÃ³n detallada del
  /// [client], incluyendo un mini mapa si hay coordenadas
  /// disponibles.  Utiliza el widget [ClienteMiniMapSection] para
  /// mostrar la ubicaciÃ³n y presenta los datos bÃ¡sicos en un
  /// formato legible.

  void _showClientInfoModal(Cliente client) {
    // Obtener las asignaciones para este cliente en el contexto del
    // trabajo actual para determinar los tÃ©cnicos asignados.
    final asignadosVM = context.read<TrabajosAsignadosViewModel>();
    final usuariosVM = context.read<UsuariosViewModel>();
    // Filtrar asignaciones del trabajo y cliente seleccionados.
    final jobId = widget.job.id;
    final jobTitle = widget.job.titulo;
    final asigs = asignadosVM.trabajos.where((a) {
      final matchesJob =
          a.trabajoId == jobId || a.id == jobId || a.tituloTrabajo == jobTitle;
      return matchesJob && a.clienteId == client.id;
    }).toList();
    // Construir la lista de tÃ©cnicos a partir de las asignaciones.
    final Set<String> techIds = {};
    for (final a in asigs) {
      techIds.addAll(a.tecnicosAsignados);
    }
    final List<Usuario> techs = [];
    for (final id in techIds) {
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return PopScope(
          canPop: false,
          child: _ClientInfoModalContent(
            client: client,
            techs: techs,
            asigs: asigs,
          ),
        );
      },
    );
  }
}

class _ClientInfoModalContent extends StatefulWidget {
  final Cliente client;
  final List<Usuario> techs;
  final List<TrabajoAsignado> asigs;

  const _ClientInfoModalContent({
    required this.client,
    required this.techs,
    required this.asigs,
  });

  @override
  State<_ClientInfoModalContent> createState() =>
      _ClientInfoModalContentState();
}

class _ClientInfoModalContentState extends State<_ClientInfoModalContent> {
  Map<String, dynamic> _getConsolidatedHoursFromAsigs() {
    Map<String, dynamic> logs = {};
    for (var asig in widget.asigs) {
      if (asig.horasAcumuladas.isNotEmpty) {
        // Convertir value double a Map para que encaje con la estructura esperada por _TechnicianSearchList (si no la cambiamos)
        // OJO: _TechnicianSearchList espera logs['horas']
        asig.horasAcumuladas.forEach((userId, horas) {
          logs[userId] = {'horas': horas};
        });
      }
    }
    return logs;
  }

  Set<String> _selectedSegment = {'tecnicos'};

  @override
  void initState() {
    super.initState();
    // Inicializar ViewModel de Sesiones si hay asignaciÃ³n
    if (widget.asigs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SesionesViewModel>().init(widget.asigs.first.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.client.nombre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

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
                      if (widget.client.razonSocial.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.business_outlined,
                                size: 16,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.client.razonSocial,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (widget.client.personaContacto.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 16,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.client.personaContacto,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (widget.client.correo.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.email_outlined,
                                size: 16,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.client.correo,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (widget.client.telefono.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 16,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.client.telefono,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (widget.client.direccion.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.client.direccion,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),

                      // Mostrar fechas de la asignaciÃ³n si existen
                      if (widget.asigs.isNotEmpty) ...[
                        Builder(
                          builder: (context) {
                            final assign = widget.asigs.first;
                            final start = assign.fechaInicio;
                            final next = assign.proximaFecha;

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
                                        const Icon(
                                          Icons.event_repeat,
                                          size: 16,
                                          color: Colors.black54,
                                        ),
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
                          },
                        ),
                      ],

                      // Segmented Button
                      Center(
                        child: SegmentedButton<String>(
                          segments: [
                            ButtonSegment<String>(
                              value: 'tecnicos',
                              label: Text(t.techniciansLabel),
                              icon: Icon(Icons.people),
                            ),
                            ButtonSegment<String>(
                              value: 'mapa',
                              label: Text(t.mapTabLabel),
                              icon: Icon(Icons.map),
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

                      // Contenido basado en la selecciÃ³n
                      if (_selectedSegment.contains('tecnicos')) ...[
                        Text(
                          t.assignedTechniciansLabel,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        // Pasar el mapa de ejecuciones para mostrar horas
                        _TechnicianSearchList(
                          techs: widget.techs,
                          executionLogs: _getConsolidatedHoursFromAsigs(),
                          currentUserId: context
                              .read<UserSessionProvider>()
                              .userId,
                          userRole: context
                              .read<UserSessionProvider>()
                              .userRole,
                          trabajoAsignadoId: widget.asigs.first.id,
                          empresaId: context
                              .read<UserSessionProvider>()
                              .empresaId,
                          onViewActivities: (tech) {
                            // Buscar la asignaciÃ³n correspondiente
                            TrabajoAsignado? assignment;
                            try {
                              assignment = widget.asigs.firstWhere(
                                (a) => a.tecnicosAsignados.contains(tech.id),
                              );
                            } catch (_) {}

                            if (assignment != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => JobActivitiesPage(
                                    asignacion: assignment!,
                                    tituloTrabajo: assignment.tituloTrabajo,
                                    role: context
                                        .read<UserSessionProvider>()
                                        .userRole,
                                    userId: context
                                        .read<UserSessionProvider>()
                                        .userId,
                                    technicianId: tech.id,
                                    technicianName: tech.nombre,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.noTechniciansAssignedMessage,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ] else ...[
                        // Enlace a Google Maps
                        if (widget.client.lat != null &&
                            widget.client.lng != null &&
                            (widget.client.lat != 0 || widget.client.lng != 0))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: InkWell(
                              onTap: () async {
                                final uri = Uri.parse(
                                  'https://www.google.com/maps/search/?api=1&query=${widget.client.lat},${widget.client.lng}',
                                );
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.map, size: 20),
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
                        // Mapa sin Card
                        ClienteMiniMapSection(
                          clienteId: widget.client.id,
                          useCard: false,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechnicianSearchList extends StatefulWidget {
  final List<Usuario> techs;
  final Map<String, dynamic> executionLogs;
  final Function(Usuario)? onViewActivities;
  final String currentUserId;
  final String userRole;
  final String trabajoAsignadoId;
  final String empresaId;

  const _TechnicianSearchList({
    required this.techs,
    this.executionLogs = const {},
    this.onViewActivities,
    required this.currentUserId,
    required this.userRole,
    required this.trabajoAsignadoId,
    required this.empresaId,
  });

  @override
  State<_TechnicianSearchList> createState() => _TechnicianSearchListState();
}

class _TechnicianSearchListState extends State<_TechnicianSearchList> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final filteredTechs = widget.techs
        .where((u) => u.nombre.toLowerCase().contains(search.toLowerCase()))
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
          onChanged: (val) {
            setState(() {
              search = val;
            });
          },
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
                  // Mostrar botÃ³n de actividades SOLO si tengo permisos
                  trailing: null,
                ),
              ),
            );
          }),
      ],
    );
  }
}

class JobClientCard extends StatelessWidget {
  final Cliente client;
  final TrabajoAsignado assignment;
  final String role;
  final Trabajo job;
  final Function(Cliente) onShowInfo;
  final Function(TrabajoAsignado) onEditAssignment;

  static final Map<String, Timer> _autoFinishTimers = {};
  static final Map<String, Timer> _autoAdvanceTimers = {};

  const JobClientCard({
    super.key,
    required this.client,
    required this.assignment,
    required this.role,
    required this.job,
    required this.onShowInfo,
    required this.onEditAssignment,
  });

  void _ensureAutoFinishScheduled({
    required TrabajoAsignado assignment,
    required String tecnicoId,
    required SesionesViewModel sesionesVM,
    required TrabajosAsignadosViewModel asignadosVM,
  }) {
    final maxMinutes = assignment.tiempoIniciadoMin;
    if (maxMinutes == null || maxMinutes <= 0) return;

    final session = sesionesVM.getActiveSessionFor(tecnicoId);
    if (session == null) return;
    if (session.trabajoAsignadoId != assignment.id) return;
    if (session.fin != null) return;

    if (_autoFinishTimers.containsKey(session.id)) return;

    final endAt = session.inicio.add(Duration(minutes: maxMinutes));
    final remaining = endAt.difference(DateTime.now());

    Future<void> autoFinish() async {
      final active = sesionesVM.getActiveSessionFor(tecnicoId);
      if (active == null || active.id != session.id || active.fin != null) {
        _autoFinishTimers.remove(session.id)?.cancel();
        return;
      }

      // Requerimiento: NO cerrar sesiÃ³n automÃ¡ticamente.
      // Solo marcar el trabajo como FINALIZADO por tiempo (mientras el usuario estÃ¡ dentro).
      try {
        asignadosVM.actualizarEstadoLocal(
          assignment.id,
          'FINALIZADO',
          tecnicoIdConHoras: tecnicoId,
        );
        await sesionesVM.finalizarSesion(session.id, assignment.id);
      } catch (_) {}
      _autoFinishTimers.remove(session.id)?.cancel();
    }

    if (remaining <= Duration.zero) {
      // No usar context aquÃ­; puede que el widget ya no exista.
      scheduleMicrotask(() {
        autoFinish();
      });
      return;
    }

    _autoFinishTimers[session.id] = Timer(remaining, () {
      autoFinish();
    });
  }

  void _ensureAutoAdvanceEnEsperaToIniciadoScheduled({
    required TrabajoAsignado assignment,
    required TrabajosAsignadosViewModel asignadosVM,
  }) {
    if (role != 'PERF_ADMIN') return;
    if (assignment.estado != 'EN ESPERA') return;

    final minutes = assignment.tiempoEnEsperaMin;
    if (minutes == null || minutes <= 0) return;

    final startAt =
        assignment.fechaActualizacion ?? assignment.fechaInicio ?? DateTime.now();
    final endAt = startAt.add(Duration(minutes: minutes));
    final remaining = endAt.difference(DateTime.now());

    final timerKey = '${assignment.id}__EN_ESPERA';
    if (_autoAdvanceTimers.containsKey(timerKey)) return;

    Future<void> advance() async {
      final current = asignadosVM.trabajos.where((a) => a.id == assignment.id);
      if (current.isEmpty) {
        _autoAdvanceTimers.remove(timerKey)?.cancel();
        return;
      }

      final latest = current.first;
      if (latest.estado != 'EN ESPERA') {
        _autoAdvanceTimers.remove(timerKey)?.cancel();
        return;
      }

      final updated = latest.copyWith(
        estado: 'INICIADO',
        fechaActualizacion: DateTime.now(),
      );
      await asignadosVM.actualizar(updated);
      _autoAdvanceTimers.remove(timerKey)?.cancel();
    }

    if (remaining <= Duration.zero) {
      scheduleMicrotask(() {
        advance();
      });
      return;
    }

    _autoAdvanceTimers[timerKey] = Timer(remaining, () {
      advance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (role == 'PERF_ADMIN') {
      _ensureAutoAdvanceEnEsperaToIniciadoScheduled(
        assignment: assignment,
        asignadosVM: context.read<TrabajosAsignadosViewModel>(),
      );
    }

    String timeLabelFor(String status) {
      int? minutes;
      switch (status) {
        case 'EN ESPERA':
          minutes = assignment.tiempoEnEsperaMin;
          break;
        case 'INICIADO':
          minutes = assignment.tiempoIniciadoMin;
          break;
        default:
          minutes = null;
          break;
      }
      if (minutes == null || minutes <= 0) return '';
      final h = minutes ~/ 60;
      final m = minutes % 60;
      if (h > 0 && m > 0) return '${h}h ${m}m';
      if (h > 0) return '${h}h';
      return '${m}m';
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => onShowInfo(client),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                    if (assignment.esCiclico)
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
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 1,
                              ),
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
                          ),
                        ),
                      ),
                    if (client.telefono.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 14,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            client.telefono,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '//',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    if (assignment.proximaFecha != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.event_repeat,
                            size: 14,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ' //',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (role == 'PERF_TEC')
                _buildTechnicianStatusAction(context)
              else
                PopupMenuButton<String>(
                  onSelected: (String newStatus) {
                    // Para EN ESPERA e INICIADO: siempre abrir editor de tiempo
                    // y opcionalmente permitir cambiar fase (sin cambiar de una).
                    if (role == 'PERF_ADMIN' &&
                        (newStatus == 'EN ESPERA' || newStatus == 'INICIADO')) {
                      _showTimeOrChangeStatusDialog(context, newStatus);
                      return;
                    }
                    if (newStatus != assignment.estado) {
                      final updatedAssignment = assignment.copyWith(
                        estado: newStatus,
                      );
                      context.read<TrabajosAsignadosViewModel>().actualizar(
                        updatedAssignment,
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'EN ESPERA',
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.jobStatusOnHold,
                                  style: TextStyle(
                                    color: _getStatusColor(
                                      context,
                                      'EN ESPERA',
                                    ),
                                  ),
                                ),
                              ),
                              if (timeLabelFor('EN ESPERA').isNotEmpty)
                                Text(
                                  timeLabelFor('EN ESPERA'),
                                  style: const TextStyle(
                                    color: Colors.black45,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'INICIADO',
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.jobStatusStarted,
                                  style: TextStyle(
                                    color: _getStatusColor(
                                      context,
                                      'INICIADO',
                                    ),
                                  ),
                                ),
                              ),
                              if (timeLabelFor('INICIADO').isNotEmpty)
                                Text(
                                  timeLabelFor('INICIADO'),
                                  style: const TextStyle(
                                    color: Colors.black45,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'FINALIZADO',
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.jobStatusFinished,
                                  style: TextStyle(
                                    color: _getStatusColor(
                                      context,
                                      'FINALIZADO',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'CERRADO',
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.jobStatusClosed,
                                  style: TextStyle(
                                    color: _getStatusColor(
                                      context,
                                      'CERRADO',
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                ),
              const SizedBox(width: 8),
              if (role != 'PERF_TEC')
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => onEditAssignment(assignment),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTimeForStatusDialog(
    BuildContext context,
    String status,
  ) async {
    if (role != 'PERF_ADMIN') return;
    if (status != 'EN ESPERA' && status != 'INICIADO') return;

    int? currentMinutes;
    switch (status) {
      case 'EN ESPERA':
        currentMinutes = assignment.tiempoEnEsperaMin;
        break;
      case 'INICIADO':
        currentMinutes = assignment.tiempoIniciadoMin ??
            (assignment.autoFinalizarHoras != null
                ? (assignment.autoFinalizarHoras! * 60)
                : null);
        break;
    }

    final hoursController = TextEditingController(
      text: currentMinutes != null ? (currentMinutes ~/ 60).toString() : '',
    );
    final minutesController = TextEditingController(
      text: currentMinutes != null ? (currentMinutes % 60).toString() : '',
    );

    final updatedMinutes = await showWorkiaBottomSheet<int?>(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tiempo: $status',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: hoursController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Horas',
                        hintText: 'Ej: 1',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: minutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minutos',
                        hintText: 'Ej: 30',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  final rawH = hoursController.text.trim();
                  final rawM = minutesController.text.trim();
                  final h = rawH.isEmpty ? 0 : (int.tryParse(rawH) ?? 0);
                  final m = rawM.isEmpty ? 0 : (int.tryParse(rawM) ?? 0);

                  final total = (h * 60) + m;
                  if (total <= 0) return Navigator.pop(ctx, null);
                  Navigator.pop(ctx, total);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        );
      },
    );

    if (updatedMinutes == null) return;

    TrabajoAsignado updated;
    switch (status) {
      case 'EN ESPERA':
        updated = assignment.copyWith(
          tiempoEnEsperaMin: updatedMinutes,
          fechaActualizacion: DateTime.now(),
        );
        break;
      case 'INICIADO':
        updated = assignment.copyWith(
          tiempoIniciadoMin: updatedMinutes,
          fechaActualizacion: DateTime.now(),
        );
        break;
      default:
        return;
    }

    await context.read<TrabajosAsignadosViewModel>().actualizar(updated);
  }

  Future<void> _showTimeOrChangeStatusDialog(
    BuildContext context,
    String status,
  ) async {
    if (role != 'PERF_ADMIN') return;
    if (status != 'EN ESPERA' && status != 'INICIADO') return;

    int? currentMinutes;
    if (status == 'EN ESPERA') {
      currentMinutes = assignment.tiempoEnEsperaMin;
    } else if (status == 'INICIADO') {
      currentMinutes = assignment.tiempoIniciadoMin ??
          (assignment.autoFinalizarHoras != null
              ? (assignment.autoFinalizarHoras! * 60)
              : null);
    }

    final hoursController = TextEditingController(
      text: currentMinutes != null ? (currentMinutes ~/ 60).toString() : '',
    );
    final minutesController = TextEditingController(
      text: currentMinutes != null ? (currentMinutes % 60).toString() : '',
    );

    final result = await showWorkiaBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tiempo: $status',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: hoursController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Horas',
                        hintText: 'Ej: 1',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: minutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minutos',
                        hintText: 'Ej: 30',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final rawH = hoursController.text.trim();
                        final rawM = minutesController.text.trim();
                        final h = rawH.isEmpty ? 0 : (int.tryParse(rawH) ?? 0);
                        final m = rawM.isEmpty ? 0 : (int.tryParse(rawM) ?? 0);
                        final total = (h * 60) + m;
                        if (total <= 0) return Navigator.pop(ctx);
                        Navigator.pop(ctx, {'action': 'save', 'minutes': total});
                      },
                      child: const Text('Guardar tiempo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final rawH = hoursController.text.trim();
                        final rawM = minutesController.text.trim();
                        final h = rawH.isEmpty ? 0 : (int.tryParse(rawH) ?? 0);
                        final m = rawM.isEmpty ? 0 : (int.tryParse(rawM) ?? 0);
                        final total = (h * 60) + m;
                        Navigator.pop(ctx, {
                          'action': 'change',
                          'minutes': total > 0 ? total : null,
                        });
                      },
                      child: Text('Cambiar a $status'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;
    final action = result['action'] as String?;
    final minutes = result['minutes'] as int?;

    final asignadosVM = context.read<TrabajosAsignadosViewModel>();
    final current = asignadosVM.trabajos.where((a) => a.id == assignment.id);
    final latest = current.isNotEmpty ? current.first : assignment;

    TrabajoAsignado updated = latest;
    if (minutes != null && minutes > 0) {
      if (status == 'EN ESPERA') {
        updated = updated.copyWith(
          tiempoEnEsperaMin: minutes,
          fechaActualizacion: DateTime.now(),
        );
      } else if (status == 'INICIADO') {
        updated = updated.copyWith(
          tiempoIniciadoMin: minutes,
          fechaActualizacion: DateTime.now(),
        );
      }
    }

    if (action == 'change') {
      updated = updated.copyWith(
        estado: status,
        fechaActualizacion: DateTime.now(),
      );
    }

    if (updated != latest) {
      await asignadosVM.actualizar(updated);
    }
  }

  Widget _buildTechnicianStatusAction(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    // HERE IS THE FIX: context.watch is now isolated to this widget
    final sesionesVM = context.watch<SesionesViewModel>();
    final userProvider = context.read<UserSessionProvider>();
    final userId = userProvider.userId;
    // Verificar si hay sesión activa para este usuario
    final isSessionActive = sesionesVM.isSessionActiveFor(userId);
    // Verificar si el usuario está asignado a este trabajo
    final isAssigned = assignment.tecnicosAsignados.contains(userId);
    if (!isAssigned) return const SizedBox.shrink();

    final normalized = assignment.estado.replaceAll('_', ' ').toLowerCase();

    if (normalized != 'iniciado' && !isSessionActive) {
      return _buildStatusBadge(context, assignment.estado);
    }

    if (normalized == 'cerrado' || normalized == 'finalizado') {
      if (!isSessionActive) {
        return _buildStatusBadge(context, assignment.estado);
      }
    }

    // Si llego aquí: O está INICIADO, o tengo una sesión activa que debo cerrar.
    if (normalized == 'cerrado') {
      return _buildStatusBadge(context, assignment.estado);
    }

    // NUEVO REQUERIMIENTO: Si el técnico ya tiene horas registradas (ya finalizó)
    // ya no puede volver a iniciarlo. Usamos tanto horasAcumuladas (persistido)
    // como la lista de sesiones actual (actualización optimista) para reaccionar al instante.
    final hasFinishedPersisted = assignment.horasAcumuladas.containsKey(userId);
    final hasFinishedOptimistic = sesionesVM.sesiones.any((s) => s.tecnicoId == userId && s.fin != null);
    final hasFinished = hasFinishedPersisted || hasFinishedOptimistic;

    if (hasFinished && !isSessionActive) {
      return _buildStatusBadge(context, 'FINALIZADO');
    }

    if (isSessionActive) {
      _ensureAutoFinishScheduled(
        assignment: assignment,
        tecnicoId: userId,
        sesionesVM: sesionesVM,
        asignadosVM: context.read<TrabajosAsignadosViewModel>(),
      );
      return ElevatedButton.icon(
        onPressed: () async {
          final session = sesionesVM.getActiveSessionFor(userId);
          if (session != null) {
            // OPTIMISTIC UPDATE: Localmente marcar como finalizado para que la agenda y UI reaccionen al instante
            context.read<TrabajosAsignadosViewModel>().actualizarEstadoLocal(assignment.id, 'FINALIZADO', tecnicoIdConHoras: userId);

            await sesionesVM.finalizarSesion(session.id, assignment.id);
            if (context.mounted) {
              context.read<TrabajosAsignadosViewModel>().cargarTrabajosAsignados(assignment.empresaId);
            }
          }
        },
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
        onPressed: () async {
          final lat = job.latitud;
          final lng = job.longitud;

          if (lat != null && lng != null && lat != 0 && lng != 0) {
            bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
            if (!serviceEnabled) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor activa el GPS')),
                );
              }
              return;
            }

            LocationPermission permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied) {
              permission = await Geolocator.requestPermission();
              if (permission == LocationPermission.denied) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Permiso de ubicación denegado'),
                    ),
                  );
                }
                return;
              }
            }

            if (permission == LocationPermission.deniedForever) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Permisos de ubicación denegados permanentemente',
                    ),
                  ),
                );
              }
              return;
            }

            final position = await Geolocator.getCurrentPosition();
            final distance = Geolocator.distanceBetween(
              lat,
              lng,
              position.latitude,
              position.longitude,
            );

            const double maxDistance = 200;
            if (distance > maxDistance) {
              if (context.mounted) {
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Estás a  metros del trabajo. Debes estar a menos de m.',
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
              }
              return;
            }
          }

          // OPTIMISTIC UPDATE: Localmente marcar como iniciado
          if (context.mounted) {
            context.read<TrabajosAsignadosViewModel>().actualizarEstadoLocal(assignment.id, 'INICIADO');
          }

          await sesionesVM.iniciarSesion(
            assignment.id,
            userId,
            assignment.trabajoId,
            job.empresaId,
          );

          // Auto-finalizar si el admin configurÃ³ un tiempo para INICIADO.
          _ensureAutoFinishScheduled(
            assignment: assignment,
            tecnicoId: userId,
            sesionesVM: sesionesVM,
            asignadosVM: context.read<TrabajosAsignadosViewModel>(),
          );
          if (context.mounted) {
            context.read<TrabajosAsignadosViewModel>().cargarTrabajosAsignados(job.empresaId);
          }
        },
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

  Widget _buildStatusBadge(BuildContext context, String status) {
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
