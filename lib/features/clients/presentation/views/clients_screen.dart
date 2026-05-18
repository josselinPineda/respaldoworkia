import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/models/cliente.dart';
import 'package:workia/widgets/currency_text.dart';
import 'package:workia/models/job.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/features/clients/presentation/views/client_edit_screen.dart';
import 'package:workia/features/clients/presentation/views/client_detail_screen.dart';
import 'package:workia/features/settings/presentation/views/user_settings_screen.dart';
import 'package:workia/features/problems/presentation/views/problems_screen.dart';
import 'package:workia/features/clients/presentation/viewmodels/clients_page_viewmodel.dart';
import 'package:workia/utils/ui_utils.dart';

/// Pantalla refactorizada "Clients" siguiendo MVVM.
class ClientsScreen extends StatelessWidget {
  const ClientsScreen({
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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ClientsPageViewModel(
        clientesVM: ctx.read<ClientesViewModel>(),
        trabajosVM: ctx.read<TrabajosViewModel>(),
        asignadosVM: ctx.read<TrabajosAsignadosViewModel>(),
        empresaId: empresaId,
        userId: userId,
      ),
      child: _ClientsScreenContent(
        userName: userName,
        role: role,
        userId: userId,
        empresaId: empresaId,
      ),
    );
  }
}

class _ClientsScreenContent extends StatefulWidget {
  const _ClientsScreenContent({
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
  State<_ClientsScreenContent> createState() => _ClientsScreenContentState();
}

class _ClientsScreenContentState extends State<_ClientsScreenContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientsPageViewModel>().loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<ClientsPageViewModel>().setSearchQuery(
      _searchController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final vm = context.watch<ClientsPageViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.clientsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProblemsScreen(
                  userName: widget.userName,
                  role: widget.role,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserSettingsScreen(
                  userName: widget.userName,
                  role: widget.role,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  vm.getInitials(widget.userName),
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
            _SearchBar(
              controller: _searchController,
              filtrosVisibles: vm.filtrosVisibles,
              onToggleFiltros: vm.toggleFiltrosVisibles,
            ),
            _AnimatedFilterPanel(vm: vm),
            if (!vm.filtrosVisibles) const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: vm.loadData,
                child: _ClientsList(
                  clients: vm.filteredClients,
                  role: widget.role,
                  userId: widget.userId,
                  empresaId: widget.empresaId,
                  onAssignJobs: (client) =>
                      _showAssignJobsSheet(context, client, vm),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClientEditScreen(
                client: null,
                userId: widget.userId,
                empresaId: widget.empresaId,
              ),
            ),
          );
          if (!context.mounted) return;
          await context.read<ClientesViewModel>().cargarClientes(
            widget.empresaId,
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAssignJobsSheet(
    BuildContext context,
    Cliente client,
    ClientsPageViewModel vm,
  ) async {
    final t = AppLocalizations.of(context)!;
    final trabajos = List<Trabajo>.from(vm.availableJobs);
    final tempSelected = <String>{};

    await showWorkiaBottomSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t.assignJobsTitle(client.nombre),
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: trabajos.length,
                    itemBuilder: (_, index) {
                      final job = trabajos[index];
                      return CheckboxListTile(
                        title: Text(job.titulo),
                        subtitle: CurrencyText(job.costo, prefix: t.costPrefix),
                        value: tempSelected.contains(job.id),
                        onChanged: (checked) {
                          setStateDialog(() {
                            if (checked == true) {
                              tempSelected.add(job.id);
                            } else {
                              tempSelected.remove(job.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
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
                          final nav = Navigator.of(ctx);
                          final messenger = ScaffoldMessenger.of(ctx);
                          await vm.assignJobsToClient(client, tempSelected);
                          nav.pop();
                          messenger.showSnackBar(
                            SnackBar(content: Text(t.jobsAssignedMessage)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(ctx).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(t.assignButton),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========== WIDGETS UI ==========

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.filtrosVisibles,
    required this.onToggleFiltros,
  });

  final TextEditingController controller;
  final bool filtrosVisibles;
  final VoidCallback onToggleFiltros;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: t.searchClientLabel,
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(filtrosVisibles ? Icons.filter_alt_off : Icons.filter_alt),
          tooltip: filtrosVisibles
              ? t.hideFiltersTooltip
              : t.showFiltersTooltip,
          onPressed: onToggleFiltros,
        ),
      ],
    );
  }
}

class _AnimatedFilterPanel extends StatelessWidget {
  const _AnimatedFilterPanel({required this.vm});

  final ClientsPageViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1.0,
        child: child,
      ),
      child: vm.filtrosVisibles
          ? Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
              child: DropdownSearch<String>(
                items: (_, __) => vm.asignadoOptions,
                itemAsString: (item) {
                  if (item == 'Todos') return t.allLabel;
                  if (item == 'Asignados') return t.assignedFilter;
                  if (item == 'No asignados') return t.unassignedFilter;
                  return item;
                },
                selectedItem: vm.asignadoFiltro == 'Todos'
                    ? null
                    : vm.asignadoFiltro,
                decoratorProps: DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: t.assignmentFilterLabel,
                    isDense: true,
                  ),
                ),
                popupProps: const PopupProps.menu(showSearchBox: true),
                onChanged: (v) => vm.setAsignadoFiltro(v ?? 'Todos'),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _ClientsList extends StatelessWidget {
  const _ClientsList({
    required this.clients,
    required this.role,
    required this.userId,
    required this.empresaId,
    required this.onAssignJobs,
  });

  final List<Cliente> clients;
  final String role;
  final String userId;
  final String empresaId;
  final void Function(Cliente) onAssignJobs;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: clients.length,
      itemBuilder: (context, index) {
        final client = clients[index];
        return _ClientCard(
          client: client,
          role: role,
          userId: userId,
          empresaId: empresaId,
          onAssignJobs: () => onAssignJobs(client),
        );
      },
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.client,
    required this.role,
    required this.userId,
    required this.empresaId,
    required this.onAssignJobs,
  });

  final Cliente client;
  final String role;
  final String userId;
  final String empresaId;
  final VoidCallback onAssignJobs;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            client.nombre.isNotEmpty ? client.nombre[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          client.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: _ClientSubtitle(client: client),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          tooltip: t.editTooltip,
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
            if (context.mounted) {
              await context.read<ClientesViewModel>().cargarClientes(empresaId);
            }
          },
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClientDetailScreen(
              clientId: client.id,
              userId: userId,
              empresaId: empresaId,
              role: role,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientSubtitle extends StatelessWidget {
  const _ClientSubtitle({required this.client});

  final Cliente client;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          _InfoRow(icon: Icons.location_on_outlined, text: client.direccion),
        if (client.personaContacto.isNotEmpty)
          _InfoRow(icon: Icons.person_outline, text: client.personaContacto),
        if (client.telefono.isNotEmpty)
          _InfoRow(icon: Icons.phone_outlined, text: client.telefono),
        if (client.correo.isNotEmpty)
          _InfoRow(icon: Icons.email_outlined, text: client.correo),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
