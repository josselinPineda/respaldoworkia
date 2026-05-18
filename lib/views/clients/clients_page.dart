import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:workia/views/clients/client_edit_page.dart';
import 'package:workia/views/settings/user_settings_page.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';

import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';

import 'package:workia/views/problems/problems_page.dart';
import 'package:workia/views/clients/client_tabs_page.dart';
// Importar viewmodel y modelo de problemas para mostrar desde el
// icono de notificaciones.
// Importar dropdown_search para filtros con búsqueda
import 'package:dropdown_search/dropdown_search.dart';
import 'package:workia/l10n/app_localizations.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({
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
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final TextEditingController _searchController = TextEditingController();

  // Variables para manejar los filtros de estado (activo/inactivo)
  // y asignaciones (clientes con o sin trabajos asignados).
  // Por defecto sólo se muestran los clientes activos.
  bool _filtrosVisibles = false;
  String _asignadoFiltro = 'Todos';

  /// Construye el panel de filtros.  Se coloca en un método separado
  /// para facilitar su uso dentro de un AnimatedSwitcher.  El panel
  /// contiene dos desplegables para filtrar por estado (Activo/Inactivo)
  /// y por asignación (Asignados/No asignados).
  Widget _buildFilterPanel() {
    return Column(
      children: [
        DropdownSearch<String>(
          items: (String filter, LoadProps? loadProps) => const [
            'Todos',
            'Asignados',
            'No asignados',
          ],
          itemAsString: (item) {
            if (item == 'Todos') return AppLocalizations.of(context)!.allLabel;
            if (item == 'Asignados') {
              return AppLocalizations.of(context)!.assignedFilter;
            }
            if (item == 'No asignados') {
              return AppLocalizations.of(context)!.unassignedFilter;
            }
            return item;
          },
          selectedItem: _asignadoFiltro == 'Todos' ? null : _asignadoFiltro,
          decoratorProps: DropDownDecoratorProps(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.assignmentFilterLabel,

              isDense: true,
            ),
          ),
          popupProps: const PopupProps.menu(showSearchBox: true),
          onChanged: (String? value) {
            setState(() {
              _asignadoFiltro = value ?? 'Todos';
            });
          },
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Cargar asignaciones para poder filtrar clientes por trabajos asignados.
    // Se realiza después del primer frame para garantizar que el contexto
    // esté disponible.  Si las asignaciones ya están cargadas esto no
    // afecta.  Se utiliza una postFrameCallback para evitar leer el
    // viewModel en initState directamente.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientesViewModel>().cargarClientes(widget.empresaId);
      context.read<TrabajosViewModel>().cargarTrabajos(widget.empresaId);
      final asignadosVM = context.read<TrabajosAsignadosViewModel>();
      asignadosVM.cargarTrabajosAsignados(widget.empresaId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    final viewModel = context.read<ClientesViewModel>();
    viewModel.buscar(query, widget.empresaId);
  }

  // (El _openProblemsDialog lo dejo igual, lo omito aquí por espacio
  // porque no toca nada del mapa; puedes conservar tu versión tal cual)

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
    final viewModel = context.watch<ClientesViewModel>();
    final allClients = viewModel.clientes;
    final clients = allClients
        .where(
          (c) =>
              widget.empresaId.isEmpty ||
              c.empresaId.isEmpty ||
              c.empresaId == widget.empresaId,
        )
        .toList();
    // Aplicar filtros adicionales sobre la lista de clientes.  Se
    // observan las asignaciones para determinar qué clientes tienen
    // trabajos asignados.  Luego se filtra por estado y asignado/no
    // asignado según lo seleccionado.
    final asignadosVM = context.watch<TrabajosAsignadosViewModel>();
    final Set<String> assignedClientIds = asignadosVM.trabajos
        .where((a) => a.activo)
        .map((a) => a.clienteId)
        .toSet();
    // Filtrar por estado y asignaciones
    final filteredClients = clients.where((c) {
      bool ok = true;
      if (_asignadoFiltro == 'Asignados' && !assignedClientIds.contains(c.id))
        ok = false;
      if (_asignadoFiltro == 'No asignados' && assignedClientIds.contains(c.id))
        ok = false;
      return ok;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.clientsTitle),
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
                backgroundColor: Theme.of(context).primaryColor,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Búsqueda y filtro
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.searchClientLabel,
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
                    _filtrosVisibles ? Icons.filter_alt_off : Icons.filter_alt,
                  ),
                  tooltip: _filtrosVisibles
                      ? AppLocalizations.of(context)!.hideFiltersTooltip
                      : AppLocalizations.of(context)!.showFiltersTooltip,
                  onPressed: () {
                    setState(() {
                      _filtrosVisibles = !_filtrosVisibles;
                    });
                  },
                ),
              ],
            ),
            // Panel de filtros con animación.
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
                      child: _buildFilterPanel(),
                    )
                  : const SizedBox.shrink(),
            ),
            // Agregar un espacio vertical constante cuando los filtros están ocultos
            if (!_filtrosVisibles) const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final clientesVM = context.read<ClientesViewModel>();
                  final trabajosVM = context.read<TrabajosViewModel>();
                  final asignadosVM = context
                      .read<TrabajosAsignadosViewModel>();
                  await Future.wait([
                    clientesVM.cargarClientes(widget.empresaId),
                    trabajosVM.cargarTrabajos(widget.empresaId),
                    asignadosVM.cargarTrabajosAsignados(widget.empresaId),
                  ]);
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filteredClients.length,
                  itemBuilder: (context, index) {
                    final client = filteredClients[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            client.nombre.isNotEmpty
                                ? client.nombre[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          client.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (client.razonSocial.isNotEmpty)
                              Text(
                                client.razonSocial,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black54,
                                ),
                              ),
                            if (client.direccion.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        client.direccion,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (client.personaContacto.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_outline, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      client.personaContacto,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (client.telefono.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      client.telefono,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (client.correo.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.email_outlined, size: 14),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        client.correo,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: AppLocalizations.of(context)!.editTooltip,
                          onPressed: () async {
                            final clientesVM = context
                                .read<ClientesViewModel>();
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ClientEditPage(
                                  client: client,
                                  userId: widget.userId,
                                  empresaId: widget.empresaId,
                                ),
                              ),
                            );
                            await clientesVM.cargarClientes(widget.empresaId);
                          },
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ClientTabsPage(
                                client: client,
                                userId: widget.userId,
                                empresaId: widget.empresaId,
                                role: widget.role,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final clientesVM = context.read<ClientesViewModel>();
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ClientEditPage(
                client: null,
                userId: widget.userId,
                empresaId: widget.empresaId,
              ),
            ),
          );
          await clientesVM.cargarClientes(widget.empresaId);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Puedes conservar _ClientAccordion y _InfoRow si los usas en otra parte;
// ya no muestran mapa, así que los dejo tal cual o elimínalos si no se usan.
