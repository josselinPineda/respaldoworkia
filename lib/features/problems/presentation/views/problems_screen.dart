import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/models/problem.dart';
import 'package:workia/models/usuario.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/gastos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/problemas_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';
import 'package:workia/features/problems/presentation/viewmodels/problems_screen_viewmodel.dart';
import 'package:workia/features/problems/presentation/widgets/problem_card.dart';
import 'package:workia/widgets/dialogo_reporte_problema.dart';
import 'package:workia/utils/ui_utils.dart'; // For showWorkiaBottomSheet
import 'package:intl/intl.dart';

class ProblemsScreen extends StatelessWidget {
  const ProblemsScreen({super.key, required this.userName, required this.role});

  final String userName;
  final String role;

  @override
  Widget build(BuildContext context) {
    final session = context.read<UserSessionProvider>();
    return ChangeNotifierProvider(
      create: (ctx) => ProblemsScreenViewModel(
        problemasVM: ctx.read<ProblemasViewModel>(),
        trabajosVM: ctx.read<TrabajosViewModel>(),
        asignadosVM: ctx.read<TrabajosAsignadosViewModel>(),
        usuariosVM: ctx.read<UsuariosViewModel>(),
        gastosVM: ctx.read<GastosViewModel>(),
        clientesVM: ctx.read<ClientesViewModel>(),
        empresaId: session.empresaId,
        userId: session.userId,
        userRole: role,
      ),
      child: _ProblemsScreenContent(userName: userName, role: role),
    );
  }
}

class _ProblemsScreenContent extends StatefulWidget {
  const _ProblemsScreenContent({required this.userName, required this.role});

  final String userName;
  final String role;

  @override
  State<_ProblemsScreenContent> createState() => _ProblemsScreenContentState();
}

class _ProblemsScreenContentState extends State<_ProblemsScreenContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _pendingSearchController =
      TextEditingController();
  final TextEditingController _historySearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pendingSearchController.addListener(_onPendingSearchChanged);
    _historySearchController.addListener(_onHistorySearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProblemsScreenViewModel>().loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pendingSearchController.dispose();
    _historySearchController.dispose();
    super.dispose();
  }

  void _onPendingSearchChanged() {
    context.read<ProblemsScreenViewModel>().setPendingSearchQuery(
      _pendingSearchController.text,
    );
  }

  void _onHistorySearchChanged() {
    context.read<ProblemsScreenViewModel>().setHistorySearchQuery(
      _historySearchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final vm = context.watch<ProblemsScreenViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.problemsPageTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t.pendingStatus),
            Tab(text: t.resolvedStatus),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pending Problems Tab
          _ProblemsTab(
            problems: vm.getPendingProblems(context),
            roleOptions: vm.getRoleOptions(context),
            selectedRole: vm.pendingRoleFilter,
            searchController: _pendingSearchController,
            emptyMessage: t.noPendingProblemsMessage,
            onRoleChanged: vm.setPendingRoleFilter,
            onRefresh: vm.loadData,
            role: widget.role,
            isHistory: false,
          ),
          // History Problems Tab
          _ProblemsTab(
            problems: vm.getHistoryProblems(context),
            roleOptions: vm.getRoleOptions(context),
            selectedRole: vm.historyRoleFilter,
            searchController: _historySearchController,
            emptyMessage: t.noHistoryProblemsMessage,
            onRoleChanged: vm.setHistoryRoleFilter,
            onRefresh: vm.loadData,
            role: widget.role,
            isHistory: true,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReportDialog(context, vm),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showReportDialog(BuildContext context, ProblemsScreenViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      builder: (_) => DialogoReporteProblema(
        userName: widget.userName,
        role: widget.role,
        jobs: vm.trabajosVM.trabajos,
        gastos: vm.gastosVM.gastos,
        trabajosAsignados: vm.asignadosVM.trabajos,
        onSave: (problema) async {
          final p = problema.copyWith(empresaId: vm.empresaId);
          await vm.problemasVM.agregar(p);
        },
      ),
    );
  }
}

class _ProblemsTab extends StatelessWidget {
  const _ProblemsTab({
    required this.problems,
    required this.roleOptions,
    required this.selectedRole,
    required this.searchController,
    required this.emptyMessage,
    required this.onRoleChanged,
    required this.onRefresh,
    required this.role,
    required this.isHistory,
  });

  final List<Problema> problems;
  final List<String> roleOptions;
  final String selectedRole;
  final TextEditingController searchController;
  final String emptyMessage;
  final ValueChanged<String> onRoleChanged;
  final RefreshCallback onRefresh;
  final String role;
  final bool isHistory;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: t.searchProblemPlaceholder,
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: roleOptions.contains(selectedRole)
                    ? selectedRole
                    : roleOptions.first,
                decoration: InputDecoration(labelText: t.roleReportedByLabel),
                isExpanded: true,
                items: roleOptions
                    .map(
                      (rol) => DropdownMenuItem(
                        value: rol,
                        child: Text(rol, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => onRoleChanged(v ?? 'Todos'),
              ),
            ],
          ),
        ),
        Expanded(
          child: problems.isEmpty
              ? Center(child: Text(emptyMessage))
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 80,
                    ),
                    itemCount: problems.length,
                    itemBuilder: (context, index) {
                      final problema = problems[index];
                      return ProblemCard(
                        problem: problema,
                        role: role,
                        onTap: () => _showReadOnlyDetails(context, problema),
                        onEdit: () => _showEditDialog(context, problema),
                        onDelete: () => _confirmDelete(context, problema),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, Problema problema) {
    final vm = context.read<ProblemsScreenViewModel>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      builder: (_) => DialogoReporteProblema(
        problema: problema,
        userName: vm.usuariosVM.usuarios
            .firstWhere((u) => u.id == vm.userId, orElse: () => Usuario.empty())
            .nombre,
        role: vm.userRole,
        jobs: vm.trabajosVM.trabajos,
        gastos: vm.gastosVM.gastos,
        trabajosAsignados: vm.asignadosVM.trabajos,
        onSave: (pEditado) async {
          final p = pEditado.copyWith(empresaId: vm.empresaId);
          await vm.problemasVM.actualizar(p);
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Problema problema) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showWorkiaBottomSheet<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.confirmTitle,
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('¿Está seguro de eliminar este problema?'),
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
                    child: Text(t.cancelButton),
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
                    child: Text(t.deleteButton),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final vm = context.read<ProblemsScreenViewModel>();
      await vm.problemasVM.eliminarProblema(
        problema.id,
        vm.empresaId,
        vm.userId,
      );
    }
  }

  void _showReadOnlyDetails(BuildContext context, Problema problema) {
    final vm = context.read<ProblemsScreenViewModel>();
    final t = AppLocalizations.of(context)!;
    final locale = t.localeName;

    final reporter = vm.resolveReporter(problema);
    final jobInfo = vm.resolveJobInfo(
      problema.referenciaId,
      problema.trabajoId,
    );

    // Resolver info del que resolvió
    String resolvedByName = '';
    String resolvedRole = '';
    if (problema.resuelto && problema.resueltoPorId.isNotEmpty) {
      try {
        final u = vm.usuariosVM.usuarios.firstWhere(
          (user) => user.id == problema.resueltoPorId,
        );
        resolvedByName = u.nombre;
        resolvedRole = u.perfilId;
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            problema.titulo,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Fecha
                    Text(
                      '${t.datePrefix}${problema.fechaCreacion != null ? DateFormat.yMd(locale).format(problema.fechaCreacion!) : '-'}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    // Detalles
                    Text(
                      t.problemDetailsLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(problema.descripcion),
                    const SizedBox(height: 16),

                    // Info trabajo
                    if (jobInfo.titulo.isNotEmpty) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        t.jobLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (jobInfo.cliente.isNotEmpty) ...[
                        Text(
                          '${t.clientPrefix}${jobInfo.cliente}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (jobInfo.titulo != problema.titulo)
                        Text('${t.titleLabel}: ${jobInfo.titulo}'),
                      if (jobInfo.direccion.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('${t.addressPrefix}${jobInfo.direccion}'),
                      ],
                      if (jobInfo.fechas.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('${t.datePrefix}${jobInfo.fechas}'),
                      ],
                      if (jobInfo.estado.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('${t.statusLabel}: ${jobInfo.estado}'),
                      ],
                      const SizedBox(height: 16),
                    ],

                    // Reportado por
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      '${t.reportedByPrefix}${reporter.name} (${vm.formatRole(context, reporter.role)})',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),

                    if (problema.resuelto) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${t.resolvedByLabel}: $resolvedByName${resolvedRole.isNotEmpty ? ' (${vm.formatRole(context, resolvedRole)})' : ''}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirmed = await _confirmResolve(context);
                            if (confirmed == true && context.mounted) {
                              await vm.problemasVM.resolver(
                                problema.id,
                                vm.empresaId,
                                vm.userId,
                                vm.userRole,
                              );
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.check_circle),
                          label: Text(t.markAsResolvedButton),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool?> _confirmResolve(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return showWorkiaBottomSheet<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.confirmTitle,
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(t.markAsResolvedConfirmation),
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
                    child: Text(t.cancelButton),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(ctx).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(t.markAsResolvedButton),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
