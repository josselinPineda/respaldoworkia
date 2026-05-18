import 'package:flutter/material.dart';

import 'package:workia/widgets/currency_text.dart';
import 'package:provider/provider.dart';

import '../../models/problem.dart';
import '../../presentation/viewmodels/problemas_viewmodel.dart';
import '../../presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/utils/ui_utils.dart';
import '../../presentation/viewmodels/gastos_viewmodel.dart';
import '../../widgets/dialogo_reporte_problema.dart';
import '../../models/job.dart';
import '../../models/gasto.dart';
import '../../models/trabajo_asignado.dart';
import '../../presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/l10n/app_localizations.dart';
import '../../presentation/providers/user_session_provider.dart';
import '../../presentation/viewmodels/usuarios_viewmodel.dart';
import '../../models/usuario.dart';
import '../../presentation/viewmodels/clientes_viewmodel.dart';
import '../../models/cliente.dart';
import 'package:intl/intl.dart';

/// Página para visualizar y reportar problemas.
///
/// Esta implementación permite filtrar los problemas por texto,
/// tipo de referencia y estado (pendiente, resuelto o ignorado).
/// Al pulsar sobre un problema se abre un diálogo que muestra
/// detalladamente la información del problema seleccionado.
class ProblemsPage extends StatefulWidget {
  const ProblemsPage({super.key, required this.userName, required this.role});

  /// Nombre de usuario actual.  Se utiliza para filtrar los
  /// problemas según quién los reportó, excepto para los
  /// administradores que ven todos los problemas.
  final String userName;

  /// Rol del usuario actual.  Los administradores pueden ver
  /// todos los problemas, mientras que técnicos y finanzas sólo
  /// ven aquellos reportados por ellos mismos.
  final String role;

  @override
  State<ProblemsPage> createState() => _ProblemsPageState();
}

/// Estado asociado a [ProblemsPage].  Gestiona los filtros y la
/// interacción con la lista de problemas, así como la apertura
/// de diálogos para mostrar detalles.
class _ProblemsPageState extends State<ProblemsPage> {
  // Controladores de búsqueda independientes
  final TextEditingController _pendingSearchController =
      TextEditingController();
  final TextEditingController _historySearchController =
      TextEditingController();

  // Roles seleccionados independientes
  String _pendingSelectedRole = 'Todos';
  String _historySelectedRole = 'Todos';

  @override
  void initState() {
    super.initState();
    // Listeners para actualizar la UI al escribir
    _pendingSearchController.addListener(() => setState(() {}));
    _historySearchController.addListener(() => setState(() {}));

    // Cargar datos necesarios para los filtros
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final empresaId = context.read<UserSessionProvider>().empresaId;
      context.read<TrabajosAsignadosViewModel>().cargarTrabajosAsignados(
        empresaId,
      );
      context.read<ProblemasViewModel>().cargarProblemas(empresaId);
      context.read<UsuariosViewModel>().cargarUsuarios(empresaId);
      context.read<TrabajosViewModel>().cargarTrabajos(empresaId);
      context.read<GastosViewModel>().cargarGastos(empresaId);
      context.read<ClientesViewModel>().cargarClientes(empresaId);
    });
  }

  @override
  void dispose() {
    _pendingSearchController.dispose();
    _historySearchController.dispose();
    super.dispose();
  }

  /// Resuelve el nombre y rol del reportante
  ({String name, String role}) _resolveReporter(
    Problema p,
    List<Usuario> users,
  ) {
    String name = p.nombreReportante;
    String role = p.rolReportante;

    if (p.reportadoPorId.isNotEmpty) {
      try {
        final u = users.firstWhere((user) => user.id == p.reportadoPorId);
        name = u.nombre;
        role = u.perfilId;
      } catch (_) {}
    }
    return (name: name, role: role);
  }

  /// Aplica filtros a una lista de problemas
  List<Problema> _applyFilters(
    List<Problema> problems,
    List<Usuario> users,
    String query,
    String roleFilter,
    String? assignmentId,
  ) {
    var list = problems;
    final q = query.trim().toLowerCase();

    // Filtrar por texto
    if (q.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.title.toLowerCase().contains(q) ||
                p.details.toLowerCase().contains(q),
          )
          .toList();
    }

    // Filtrar por rol (ahora el valor es "Rol - Nombre")
    if (roleFilter != 'Todos') {
      list = list.where((p) {
        final resolved = _resolveReporter(p, users);
        final formattedRole = _formatRole(resolved.role);
        final key = '$formattedRole - ${resolved.name}';
        return key == roleFilter;
      }).toList();
    }

    // Filtrar por asignación de trabajo específica
    if (assignmentId != null && assignmentId.isNotEmpty) {
      list = list.where((p) => p.trabajoAsignadoId == assignmentId).toList();
    }

    return list;
  }

  /// Helper para resolver información de trabajo robustamente
  static ({
    String titulo,
    String cliente,
    String direccion,
    String descripcion,
    String fechas,
    String estado,
  })
  _resolveJobInfo(
    String? refId,
    String? fallbackJobId,
    List<TrabajoAsignado> asignaciones,
    List<Job> trabajos,
    List<Cliente> clientes,
  ) {
    // DEBUG LOGS
    // DEBUG LOGS

    if ((refId == null || refId.isEmpty) &&
        (fallbackJobId == null || fallbackJobId.isEmpty)) {
      return (
        titulo: '',
        cliente: '',
        direccion: '',
        descripcion: '',
        fechas: '',
        estado: '',
      );
    }

    String titulo = '';
    String clienteName = '';
    String direccion = '';
    String descripcion = '';
    String fechas = '';
    String estado = '';
    String? clienteId;
    String? trabajoId;
    DateTime? fInicio;
    DateTime? fFin;

    // 1. Intentar buscar como Asignación
    try {
      if (refId != null) {
        final asig = asignaciones.firstWhere((a) => a.id == refId);
        titulo = asig.tituloTrabajo;
        clienteId = asig.clienteId;
        trabajoId = asig.trabajoId;
        estado = asig.estado;
        fInicio = asig.fechaInicio;
        fFin = asig.fechaFin;
      }
    } catch (_) {}

    // 2. Si titulo vacio, buscar en catálogo de trabajos
    if (titulo.isEmpty) {
      // Prioridad:
      // 1. trabajoId de asignación
      // 2. fallbackJobId
      // 3. refId (si fuera ID directo de trabajo)
      // 4. PARSEO INTELIGENTE: Si refId es de asignacion (ASIG_...) extraer el ID de trabajo

      String? idToSearch = (trabajoId != null && trabajoId.isNotEmpty)
          ? trabajoId
          : (fallbackJobId != null && fallbackJobId.isNotEmpty)
          ? fallbackJobId
          : refId;

      // LOGICA DE PARSEO DE LEGADO
      if ((idToSearch == null || idToSearch == refId) &&
          refId != null &&
          refId.startsWith('ASIG_')) {
        // Formato: ASIG_[JOB_ID]__[CLIENT_ID]_[TIMESTAMP]
        final parts = refId.split('__');
        if (parts.isNotEmpty) {
          final firstPart = parts[0]; // ASIG_[JOB_ID]
          if (firstPart.length > 5) {
            final extractedId = firstPart.substring(5); // [JOB_ID]
            // Solo usamos este si no teniamos nada mejor
            if (idToSearch == refId) {
              idToSearch = extractedId;
            }
          }
        }
      }

      if (idToSearch != null && idToSearch.isNotEmpty) {
        try {
          final t = trabajos.firstWhere((j) => j.id == idToSearch);
          titulo = t.titulo;

          if (descripcion.isEmpty) descripcion = t.descripcion;

          // Solo sobrescribir estado si no lo teníamos (ej. null assignment)
          if (estado.isEmpty) estado = t.estado;

          // Solo sobrescribir fechas si no las teníamos
          if (fInicio == null || fFin == null) {
            fInicio = t.fechaInicio;
            fFin = t.fechaFin;
          }

          if (clienteId == null || clienteId.isEmpty) {
            clienteId = t.clienteId;
            if (clienteId.isEmpty) clienteName = t.cliente;
          }
        } catch (_) {
          titulo = '';
        }
      }
    }

    // Formatear fechas si existen
    if (fInicio != null && fFin != null) {
      final df = DateFormat('dd/MM/yyyy');
      final isSameDay =
          fInicio.year == fFin.year &&
          fInicio.month == fFin.month &&
          fInicio.day == fFin.day;

      if (isSameDay) {
        fechas = df.format(fInicio);
      } else {
        fechas = '${df.format(fInicio)} - ${df.format(fFin)}';
      }
    }

    // 3. Resolver Cliente si tenemos ID
    if (clienteId != null && clienteId.isNotEmpty) {
      try {
        final c = clientes.firstWhere((cl) => cl.id == clienteId);
        clienteName = c.nombre;
        direccion = c.direccion;
      } catch (_) {}
    }

    return (
      titulo: titulo,
      cliente: clienteName,
      direccion: direccion,
      descripcion: descripcion,
      fechas: fechas,
      estado: estado,
    );
  }

  /// Confirmar y marcar como resuelto
  Future<void> _confirmarResolver(Problema problema) async {
    final confirmed = await showWorkiaBottomSheet<bool>(
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
        );
      },
    );

    if (confirmed == true) {
      if (!mounted) return;
      final problemasVM = context.read<ProblemasViewModel>();
      final userId = context.read<UserSessionProvider>().userId;
      await problemasVM.resolver(
        problema.id,
        problema.empresaId,
        userId,
        widget.role,
      );
    }
  }

  /// Confirmar y eliminar problema
  Future<void> _confirmarEliminar(Problema problema) async {
    final confirmed = await showWorkiaBottomSheet<bool>(
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
                t.confirmTitle,
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('¿Está seguro de que desea eliminar este problema?'),
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
        );
      },
    );

    if (confirmed == true) {
      if (!mounted) return;
      final problemasVM = context.read<ProblemasViewModel>();
      final userId = context.read<UserSessionProvider>().userId;
      await problemasVM.eliminarProblema(
        problema.id,
        problema.empresaId,
        userId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final problemasVM = context.watch<ProblemasViewModel>();
    final trabajosAsignadosVM = context.watch<TrabajosAsignadosViewModel>();
    final usuariosVM = context.watch<UsuariosViewModel>();
    final trabajosVM = context.watch<TrabajosViewModel>();
    final gastosVM = context.watch<GastosViewModel>();

    // 3. Obtener mis asignaciones para filtrar (movido arriba para usar en filtro inicial)
    // NOTE: Se usa read en lugar de watch para userId para evitar rebuilds innecesarios si solo eso cambia,
    // pero idealmente deberia ser consistente.
    final userId = context.read<UserSessionProvider>().userId;
    // Usamos la lista completa de asignados para filtrar los mios
    final myAssignments = trabajosAsignadosVM.trabajos
        .where((t) => t.tecnicosAsignados.contains(userId))
        .toList();

    // 0. Filtrar lista maestra si es técnico
    List<Problema> masterList = problemasVM.problemas;
    if (widget.role == 'PERF_TEC') {
      masterList = masterList.where((p) {
        // 1. Reportado por mi
        if (p.reportadoPorId == userId) return true;

        // 2. Relacionado con trabajo asignado a mi
        if (p.referenciaTipo == 'Trabajo' && p.referenciaId != null) {
          // Chequear si referenciaId coincide con ID de asignacion o ID de trabajo
          // En mis asignaciones tengo: id (asignacion) y trabajoId (trabajo original)
          final isMyAssignment = myAssignments.any(
            (a) => a.id == p.referenciaId || a.trabajoId == p.referenciaId,
          );
          if (isMyAssignment) return true;
        }

        return false;
      }).toList();
    }

    if (widget.role == 'PERF_TEC') {}

    // 1. Separar pendientes vs historial usando la lista filtrada
    final pendingProblems = masterList
        .where((p) => !p.resuelto && !p.ignorado)
        .toList();
    final historyProblems = masterList
        .where((p) => p.resuelto || p.ignorado)
        .toList();

    // 2. Obtener roles disponibles para el filtro usando datos resueltos
    final allRoles = masterList
        .map((p) {
          final resolved = _resolveReporter(p, usuariosVM.usuarios);
          final formattedRole = _formatRole(resolved.role);
          return '$formattedRole - ${resolved.name}';
        })
        .toSet()
        .toList();
    allRoles.sort();
    final roleOptions = ['Todos', ...allRoles];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.problemsPageTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: AppLocalizations.of(context)!.pendingStatus),
              Tab(text: AppLocalizations.of(context)!.resolvedStatus),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pestaña Pendientes
            _buildTabContent(
              problems: pendingProblems,
              users: usuariosVM.usuarios,
              searchController: _pendingSearchController,
              selectedRole: _pendingSelectedRole,
              roleOptions: roleOptions,
              onRoleChanged: (val) {
                if (val != null) setState(() => _pendingSelectedRole = val);
              },
              emptyMessage: AppLocalizations.of(
                context,
              )!.noPendingProblemsMessage,
              myAssignments: myAssignments,
              trabajos: trabajosVM.trabajos,
              gastos: gastosVM.gastos,
              trabajosAsignados: trabajosAsignadosVM.trabajos,
            ),
            // Pestaña Historial
            _buildTabContent(
              problems: historyProblems,
              users: usuariosVM.usuarios,
              searchController: _historySearchController,
              selectedRole: _historySelectedRole,
              roleOptions: roleOptions,
              onRoleChanged: (val) {
                if (val != null) setState(() => _historySelectedRole = val);
              },
              emptyMessage: AppLocalizations.of(
                context,
              )!.noHistoryProblemsMessage,
              myAssignments: myAssignments,
              trabajos: trabajosVM.trabajos,
              gastos: gastosVM.gastos,
              trabajosAsignados: trabajosAsignadosVM.trabajos,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Mostrar el diálogo reutilizable para reportar problema.
            final trabajosVM = context.read<TrabajosViewModel>();
            final gastosVM = context.read<GastosViewModel>();
            final trabajosAsignadosVM = context
                .read<TrabajosAsignadosViewModel>();

            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              enableDrag: false,
              isDismissible: false,
              builder: (ctx) => DialogoReporteProblema(
                userName: widget.userName,
                role: widget.role,
                jobs: trabajosVM.trabajos,
                gastos: gastosVM.gastos,
                trabajosAsignados: trabajosAsignadosVM.trabajos,
                onSave: (problema) async {
                  try {
                    final session = context.read<UserSessionProvider>();
                    final empresaId = session.empresaId;
                    if (empresaId.isEmpty) throw 'No se encontró el ID de la empresa';
                    
                    final p = problema.copyWith(empresaId: empresaId);
                    await problemasVM.agregar(p);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Problema reportado con éxito')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al reportar: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTabContent({
    required List<Problema> problems,
    required List<Usuario> users,
    required TextEditingController searchController,
    required String selectedRole,
    required List<String> roleOptions,
    required Function(String?) onRoleChanged,
    required String emptyMessage,
    required List<TrabajoAsignado> myAssignments,
    required List<Job> trabajos,
    required List<Gasto> gastos,
    required List<TrabajoAsignado> trabajosAsignados,
  }) {
    // Validar que la selección actual exista en las opciones, si no, resetear a 'Todos'
    final validSelectedRole = roleOptions.contains(selectedRole)
        ? selectedRole
        : 'Todos';

    final filtered = _applyFilters(
      problems,
      users,
      searchController.text,
      validSelectedRole,
      null,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.searchProblemPlaceholder,
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: validSelectedRole,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.roleReportedByLabel,
                ),
                isExpanded: true,
                items: roleOptions
                    .map(
                      (rol) => DropdownMenuItem(
                        value: rol,
                        child: Text(rol, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: onRoleChanged,
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text(emptyMessage))
              : RefreshIndicator(
                  onRefresh: () async {
                    final problemasVM = context.read<ProblemasViewModel>();
                    final trabajosAsignadosVM = context
                        .read<TrabajosAsignadosViewModel>();
                    final usuariosVM = context.read<UsuariosViewModel>();
                    final trabajosVM = context.read<TrabajosViewModel>();
                    final gastosVM = context.read<GastosViewModel>();
                    final clientesVM = context.read<ClientesViewModel>();

                    final empresaId = context
                        .read<UserSessionProvider>()
                        .empresaId;
                    await Future.wait([
                      problemasVM.cargarProblemas(empresaId),
                      trabajosAsignadosVM.cargarTrabajosAsignados(empresaId),
                      usuariosVM.cargarUsuarios(empresaId),
                      trabajosVM.cargarTrabajos(empresaId),
                      gastosVM.cargarGastos(empresaId),
                      clientesVM.cargarClientes(empresaId),
                    ]);
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final problema = filtered[index];
                      return _ProblemCard(
                        problem: problema,
                        role: widget.role,
                        trabajos: trabajos,
                        gastos: gastos,
                        trabajosAsignados: trabajosAsignados,
                        onTap: () => _showReadOnlyDetails(context, problema),
                        onEdit: () => _showProblemDetails(context, problema),
                        onDelete: () => _confirmarEliminar(problema),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _showProblemDetails(BuildContext context, Problema problema) {
    final empresaId = context.read<UserSessionProvider>().empresaId;
    final trabajosVM = context.read<TrabajosViewModel>();
    final gastosVM = context.read<GastosViewModel>();
    final trabajosAsignadosVM = context.read<TrabajosAsignadosViewModel>();
    final problemasVM = context.read<ProblemasViewModel>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      builder: (_) => DialogoReporteProblema(
        problema: problema,
        userName: widget.userName,
        role: widget.role,
        jobs: trabajosVM.trabajos,
        gastos: gastosVM.gastos,
        trabajosAsignados: trabajosAsignadosVM.trabajos,
        onSave: (pEditado) async {
          final p = pEditado.copyWith(empresaId: empresaId);
          await problemasVM.actualizar(p);
        },
      ),
    );
  }

  String _formatRole(String role) {
    switch (role) {
      case 'PERF_ADMIN':
        return AppLocalizations.of(context)!.adminRole;
      case 'PERF_TEC':
        return AppLocalizations.of(context)!.technicianRole;
      case 'PERF_FIN':
        return AppLocalizations.of(context)!.financeRole;
      default:
        return role;
    }
  }

  void _showReadOnlyDetails(BuildContext context, Problema problema) {
    final usuariosVM = context.read<UsuariosViewModel>();
    final trabajosVM = context.read<TrabajosViewModel>();
    final asignadosVM = context.read<TrabajosAsignadosViewModel>();
    final clientesVM = context.read<ClientesViewModel>();

    // Resolver nombre del reportante
    String reportedByName = problema.nombreReportante;
    String reportedByRole = problema.rolReportante;
    if (problema.reportadoPorId.isNotEmpty) {
      try {
        final u = usuariosVM.usuarios.firstWhere(
          (user) => user.id == problema.reportadoPorId,
        );
        reportedByName = u.nombre;
        reportedByRole = u.perfilId;
      } catch (_) {}
    }

    // Resolver nombre del que resolvió
    String resolvedByName = problema.resueltoPorId;
    if (problema.resuelto && problema.resueltoPorId.isNotEmpty) {
      try {
        final u = usuariosVM.usuarios.firstWhere(
          (user) => user.id == problema.resueltoPorId,
        );
        resolvedByName = u.nombre;
      } catch (_) {}
    }

    // Resolver información del trabajo (si aplica)
    // Resolver información del trabajo (si aplica)
    String jobTitle = '';
    String clientName = '';
    String jobAddress = '';
    // Inicializar vacios para el resto de info
    var info = (
      titulo: '',
      cliente: '',
      direccion: '',
      descripcion: '',
      fechas: '',
      estado: '',
    );

    if (problema.referenciaTipo == 'Trabajo') {
      info = _resolveJobInfo(
        problema.referenciaId,
        problema.trabajoId,
        asignadosVM.trabajos,
        trabajosVM.trabajos,
        clientesVM.clientes,
      );
      jobTitle = info.titulo;
      clientName = info.cliente;
      jobAddress = info.direccion;

      // Fallback ID si no se encontró título
      if (jobTitle.isEmpty) {
        jobTitle =
            '${AppLocalizations.of(context)!.jobIdLabel} ${problema.referenciaId}';
      }
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
            final t = AppLocalizations.of(context)!;
            final locale = t.localeName;
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con título y botón de cerrar
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

                    // Fecha de reporte
                    // Fecha de reporte
                    Text(
                      'Fecha del problema: ${problema.fechaCreacion != null ? DateFormat.yMd(locale).format(problema.fechaCreacion!) : '-'}',
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

                    // Información del Trabajo (si existe)
                    if (jobTitle.isNotEmpty) ...[
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
                      if (clientName.isNotEmpty) ...[
                        Text(
                          '${t.clientPrefix}$clientName',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (jobTitle.isNotEmpty && jobTitle != problema.titulo)
                        Text('${t.titleLabel}: $jobTitle'),

                      if (jobAddress.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('${t.addressPrefix}$jobAddress'),
                      ],
                      if (info.fechas.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('${t.datePrefix}${info.fechas}'),
                      ],
                      if (info.estado.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('${t.statusLabel}: ${info.estado}'),
                      ],
                      if (info.descripcion.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          t.descriptionLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(info.descripcion),
                      ],
                      const SizedBox(height: 16),
                    ],

                    // Reportado por
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      '${t.reportedByPrefix}$reportedByName (${_formatRole(reportedByRole)})',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    if (problema.resuelto) ...[
                      const SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          // Resolver nombre del que resolvió para mostrar
                          String rName = resolvedByName;
                          String rRole = '';
                          if (problema.resueltoPorId.isNotEmpty) {
                            try {
                              final u = usuariosVM.usuarios.firstWhere(
                                (user) => user.id == problema.resueltoPorId,
                              );
                              rName = u.nombre;
                              rRole = u.perfilId;
                            } catch (_) {}
                          }
                          final rRoleStr = rRole.isNotEmpty
                              ? ' (${_formatRole(rRole)})'
                              : '';

                          return Text(
                            '${AppLocalizations.of(context)!.resolvedByLabel}: $rName$rRoleStr',
                            style: const TextStyle(
                              color: Colors.green,
                              fontStyle: FontStyle.italic,
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _confirmarResolver(problema);
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check_circle),
                          label: Text(
                            AppLocalizations.of(context)!.markAsResolvedButton,
                          ),
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
}

/// Tarjeta para mostrar un problema individual en la lista.
class _ProblemCard extends StatelessWidget {
  const _ProblemCard({
    required this.problem,
    required this.role,
    required this.trabajos,
    required this.gastos,
    required this.trabajosAsignados,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final Problema problem;
  final String role;
  final List<Job> trabajos;
  final List<Gasto> gastos;
  final List<TrabajoAsignado> trabajosAsignados;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  // Helper para formatear roles
  String formatRole(BuildContext context, String role) {
    switch (role) {
      case 'PERF_ADMIN':
        return AppLocalizations.of(context)!.roleAdmin;
      case 'PERF_TEC':
        return AppLocalizations.of(context)!.roleTech;
      case 'PERF_FIN':
        return AppLocalizations.of(context)!.roleFinance;
      default:
        return role;
    }
  }

  String _getResolverName(Problema problem, UsuariosViewModel usuariosVM) {
    if (!problem.resuelto) return '';
    // Usar resueltoPorId si existe, sino fallback a actualizadoPorId (legacy)
    final idToUse = problem.resueltoPorId.isNotEmpty
        ? problem.resueltoPorId
        : problem.actualizadoPorId;

    if (idToUse.isEmpty) return '';

    try {
      final user = usuariosVM.usuarios.firstWhere((u) => u.id == idToUse);
      return user.nombre;
    } catch (_) {
      return idToUse;
    }
  }

  String _getResolverRole(Problema problem, UsuariosViewModel usuariosVM) {
    if (!problem.resuelto) return '';
    // Usar resueltoPorId si existe, sino fallback a actualizadoPorId (legacy)
    final idToUse = problem.resueltoPorId.isNotEmpty
        ? problem.resueltoPorId
        : problem.actualizadoPorId;

    if (idToUse.isEmpty) return '';

    try {
      final user = usuariosVM.usuarios.firstWhere((u) => u.id == idToUse);
      return user.perfilId;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener ViewModel de usuarios para buscar nombres por ID
    final usuariosVM = context.read<UsuariosViewModel>();

    // Buscar usuario reportante
    Usuario? reportante;
    try {
      if (problem.reportadoPorId.isNotEmpty) {
        reportante = usuariosVM.usuarios.firstWhere(
          (u) => u.id == problem.reportadoPorId,
        );
      }
    } catch (_) {
      reportante = null;
    }

    final nombreReportante = reportante?.nombre ?? problem.nombreReportante;
    final rolReportante = reportante?.perfilId ?? problem.rolReportante;

    Widget refWidget;
    String refText =
        '${AppLocalizations.of(context)!.typeLabel}: ${problem.referenciaTipo}';
    refWidget = Text(refText, style: const TextStyle(fontSize: 12));

    if (problem.referenciaTipo == 'Trabajo' && problem.referenciaId != null) {
      final info = _ProblemsPageState._resolveJobInfo(
        problem.referenciaId,
        problem.trabajoId,
        trabajosAsignados,
        trabajos,
        [],
      );

      String titulo = info.titulo;

      if (titulo.isNotEmpty) {
        if (info.fechas.isNotEmpty) {
          refText =
              '${AppLocalizations.of(context)!.assignedJobLabel}: $titulo - ${info.fechas}';
        } else {
          refText = '${AppLocalizations.of(context)!.jobLabel}: $titulo';
        }
      } else {
        refText =
            '${AppLocalizations.of(context)!.jobIdLabel} ${problem.referenciaId}';
      }

      if (titulo.isEmpty) {
        refText =
            '${AppLocalizations.of(context)!.jobIdLabel} ${problem.referenciaId}';
      }
      refWidget = Text(refText, style: const TextStyle(fontSize: 12));
    } else if (problem.referenciaTipo == 'Gasto' &&
        problem.referenciaId != null) {
      final matching = gastos
          .where((g) => g.id == problem.referenciaId)
          .toList();
      if (matching.isNotEmpty) {
        final gasto = matching.first;
        refWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppLocalizations.of(context)!.expenseLabel}: ',
              style: const TextStyle(fontSize: 12),
            ),
            CurrencyText(gasto.monto, style: const TextStyle(fontSize: 12)),
          ],
        );
      } else {
        refText =
            '${AppLocalizations.of(context)!.expenseIdLabel} ${problem.referenciaId}';
        refWidget = Text(refText, style: const TextStyle(fontSize: 12));
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias, // Ensure InkWell ripple is clipped
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      problem.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppLocalizations.of(context)!.reportedByPrefix}$nombreReportante (${formatRole(context, rolReportante)})',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (problem.referenciaTipo == 'Trabajo' &&
                        problem.referenciaId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: refWidget,
                      ),
                    if (problem.resuelto)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Builder(
                          builder: (context) {
                            final rName = _getResolverName(problem, usuariosVM);
                            final rRole = _getResolverRole(problem, usuariosVM);
                            final rRoleStr = rRole.isNotEmpty
                                ? ' (${formatRole(context, rRole)})'
                                : '';
                            return Text(
                              '${AppLocalizations.of(context)!.resolvedByLabel}: $rName$rRoleStr',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (role != 'PERF_TEC')
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                  tooltip: AppLocalizations.of(context)!.editButton,
                ),
              if (role != 'PERF_TEC')
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: onDelete,
                  tooltip: AppLocalizations.of(context)!.deleteButton,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
