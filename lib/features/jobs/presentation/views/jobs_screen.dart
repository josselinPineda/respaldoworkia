import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/models/job.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/widgets/currency_text.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/features/jobs/presentation/views/job_form_screen.dart';
import 'package:workia/features/problems/presentation/views/problems_screen.dart';
import 'package:workia/features/jobs/presentation/viewmodels/jobs_page_viewmodel.dart';
import 'package:workia/features/jobs/presentation/views/job_detail_screen.dart';
import 'package:workia/utils/ui_utils.dart';

/// Pantalla refactorizada "Jobs" (catálogo de trabajos) siguiendo MVVM.
class JobsScreen extends StatelessWidget {
  const JobsScreen({
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
      create: (ctx) => JobsPageViewModel(
        trabajosVM: ctx.read<TrabajosViewModel>(),
        clientesVM: ctx.read<ClientesViewModel>(),
        usuariosVM: ctx.read<UsuariosViewModel>(),
        empresaId: empresaId,
        userRole: role,
      ),
      child: _JobsScreenContent(
        userName: userName,
        role: role,
        userId: userId,
        empresaId: empresaId,
      ),
    );
  }
}

class _JobsScreenContent extends StatefulWidget {
  const _JobsScreenContent({
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
  State<_JobsScreenContent> createState() => _JobsScreenContentState();
}

class _JobsScreenContentState extends State<_JobsScreenContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobsPageViewModel>().loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<JobsPageViewModel>().setSearchQuery(
      _searchController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final vm = context.watch<JobsPageViewModel>();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.jobsTitle),
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
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
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
                  child: _JobsList(
                    jobs: vm.filteredJobs,
                    role: widget.role,
                    userId: widget.userId,
                    empresaId: widget.empresaId,
                    userName: widget.userName,
                    onDelete: (job) => vm.deleteJob(job.id, widget.userId),
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

  final JobsPageViewModel vm;

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
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownSearch<String>(
                          items: (_, __) => vm.statusOptions,
                          selectedItem: vm.statusFilter == 'Todos'
                              ? null
                              : vm.statusFilter,
                          decoratorProps: DropDownDecoratorProps(
                            decoration: InputDecoration(
                              labelText: t.statusLabel,
                              isDense: true,
                            ),
                          ),
                          popupProps: const PopupProps.menu(),
                          onChanged: (v) => vm.setStatusFilter(v ?? 'Todos'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownSearch<String>(
                          items: (_, __) => vm.clientOptions,
                          selectedItem: vm.clientFilter == 'Todos'
                              ? null
                              : vm.clientFilter,
                          decoratorProps: DropDownDecoratorProps(
                            decoration: InputDecoration(
                              labelText: t.clientLabel,
                              isDense: true,
                            ),
                          ),
                          popupProps: const PopupProps.menu(
                            showSearchBox: true,
                          ),
                          onChanged: (v) => vm.setClientFilter(v ?? 'Todos'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownSearch<String>(
                    items: (_, __) => vm.techOptions,
                    selectedItem: vm.techFilter == 'Todos'
                        ? null
                        : vm.techFilter,
                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: t.technicianLabel,
                        isDense: true,
                      ),
                    ),
                    popupProps: const PopupProps.menu(showSearchBox: true),
                    onChanged: (v) => vm.setTechFilter(v ?? 'Todos'),
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
    required this.onDelete,
  });

  final List<Trabajo> jobs;
  final String role;
  final String userId;
  final String empresaId;
  final String userName;
  final Future<void> Function(Trabajo) onDelete;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noJobsFilterMessage,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
        ),
      );
    }
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
          onDelete: () => onDelete(job),
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
    required this.onDelete,
  });

  final Trabajo job;
  final String role;
  final String userId;
  final String empresaId;
  final String userName;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final canEdit = role != 'PERF_TEC';

    return InkWell(
      onTap: () => _navigateToDetail(context),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (job.costo > 0 && canEdit) ...[
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
                  ],
                ),
              ),
              if (canEdit)
                Column(
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
    if (context.mounted) {
      await context.read<TrabajosViewModel>().cargarTrabajos(empresaId);
    }
  }

  Future<void> _editJob(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobFormScreen(job: job, role: role),
      ),
    );
    if (context.mounted) {
      await context.read<TrabajosViewModel>().cargarTrabajos(empresaId);
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

    if (confirm == true) {
      onDelete();
    }
  }
}
