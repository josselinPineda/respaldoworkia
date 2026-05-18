import 'package:flutter/material.dart';
import 'package:workia/models/job.dart';
import 'package:provider/provider.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/views/jobs/job_form_page.dart';
import 'package:workia/views/jobs/job_detail_page.dart';
import 'package:workia/views/problems/problems_page.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/widgets/currency_text.dart';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/models/usuario.dart';

/// Page that displays and manages a list of jobs.  Users can
/// search through existing jobs, view details, edit or delete
/// them, and create new jobs.  Data is stored in memory via
/// [JobsController]; when connected to a backend, this controller
/// should be replaced with one that persists data to Firestore.
class JobsPage extends StatefulWidget {
  const JobsPage({
    super.key,
    required this.role,
    required this.userName,
    required this.empresaId,
  });

  /// Rol del usuario actual.  Se utiliza para determinar si
  /// puede crear nuevos trabajos y ver información sensible como
  /// el costo.
  final String role;

  /// Nombre de usuario actual.  Se utiliza para asociar actividades
  /// registradas y para pasar a la página de detalle del trabajo.
  final String userName;

  /// Identificador de la empresa actual.
  final String empresaId;

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  // Controlador de búsqueda para filtrar trabajos.
  final TextEditingController _searchController = TextEditingController();

  // Filtros
  bool _filtrosVisibles = false;
  String _statusFilter = 'Todos';
  String _clientFilter = 'Todos';
  String _techFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Cargar trabajos después del primer frame para inicializar la lista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrabajosViewModel>().cargarTrabajos(widget.empresaId);
      context.read<ClientesViewModel>().cargarClientes(widget.empresaId);
      context.read<UsuariosViewModel>().cargarUsuarios(widget.empresaId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    // Delegar la búsqueda al ViewModel.  Si la consulta está vacía
    // se restablece la lista completa.
    context.read<TrabajosViewModel>().buscar(query, widget.empresaId);
  }

  @override
  Widget build(BuildContext context) {
    // Obtain localized strings
    final t = AppLocalizations.of(context)!;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          // Use localized title for jobs page
          title: Text(t.jobsTitle),
          actions: [
            // Icono de notificaciones para ver problemas.  Utiliza
            // un diálogo similar al de AgendaPage.  Técnicos y
            // finanzas ven sus problemas y pueden crear uno nuevo;
            // administradores ven todos los problemas.
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
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Búsqueda y filtro
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
              // Panel de filtros con animación
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1.0,
                    child: child,
                  );
                },
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                child: _filtrosVisibles
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                        child: Column(
                          children: [
                            // Filtro de Estado
                            DropdownSearch<String>(
                              items: (filter, _) => [
                                'Todos',
                                'En espera', // Changed from Pendiente
                                'Iniciado',
                                'Finalizado',
                                'Cerrado',
                              ],
                              itemAsString: (item) {
                                if (item == 'Todos') return t.allOption;
                                if (item == 'En espera')
                                  return t.jobStatusOnHold;
                                if (item == 'Iniciado')
                                  return t.jobStatusStarted;
                                if (item == 'Finalizado')
                                  return t.jobStatusFinished;
                                if (item == 'Cerrado') return t.jobStatusClosed;
                                return item;
                              },
                              selectedItem: _statusFilter == 'Todos'
                                  ? null
                                  : _statusFilter,
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: t.filterByStatusLabel,
                                  isDense: true,
                                ),
                              ),
                              popupProps: const PopupProps.menu(
                                fit: FlexFit.loose,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _statusFilter = value ?? 'Todos';
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            // Filtro de Cliente
                            Consumer<ClientesViewModel>(
                              builder: (context, clientesVM, child) {
                                return DropdownSearch<String>(
                                  items: (filter, _) {
                                    final all = [
                                      'Todos',
                                      ...clientesVM.clientes.map(
                                        (c) => c.nombre,
                                      ),
                                    ];
                                    if (filter.isEmpty) return all;
                                    return all
                                        .where(
                                          (e) => e.toLowerCase().contains(
                                            filter.toLowerCase(),
                                          ),
                                        )
                                        .toList();
                                  },
                                  itemAsString: (item) =>
                                      item == 'Todos' ? t.allOption : item,
                                  selectedItem: _clientFilter == 'Todos'
                                      ? null
                                      : _clientFilter,
                                  decoratorProps: DropDownDecoratorProps(
                                    decoration: InputDecoration(
                                      labelText: t.clientLabel,
                                      isDense: true,
                                    ),
                                  ),
                                  popupProps: const PopupProps.menu(
                                    showSearchBox: true,
                                    fit: FlexFit.loose,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _clientFilter = value ?? 'Todos';
                                    });
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            // Filtro de Técnico
                            Consumer<UsuariosViewModel>(
                              builder: (context, usuariosVM, child) {
                                return DropdownSearch<String>(
                                  items: (filter, _) {
                                    final all = [
                                      'Todos',
                                      ...usuariosVM.usuarios.map(
                                        (u) => u.nombre,
                                      ),
                                    ];
                                    if (filter.isEmpty) return all;
                                    return all
                                        .where(
                                          (e) => e.toLowerCase().contains(
                                            filter.toLowerCase(),
                                          ),
                                        )
                                        .toList();
                                  },
                                  itemAsString: (item) =>
                                      item == 'Todos' ? t.allOption : item,
                                  selectedItem: _techFilter == 'Todos'
                                      ? null
                                      : _techFilter,
                                  decoratorProps: DropDownDecoratorProps(
                                    decoration: InputDecoration(
                                      labelText: t.technicianLabel,
                                      isDense: true,
                                    ),
                                  ),
                                  popupProps: const PopupProps.menu(
                                    showSearchBox: true,
                                    fit: FlexFit.loose,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _techFilter = value ?? 'Todos';
                                    });
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              // Agregar un espacio vertical constante cuando los filtros están ocultos
              if (!_filtrosVisibles) const SizedBox(height: 12),
              Expanded(
                child: Consumer<TrabajosViewModel>(
                  builder: (context, viewModel, child) {
                    // Filtrar la lista de trabajos
                    final usuariosVM = context.read<UsuariosViewModel>();
                    final listaFiltrada = viewModel.trabajos.where((job) {
                      // Filtro de estado
                      if (_statusFilter != 'Todos' &&
                          job.estado != _statusFilter) {
                        return false;
                      }
                      // Filtro de cliente
                      if (_clientFilter != 'Todos') {
                        final clientMatch =
                            job.cliente == _clientFilter ||
                            job.clientesAsignados.contains(_clientFilter);
                        if (!clientMatch) return false;
                      }
                      // Filtro de técnico
                      if (_techFilter != 'Todos') {
                        final techMatch = job.empleadosAsignados.any((id) {
                          final user = usuariosVM.usuarios.firstWhere(
                            (u) => u.id == id,
                            orElse: () => Usuario(
                              id: '',
                              authUid: '',
                              nombre: '',
                              email: '',
                              idEmpresa: '',
                              perfilId: '',
                            ),
                          );
                          return user.nombre == _techFilter;
                        });
                        if (!techMatch) return false;
                      }
                      return true;
                    }).toList();

                    return RefreshIndicator(
                      onRefresh: () async {
                        final trabajosVM = context.read<TrabajosViewModel>();
                        final clientesVM = context.read<ClientesViewModel>();
                        final usuariosVM = context.read<UsuariosViewModel>();
                        await Future.wait([
                          trabajosVM.cargarTrabajos(widget.empresaId),
                          clientesVM.cargarClientes(widget.empresaId),
                          usuariosVM.cargarUsuarios(widget.empresaId),
                        ]);
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: listaFiltrada.length,
                        itemBuilder: (context, index) {
                          final job = listaFiltrada[index];
                          return _JobListItem(
                            job: job,
                            role: widget.role,
                            onTap: () async {
                              // Capturar el ViewModel antes de navegar para evitar usar context después del await
                              final trabajosVM = context
                                  .read<TrabajosViewModel>();
                              // Abrir página de detalle y recargar al volver
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => JobDetailPage(
                                    job: job,
                                    role: widget.role,
                                    userName: widget.userName,
                                  ),
                                ),
                              );
                              // Recargar trabajos después de volver usando el ViewModel capturado
                              await trabajosVM.cargarTrabajos(widget.empresaId);
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
        floatingActionButton: (widget.role == 'PERF_TEC')
            ? null
            : FloatingActionButton(
                onPressed: () async {
                  // Capturar el ViewModel antes de navegar
                  final trabajosVM = context.read<TrabajosViewModel>();
                  // Navegar al formulario de trabajo para un nuevo trabajo
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => JobFormPage(job: null, role: widget.role),
                    ),
                  );
                  // Recargar trabajos después de agregar usando el ViewModel capturado
                  await trabajosVM.cargarTrabajos(widget.empresaId);
                },
                child: const Icon(Icons.add),
              ),
      ),
    );
  }

  /// Muestra un diálogo con el listado de problemas de acuerdo al
  /// rol.  Este método ya no se utiliza tras la refactorización que
  /// centraliza los problemas en `ProblemsPage`.  Se conserva como
  /// referencia.  La anotación `unused_element` evita advertencias
  /// del analizador.
}

class _JobListItem extends StatelessWidget {
  const _JobListItem({
    required this.job,
    required this.role,
    required this.onTap,
  });

  final Trabajo job;
  final String role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    // Determine if the user can see the cost (Admins and Finance)
    final bool showCost = role != 'PERF_TEC' && job.costo > 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(Icons.work),
        ),
        title: Text(
          job.titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (job.descripcion.isNotEmpty)
              Text(
                job.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (job.cliente.isNotEmpty)
              Text(
                '${t.clientLabel}: ${job.cliente}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            if (showCost)
              CurrencyText(
                job.costo,
                prefix:
                    '${t.pricePrefix} ', // Add space as prefix might not have it
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
