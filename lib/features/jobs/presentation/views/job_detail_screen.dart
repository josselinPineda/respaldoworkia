import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/models/job.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/sesiones_viewmodel.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';
import 'package:workia/features/jobs/presentation/views/job_form_screen.dart';
import 'package:workia/features/jobs/presentation/viewmodels/job_detail_viewmodel.dart';
import 'package:workia/features/jobs/presentation/widgets/job_clients_list.dart';

/// Pantalla de detalle de un trabajo.
///
/// Esta Vista es puramente declarativa:
/// - Consume estado del [JobDetailViewModel].
/// - Dispara eventos al ViewModel.
/// - No contiene lógica de negocio, filtros ni cálculos.
class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({
    super.key,
    required this.job,
    required this.role,
    required this.userName,
  });

  final Trabajo job;
  final String role;
  final String userName;

  @override
  Widget build(BuildContext context) {
    // Obtener dependencias de ViewModels de datos
    final clientesVM = context.read<ClientesViewModel>();
    final asignadosVM = context.read<TrabajosAsignadosViewModel>();
    final usuariosVM = context.read<UsuariosViewModel>();
    final sesionesVM = context.read<SesionesViewModel>();
    final userProvider = context.read<UserSessionProvider>();

    // Proveer el ViewModel específico de esta pantalla
    return ChangeNotifierProvider(
      create: (_) => JobDetailViewModel(
        clientesVM: clientesVM,
        asignadosVM: asignadosVM,
        usuariosVM: usuariosVM,
        sesionesVM: sesionesVM,
        job: job,
        userRole: role,
        userName: userName,
        currentUserId: userProvider.userId,
      ),
      child: _JobDetailScreenContent(job: job, role: role),
    );
  }
}

class _JobDetailScreenContent extends StatefulWidget {
  const _JobDetailScreenContent({required this.job, required this.role});

  final Trabajo job;
  final String role;

  @override
  State<_JobDetailScreenContent> createState() =>
      _JobDetailScreenContentState();
}

class _JobDetailScreenContentState extends State<_JobDetailScreenContent> {
  @override
  void initState() {
    super.initState();
    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final clientesVM = context.read<ClientesViewModel>();
    final asignadosVM = context.read<TrabajosAsignadosViewModel>();
    final usuariosVM = context.read<UsuariosViewModel>();

    await Future.wait([
      clientesVM.cargarClientes(widget.job.empresaId),
      asignadosVM.cargarTrabajosAsignados(widget.job.empresaId),
      usuariosVM.cargarUsuarios(widget.job.empresaId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.job.titulo),
        actions: [
          if (widget.role != 'PERF_TEC')
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: t.editJobTooltip,
              onPressed: () => _navigateToEditJob(context),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: JobClientsList(),
        ),
      ),
    );
  }

  Future<void> _navigateToEditJob(BuildContext context) async {
    final asignadosVM = context.read<TrabajosAsignadosViewModel>();
    await asignadosVM.cargarTrabajosAsignados(widget.job.empresaId);
    if (!context.mounted) return;

    final trabajosVM = context.read<TrabajosViewModel>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JobFormScreen(job: widget.job, role: widget.role),
      ),
    );
    if (!context.mounted) return;

    await trabajosVM.cargarTrabajos(widget.job.empresaId);
  }
}
