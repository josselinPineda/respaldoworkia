import 'package:flutter/material.dart';
import 'package:workia/utils/ui_utils.dart';

import 'package:workia/views/settings/user_settings_page.dart';
import 'package:workia/models/job.dart';
import 'package:workia/models/trabajo_asignado.dart';
import 'package:workia/models/cliente.dart';
import 'package:provider/provider.dart';
import 'package:workia/views/jobs/job_form_page.dart';
import 'package:workia/views/jobs/job_detail_page.dart';

import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/views/problems/problems_page.dart';
import 'package:workia/models/usuario.dart';
import 'package:workia/presentation/viewmodels/empresa_viewmodel.dart';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/widgets/currency_text.dart';

class MisTrabajosPage extends StatefulWidget {
  const MisTrabajosPage({
    super.key,
    required this.userName,
    required this.role,
    required this.userId,
    required this.empresaId,
  });

  final String userName;
  final String role;
  final String userId;
  final String empresaId;

  @override
  State<MisTrabajosPage> createState() => _MisTrabajosPageState();
}

class _MisTrabajosPageState extends State<MisTrabajosPage> {
  final TextEditingController _searchController = TextEditingController();

  // ----------------- CAMPOS DE FILTRO -----------------
  // El filtro de estado ha sido eliminado.  La lista de trabajos se
  // llena únicamente con los trabajos creados en el catálogo, por lo
  // que ya no se filtra por el estado consolidado.  Se mantienen
  // filtros de cliente y técnico.
  // Track the selected filter values.  These default to the localized
  // "all" option but are initialized with the Spanish string so that
  // existing persisted values still compare correctly.  When the
  // language changes, the current value will be compared against the
  // translated label as well.
  String _filtroCliente = 'Todos';
  String _filtroTecnico = 'Todos';
  // Indica si los filtros están visibles debajo de la barra de búsqueda.
  bool _filtrosVisibles = false;
  // ----------------------------------------------------

  /// Construye el panel de filtros para la página "Mis trabajos".
  /// Este panel incluye desplegables para seleccionar estado,
  /// cliente y técnico.  Se utiliza dentro de un AnimatedSwitcher
  /// para animar su aparición y desaparición.  El parámetro
  /// [estadosOpc], [clientesOpc] y [tecnicosOpc] deben incluir la
  /// opción 'Todos' como primera entrada.
  Widget _buildFilterPanel(List<String> clientesOpc, List<String> tecnicosOpc) {
    // Panel de filtros que permite seleccionar cliente y técnico.  El
    // filtro de estado ha sido eliminado, por lo que sólo se
    // muestran dos desplegables.  La opción 'Todos' se pasa como
    // primer elemento en las listas proporcionadas.
    final t = AppLocalizations.of(context)!;
    final allOption = t.allOption;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownSearch<String>(
                items: (String filter, LoadProps? loadProps) => clientesOpc,
                // When the filter is the "all" option we show the hint rather than a selected value.
                selectedItem:
                    (_filtroCliente == 'Todos' || _filtroCliente == allOption)
                    ? null
                    : _filtroCliente,
                decoratorProps: DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: t.clientLabel,
                    isDense: true,
                  ),
                ),
                popupProps: const PopupProps.menu(showSearchBox: true),
                onChanged: (String? value) {
                  setState(() {
                    // Store the translated value when available; fall back to the Spanish default.
                    _filtroCliente = value ?? allOption;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownSearch<String>(
                items: (String filter, LoadProps? loadProps) => tecnicosOpc,
                selectedItem:
                    (_filtroTecnico == 'Todos' || _filtroTecnico == allOption)
                    ? null
                    : _filtroTecnico,
                decoratorProps: DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: t.technicianLabel,
                    isDense: true,
                  ),
                ),
                popupProps: const PopupProps.menu(showSearchBox: true),
                onChanged: (String? value) {
                  setState(() {
                    _filtroTecnico = value ?? allOption;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Combina los trabajos del catálogo con sus asignaciones para
  /// construir una lista que incluya todos los trabajos creados,
  /// incluso aquellos sin asignaciones.  Las asignaciones se
  /// utilizan para determinar un estado consolidado y las listas de
  /// clientes y técnicos asociados.  Si un trabajo no tiene
  /// asignaciones, se conserva el estado del catálogo (si existe) o
  /// se marca como 'Pendiente'.  Las listas de clientes y
  /// técnicos se construyen usando los nombres obtenidos a partir
  /// de los IDs en los view models de clientes y usuarios.
  List<Trabajo> _mergeJobsWithAssignments(
    List<Trabajo> catalogo,
    List<TrabajoAsignado> asignaciones,
  ) {
    final clientesVM = context.read<ClientesViewModel>();
    final usuariosVM = context.read<UsuariosViewModel>();
    final List<Trabajo> result = [];
    // Definir la prioridad de los estados para consolidar múltiples
    // asignaciones en un único estado.  Índice menor = mayor prioridad.
    final List<String> statusOrder = [
      'iniciado',
      'en progreso', // Legacy support
      'en espera',
      'pendiente', // Legacy
      'finalizado',
      'completo', // Legacy
      'cerrado',
    ];
    for (final job in catalogo) {
      // Obtener asignaciones de este trabajo
      final jobAssignments = asignaciones
          .where((a) => a.trabajoId == job.id && a.activo)
          .toList();
      // Determinar el estado consolidado.  Si no hay asignaciones
      // utilizar el estado del catálogo o 'En espera'.
      String consolidatedState = job.estado.isNotEmpty
          ? job.estado.replaceAll('_', ' ')
          : 'En espera';

      if (jobAssignments.isNotEmpty) {
        int bestIndex = statusOrder.length;
        for (final a in jobAssignments) {
          final s = a.estado.replaceAll('_', ' ').toLowerCase();
          // Normalización rápida local
          String normalized = s;
          if (s == 'pendiente') normalized = 'en espera';
          if (s == 'completo' || s == 'completado') normalized = 'finalizado';

          final idx = statusOrder.indexWhere((e) => e == normalized);
          final index = idx == -1 ? statusOrder.length : idx;
          if (index < bestIndex) {
            bestIndex = index;
            // Guardamos el estado "bonito" (capitalized) basado en el normalizado
            if (normalized == 'en espera')
              consolidatedState = 'En espera';
            else if (normalized == 'iniciado')
              consolidatedState = 'Iniciado';
            else if (normalized == 'finalizado')
              consolidatedState = 'Finalizado';
            else
              consolidatedState = a.estado.replaceAll('_', ' ');
          }
        }
      }
      // Construir lista de clientes asignados
      final Set<String> clientNames = <String>{};
      // Incluir cliente principal del trabajo si no está vacío
      if (job.cliente.isNotEmpty) {
        clientNames.add(job.cliente);
      }
      // Recorrer asignaciones para obtener nombres de clientes
      for (final a in jobAssignments) {
        if (a.clienteId.isNotEmpty) {
          final client = clientesVM.clientes.firstWhere(
            (c) => c.id == a.clienteId,
            orElse: () => Cliente(
              id: a.clienteId,
              nombre: a.clienteId,
              razonSocial: '',
              personaContacto: '',
              telefono: '',
              correo: '',
              direccion: '',
            ),
          );
          if (client.nombre.isNotEmpty) {
            clientNames.add(client.nombre);
          }
        }
      }
      // Construir lista de técnicos asignados
      final Set<String> techNames = <String>{};
      for (final a in jobAssignments) {
        for (final techId in a.tecnicosAsignados) {
          final user = usuariosVM.usuarios.firstWhere(
            (u) => u.id == techId,
            orElse: () => Usuario(
              id: techId,
              authUid: '',
              nombre: techId,
              email: '',
              idEmpresa: '',
              perfilId: '',
            ),
          );
          if (user.nombre.isNotEmpty) {
            techNames.add(user.nombre);
          }
        }
      }
      result.add(
        job.copyWith(
          estado: consolidatedState,
          clientesAsignados: clientNames.toList(),
          empleadosAsignados: techNames.toList(),
        ),
      );
    }
    // También incluir trabajos que existan sólo en asignaciones y no en el
    // catálogo.  Esto permite mostrar asignaciones cuya definición
    // del trabajo fue eliminada del catálogo pero siguen activas.
    final Set<String> catalogIds = catalogo.map((t) => t.id).toSet();
    final extraAssignments = asignaciones
        .where((a) => !catalogIds.contains(a.trabajoId))
        .toList();
    for (final a in extraAssignments) {
      // Construir un trabajo mínimo a partir de la asignación
      String consolidatedState = a.estado.replaceAll('_', ' ');
      final Set<String> clientNames = <String>{};
      if (a.clienteId.isNotEmpty) {
        final client = clientesVM.clientes.firstWhere(
          (c) => c.id == a.clienteId,
          orElse: () => Cliente(
            id: a.clienteId,
            nombre: a.clienteId,
            razonSocial: '',
            personaContacto: '',
            telefono: '',
            correo: '',
            direccion: '',
          ),
        );
        if (client.nombre.isNotEmpty) {
          clientNames.add(client.nombre);
        }
      }
      final Set<String> techNames = <String>{};
      for (final techId in a.tecnicosAsignados) {
        final user = usuariosVM.usuarios.firstWhere(
          (u) => u.id == techId,
          orElse: () => Usuario(
            id: techId,
            authUid: '',
            nombre: techId,
            email: '',
            idEmpresa: '',
            perfilId: '',
          ),
        );
        techNames.add(user.nombre);
      }
      result.add(
        Trabajo(
          id: a.trabajoId,
          titulo: a.tituloTrabajo.isNotEmpty ? a.tituloTrabajo : a.trabajoId,
          cliente: clientNames.isNotEmpty ? clientNames.first : '',
          fechaInicio: a.fechaInicio,
          fechaFin: a.fechaFin,
          estado: consolidatedState,
          descripcion: '',
          costo: a.precioFinal,
          esCiclico: a.esCiclico,
          frecuenciaCiclico: a.frecuenciaCiclico,
          proximaFecha: a.proximaFecha,
          empleadosAsignados: techNames.toList(),
          clientesAsignados: clientNames.toList(),
          clienteId: a.clienteId,
          empresaId: a.empresaId,
        ),
      );
    }
    return result;
  }

  /// Agrupa una lista de trabajos que representan asignaciones
  /// individuales en un único trabajo por identificador.  Cuando un
  /// trabajo está asignado a múltiples clientes o técnicos, este
  /// método consolida las listas de clientes y empleados evitando
  /// duplicados.  También determina un estado representativo para el
  /// trabajo en función del estado de sus asignaciones.  El estado
  /// con mayor prioridad es 'En progreso', seguido de 'Pendiente',
  /// luego 'Completo' o 'Finalizado' y finalmente 'Cancelado'.
  List<Trabajo> _groupTrabajos(List<Trabajo> trabajos) {
    // Mapear cada trabajo a una entrada única por id.
    final Map<String, Trabajo> result = {};
    final Map<String, Set<String>> clientSets = {};
    final Map<String, Set<String>> techSets = {};
    final Map<String, String> bestStatus = {};
    // Definir el orden de prioridad de los estados.  Se comparan en
    // minúsculas para evitar problemas por mayúsculas o guiones.
    final List<String> statusOrder = [
      'iniciado',
      'en progreso',
      'en espera',
      'pendiente',
      'finalizado',
      'completo',
      'cerrado',
      'cancelado',
    ];
    for (final t in trabajos) {
      final key = t.id;
      // Inicializar las estructuras para este trabajo si no existen.
      if (!result.containsKey(key)) {
        result[key] = t;
        clientSets[key] = <String>{};
        techSets[key] = <String>{};
        bestStatus[key] = t.estado;
      }
      final clients = clientSets[key]!;
      // Agregar el cliente principal y la lista de clientes asignados.
      if (t.cliente.isNotEmpty) clients.add(t.cliente);
      clients.addAll(t.clientesAsignados);
      final techs = techSets[key]!;
      techs.addAll(t.empleadosAsignados);
      // Determinar si este estado tiene mayor prioridad que el actual.
      final currentBest = bestStatus[key] ?? t.estado;
      final normalizedCurrent = currentBest.replaceAll('_', ' ').toLowerCase();
      final normalizedNew = t.estado.replaceAll('_', ' ').toLowerCase();
      int currentIndex = statusOrder.indexOf(normalizedCurrent);
      int newIndex = statusOrder.indexOf(normalizedNew);
      if (currentIndex == -1) currentIndex = statusOrder.length;
      if (newIndex == -1) newIndex = statusOrder.length;
      // Si el nuevo estado tiene índice menor (mayor prioridad),
      // reemplazar el estado representativo.
      if (newIndex < currentIndex) {
        bestStatus[key] = t.estado;
      }
    }
    // Construir la lista consolidada de trabajos.
    return result.entries.map((entry) {
      final id = entry.key;
      final base = entry.value;
      final clientsList = clientSets[id]!.where((c) => c.isNotEmpty).toList();
      final techList = techSets[id]!.where((c) => c.isNotEmpty).toList();
      final state = bestStatus[id] ?? base.estado;
      return base.copyWith(
        clientesAsignados: clientsList,
        empleadosAsignados: techList,
        estado: state,
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmpresaViewModel>().cargarEmpresa(widget.empresaId);
      // Cargar trabajos asignados para obtener el estado actual de cada trabajo
      context.read<TrabajosAsignadosViewModel>().cargarTrabajosAsignados(
        widget.empresaId,
      );
      // Cargar el catálogo de trabajos para disponer de títulos y costos
      context.read<TrabajosViewModel>().cargarTrabajos(widget.empresaId);
      // Cargar clientes para poder mostrar los nombres en filtros y tarjetas
      context.read<ClientesViewModel>().cargarClientes(widget.empresaId);
      // Cargar usuarios para disponer de los nombres de técnicos
      context.read<UsuariosViewModel>().cargarUsuarios(widget.empresaId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    // Buscar tanto en trabajos asignados como en el catálogo para
    // aplicar el filtro de búsqueda sobre ambas listas.  El método
    // buscar() del view model de trabajos actualiza la lista
    // filtrada del catálogo; el de asignaciones filtra las
    // asignaciones.  Se utilizan ambos resultados al combinar.
    context.read<TrabajosAsignadosViewModel>().buscar(query, widget.empresaId);
    context.read<TrabajosViewModel>().buscar(query, widget.empresaId);
  }

  String _initials() {
    final parts = widget.userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return ('${parts.first[0]}${parts.last[0]}').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Obtain the localization instance once for this build.
    final t = AppLocalizations.of(context)!;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.navMyJobs),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProblemsPage(
                      userName: widget.userName,
                      role: widget.role,
                    ),
                  ),
                );
              },
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UserSettingsPage(
                      userName: widget.userName,
                      role: widget.role,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    _initials(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Búsqueda y filtro: barra de búsqueda y botón de filtros
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: t.searchJobLabel,
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _filtrosVisibles
                          ? Icons.filter_alt_off
                          : Icons.filter_alt,
                    ),
                    tooltip: _filtrosVisibles
                        ? t.hideFiltersTooltip
                        : t.showFiltersTooltip,
                    onPressed: () {
                      setState(() {
                        _filtrosVisibles = !_filtrosVisibles;
                      });
                    },
                  ),
                ],
              ),
              // Panel de filtros animado: se construye al vuelo
              // utilizando los valores calculados del ViewModel y se
              // envuelve en un AnimatedSwitcher para animar la
              // expansión y contracción.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1.0,
                    child: child,
                  );
                },
                child: _filtrosVisibles
                    ? Consumer2<TrabajosAsignadosViewModel, TrabajosViewModel>(
                        builder: (context, asignadosVM, trabajosVM, child) {
                          // Combinar el catálogo de trabajos con las asignaciones para
                          // construir la lista de trabajos a partir de la cual
                          // derivar los filtros.
                          final List<Trabajo> listaTrabajos =
                              _mergeJobsWithAssignments(
                                trabajosVM.trabajos,
                                asignadosVM.trabajos,
                              );
                          final clientes = <String>{};
                          final tecnicos = <String>{};
                          for (final t in listaTrabajos) {
                            // Añadir todos los clientes asignados para filtros
                            for (final c in t.clientesAsignados) {
                              if (c.isNotEmpty) clientes.add(c);
                            }
                            // Añadir técnicos asignados (nombres) a filtros
                            for (final techName in t.empleadosAsignados) {
                              if (techName.isNotEmpty) {
                                tecnicos.add(techName);
                              }
                            }
                          }
                          // Prefix the list of client and technician filters with the localized
                          // "all" option.  Fall back to the Spanish default if localization
                          // hasn't been initialized yet.
                          final tLocal = AppLocalizations.of(context);
                          final allOption = tLocal == null
                              ? 'Todos'
                              : tLocal.allOption;
                          final clientesOpc = [
                            allOption,
                            ...clientes.toList()..sort(),
                          ];
                          final tecnicosOpc = [
                            allOption,
                            ...tecnicos.toList()..sort(),
                          ];
                          return Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 12.0,
                            ),
                            child: _buildFilterPanel(clientesOpc, tecnicosOpc),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ),
              // Añadir espacio vertical cuando los filtros están ocultos
              if (!_filtrosVisibles) const SizedBox(height: 12),
              // -----------------------------------------------------
              Expanded(
                child: Consumer2<TrabajosAsignadosViewModel, TrabajosViewModel>(
                  builder: (context, asignadosVM, trabajosVM, child) {
                    // Combinar trabajos del catálogo con asignaciones y
                    // agruparlos por identificador.  Esto garantiza que un
                    // mismo trabajo asignado a múltiples clientes se
                    // represente como un único elemento en la lista.
                    final List<Trabajo> merged = _mergeJobsWithAssignments(
                      trabajosVM.trabajos,
                      asignadosVM.trabajos,
                    );
                    final List<Trabajo> grouped = _groupTrabajos(merged);
                    Iterable<Trabajo> trabajosBase = grouped;
                    // Filtrar por rol (técnico ve solo los trabajos donde tiene asignaciones)
                    if (widget.role == 'PERF_TEC') {
                      // Obtener el id del usuario actual
                      String currentUserId = '';
                      try {
                        final usuariosVM = context.read<UsuariosViewModel>();
                        final user = usuariosVM.usuarios.firstWhere(
                          (u) => u.nombre == widget.userName,
                        );
                        currentUserId = user.id;
                      } catch (_) {
                        currentUserId = '';
                      }
                      trabajosBase = trabajosBase.where((t) {
                        // Revisar si existe alguna asignación activa con el id del usuario
                        final assignmentsForJob = asignadosVM.trabajos.where(
                          (a) => a.trabajoId == t.id && a.activo,
                        );
                        return assignmentsForJob.any((a) {
                          // final e = a.estado.toLowerCase();
                          return a.tecnicosAsignados.contains(currentUserId);
                        });
                      });
                    }
                    // Aplicar filtros de estado, cliente y técnico
                    final List<Trabajo> filtered = trabajosBase.where((tJob) {
                      // When the selected value is neither the Spanish default ('Todos')
                      // nor the localized "all" option, filter by client and
                      // technician.  Otherwise include all.
                      final localAll = AppLocalizations.of(context)!.allOption;
                      // Client filter
                      if (_filtroCliente != 'Todos' &&
                          _filtroCliente != localAll) {
                        if (!tJob.clientesAsignados.contains(_filtroCliente)) {
                          return false;
                        }
                      }
                      // Technician filter
                      if (_filtroTecnico != 'Todos' &&
                          _filtroTecnico != localAll) {
                        if (!tJob.empleadosAsignados.contains(_filtroTecnico)) {
                          return false;
                        }
                      }
                      return true;
                    }).toList();

                    if (widget.role == 'PERF_TEC') {}

                    return RefreshIndicator(
                      onRefresh: () async {
                        final asignadosVM = context
                            .read<TrabajosAsignadosViewModel>();
                        final trabajosVM = context.read<TrabajosViewModel>();
                        final clientesVM = context.read<ClientesViewModel>();
                        final usuariosVM = context.read<UsuariosViewModel>();
                        await Future.wait([
                          asignadosVM.cargarTrabajosAsignados(widget.empresaId),
                          trabajosVM.cargarTrabajos(widget.empresaId),
                          clientesVM.cargarClientes(widget.empresaId),
                          usuariosVM.cargarUsuarios(widget.empresaId),
                        ]);
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final trabajo = filtered[index];
                          return _JobCardOrAccordion(
                            trabajo: trabajo,
                            role: widget.role,
                            userId: widget.userId,
                            empresaId: widget.empresaId,
                            onTap: () async {
                              final asignadosVM2 = context
                                  .read<TrabajosAsignadosViewModel>();
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => JobDetailPage(
                                    job: trabajo,
                                    role: widget.role,
                                    userName: widget.userName,
                                  ),
                                ),
                              );
                              await asignadosVM2.cargarTrabajosAsignados(
                                widget.empresaId,
                              );
                              if (!context.mounted) return;
                              await context
                                  .read<TrabajosViewModel>()
                                  .cargarTrabajos(widget.empresaId);
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: widget.role == 'PERF_TEC'
            ? null
            : FloatingActionButton(
                onPressed: () async {
                  final trabajosVM = context.read<TrabajosViewModel>();

                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => JobFormPage(job: null, role: widget.role),
                    ),
                  );

                  await trabajosVM.cargarTrabajos(widget.empresaId);
                },
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// TARJETA / ACORDEÓN DEL TRABAJO
//  - PERF_TEC  -> tarjeta clickeable con descripción
//  - otros     -> acordeón con botón "Ver detalle"
// ---------------------------------------------------------------------
class _JobCardOrAccordion extends StatelessWidget {
  const _JobCardOrAccordion({
    required this.trabajo,
    required this.role,
    required this.userId,
    required this.empresaId,
    required this.onTap,
  });

  final Trabajo trabajo;
  final String role;
  final String userId;
  final String empresaId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final bool canEdit = true; // Permitir el borrado para todos los roles (ajustar según política)
    final bool showCost = role != 'PERF_TEC' && trabajo.costo > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trabajo.titulo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (trabajo.descripcion.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        trabajo.descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.black87),
                      ),
                    ],
                    if (showCost) ...[
                      const SizedBox(height: 4),
                      const SizedBox(height: 4),
                      CurrencyText(
                        trabajo.costo,
                        prefix: t.pricePrefix,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canEdit)
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: AppLocalizations.of(context)!.editButton,
                      onPressed: () async {
                        final asignadosVM = context
                            .read<TrabajosAsignadosViewModel>();
                        await asignadosVM.cargarTrabajosAsignados(
                          trabajo.empresaId,
                        );
                        final trabajosVM = context.read<TrabajosViewModel>();
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                JobFormPage(job: trabajo, role: role),
                          ),
                        );
                        await trabajosVM.cargarTrabajos(trabajo.empresaId);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: AppLocalizations.of(context)!.deleteButton,
                      onPressed: () async {
                        final confirm = await showWorkiaBottomSheet<bool>(
                          context: context,
                          builder: (ctx) {
                            final t = AppLocalizations.of(ctx)!;
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    t.confirmDeleteTitle,
                                    style: Theme.of(ctx).textTheme.titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(t.confirmDeleteMessage),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(t.noButton),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
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
                                          child: Text(t.yesButton),
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
                          final trabajosVM = context.read<TrabajosViewModel>();
                          final asignadosVM = context.read<TrabajosAsignadosViewModel>();

                          // Cancelar el trabajo en catálogo
                          await trabajosVM.cancelar(
                            trabajo.id,
                            empresaId,
                            userId,
                          );

                          // Cancelar asignaciones activas relacionadas al trabajo
                          final relatedAsignados = asignadosVM.trabajos
                              .where((a) => a.trabajoId == trabajo.id)
                              .toList();
                          for (final a in relatedAsignados) {
                            await asignadosVM.cancelar(
                              a.id,
                              empresaId,
                              userId,
                            );
                          }

                          // Recargar las listas
                          await Future.wait([
                            trabajosVM.cargarTrabajos(empresaId),
                            asignadosVM.cargarTrabajosAsignados(empresaId),
                          ]);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Trabajo cancelado correctamente.'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
