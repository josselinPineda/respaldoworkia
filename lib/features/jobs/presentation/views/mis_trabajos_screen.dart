import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/models/job.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/widgets/currency_text.dart';
import 'package:workia/features/settings/presentation/views/user_settings_screen.dart';
import 'package:workia/features/problems/presentation/views/problems_screen.dart';
import 'package:workia/features/jobs/presentation/views/job_form_screen.dart';
import 'package:workia/features/jobs/presentation/viewmodels/mis_trabajos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/empresa_viewmodel.dart';
import 'package:workia/features/jobs/presentation/views/job_detail_screen.dart';
import 'package:workia/utils/ui_utils.dart';

/// Pantalla refactorizada "Mis Trabajos" siguiendo MVVM.
///
/// La Vista consume el ViewModel y no contiene lógica de negocio.
class MisTrabajosScreen extends StatelessWidget {
  const MisTrabajosScreen({
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
      create: (ctx) => MisTrabajosViewModel(
        clientesVM: ctx.read<ClientesViewModel>(),
        asignadosVM: ctx.read<TrabajosAsignadosViewModel>(),
        usuariosVM: ctx.read<UsuariosViewModel>(),
        trabajosVM: ctx.read<TrabajosViewModel>(),
        userRole: role,
        userId: userId,
        empresaId: empresaId,
      ),
      child: _MisTrabajosContent(
        userName: userName,
        role: role,
        userId: userId,
        empresaId: empresaId,
      ),
    );
  }
}

class _MisTrabajosContent extends StatefulWidget {
  const _MisTrabajosContent({
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
  State<_MisTrabajosContent> createState() => _MisTrabajosContentState();
}

class _MisTrabajosContentState extends State<_MisTrabajosContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmpresaViewModel>().cargarEmpresa(widget.empresaId);
      context.read<TrabajosAsignadosViewModel>().cargarTrabajosAsignados(
        widget.empresaId,
      );
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
    context.read<MisTrabajosViewModel>().setSearchQuery(
      _searchController.text.trim(),
    );
  }

  String _getInitials() {
    final vm = context.read<MisTrabajosViewModel>();
    return vm.getInitials(widget.userName);
  }

  Future<void> _refreshData() async {
    await Future.wait([
      context.read<TrabajosAsignadosViewModel>().cargarTrabajosAsignados(
        widget.empresaId,
      ),
      context.read<TrabajosViewModel>().cargarTrabajos(widget.empresaId),
      context.read<ClientesViewModel>().cargarClientes(widget.empresaId),
      context.read<UsuariosViewModel>().cargarUsuarios(widget.empresaId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final vm = context.watch<MisTrabajosViewModel>();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.navMyJobs),
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    _getInitials(),
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
              // Búsqueda y filtros
              _SearchBar(
                controller: _searchController,
                filtrosVisibles: vm.filtrosVisibles,
                onToggleFiltros: vm.toggleFiltrosVisibles,
              ),
              // Panel de filtros animado
              _AnimatedFilterPanel(vm: vm),
              if (!vm.filtrosVisibles) const SizedBox(height: 12),
              // Lista de trabajos
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  child: _JobsList(
                    jobs: vm.filteredJobs,
                    role: widget.role,
                    userId: widget.userId,
                    empresaId: widget.empresaId,
                    userName: widget.userName,
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: widget.role == 'PERF_TEC'
            ? null
            : FloatingActionButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          JobFormScreen(job: null, role: widget.role),
                    ),
                  );
                  if (!context.mounted) return;
                  await context.read<TrabajosViewModel>().cargarTrabajos(
                    widget.empresaId,
                  );
                },
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}

// ========== WIDGETS PUROS UI ==========

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

  final MisTrabajosViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final allOption = t.allOption;

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
              child: Row(
                children: [
                  Expanded(
                    child: DropdownSearch<String>(
                      items: (_, __) => vm.clienteOptions,
                      selectedItem:
                          (vm.filtroCliente == 'Todos' ||
                              vm.filtroCliente == allOption)
                          ? null
                          : vm.filtroCliente,
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: t.clientLabel,
                          isDense: true,
                        ),
                      ),
                      popupProps: const PopupProps.menu(showSearchBox: true),
                      onChanged: (value) =>
                          vm.setFiltroCliente(value ?? allOption),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownSearch<String>(
                      items: (_, __) => vm.tecnicoOptions,
                      selectedItem:
                          (vm.filtroTecnico == 'Todos' ||
                              vm.filtroTecnico == allOption)
                          ? null
                          : vm.filtroTecnico,
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: t.technicianLabel,
                          isDense: true,
                        ),
                      ),
                      popupProps: const PopupProps.menu(showSearchBox: true),
                      onChanged: (value) =>
                          vm.setFiltroTecnico(value ?? allOption),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _JobsList extends StatelessWidget {
  const _JobsList({
    required this.jobs,
    required this.role,
    required this.userId,
    required this.empresaId,
    required this.userName,
  });

  final List<Trabajo> jobs;
  final String role;
  final String userId;
  final String empresaId;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return _JobCard(
          job: job,
          role: role,
          userId: userId,
          empresaId: empresaId,
          userName: userName,
        );
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.role,
    required this.userId,
    required this.empresaId,
    required this.userName,
  });

  final Trabajo job;
  final String role;
  final String userId;
  final String empresaId;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final canEdit = true; // Permitir acciones para todos los roles (ajustar según permiso real)
    final showCost = role != 'PERF_TEC' && job.costo > 0;

    return InkWell(
      onTap: () => _navigateToDetail(context),
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
                      job.titulo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (job.descripcion.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        job.descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.black87),
                      ),
                    ],
                    if (showCost) ...[
                      const SizedBox(height: 4),
                      CurrencyText(
                        job.costo,
                        prefix: t.pricePrefix,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                    if (job.autoFinalizarHoras != null &&
                        job.autoFinalizarHoras! > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tiempo: ${job.autoFinalizarHoras}h',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canEdit)
                _ActionButtons(
                  job: job,
                  role: role,
                  userId: userId,
                  empresaId: empresaId,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToDetail(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            JobDetailScreen(job: job, role: role, userName: userName),
      ),
    );
    if (!context.mounted) return;
    await context.read<TrabajosAsignadosViewModel>().cargarTrabajosAsignados(
      empresaId,
    );
    if (!context.mounted) return;
    await context.read<TrabajosViewModel>().cargarTrabajos(empresaId);
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.job,
    required this.role,
    required this.userId,
    required this.empresaId,
  });

  final Trabajo job;
  final String role;
  final String userId;
  final String empresaId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: t.editButton,
          onPressed: () => _editJob(context),
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: t.deleteButton,
          onPressed: () => _confirmDelete(context),
        ),
      ],
    );
  }

  Future<void> _editJob(BuildContext context) async {
    await context.read<TrabajosAsignadosViewModel>().cargarTrabajosAsignados(
      job.empresaId,
    );
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobFormScreen(job: job, role: role),
      ),
    );
    if (context.mounted) {
      await context.read<TrabajosViewModel>().cargarTrabajos(job.empresaId);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final confirm = await showWorkiaBottomSheet<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.confirmDeleteTitle,
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(t.confirmDeleteMessage),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(t.noButton),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(t.yesButton),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      final trabajosVM = context.read<TrabajosViewModel>();
      final asignadosVM = context.read<TrabajosAsignadosViewModel>();

      // Cancelar el trabajo en catálogo
      await trabajosVM.cancelar(job.id, empresaId, userId);

      // Cancelar las asignaciones del trabajo
      final relatedAsignados = asignadosVM.trabajos
          .where((a) => a.trabajoId == job.id)
          .toList();
      for (final a in relatedAsignados) {
        await asignadosVM.cancelar(a.id, empresaId, userId);
      }

      // Recargar datos
      await Future.wait([
        trabajosVM.cargarTrabajos(empresaId),
        asignadosVM.cargarTrabajosAsignados(empresaId),
      ]);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trabajo cancelado correctamente.')),
        );
      }
    }
  }
}
