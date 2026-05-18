import 'package:flutter/material.dart';
import 'package:workia/utils/ui_utils.dart';

import 'package:workia/views/settings/user_settings_page.dart';
import 'package:workia/models/material_expense.dart';
import 'package:workia/models/expenses_repository.dart';
// La clase Problem se utiliza Ãºnicamente en el repositorio de problemas y en la
// pÃ¡gina de problemas.  Ya no se crean problemas directamente en esta pÃ¡gina,
// por lo que se elimina la importaciÃ³n de Problem.
// import 'package:workia/models/problems_repository.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:workia/presentation/viewmodels/problemas_viewmodel.dart';

import 'package:workia/presentation/viewmodels/gastos_viewmodel.dart';
import 'package:workia/features/activities/presentation/viewmodels/actividades_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
// Importar ViewModel de trabajos asignados para obtener el estado desde la colecciÃ³n
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/presentation/viewmodels/sesiones_viewmodel.dart';
import 'package:workia/views/jobs/job_detail_page.dart';
// Importar modelo de trabajo para usar su tipo en el calendario
import 'package:workia/models/job.dart';
import 'package:workia/models/sesion_trabajo.dart';
import 'package:workia/models/trabajo_asignado.dart';
import 'package:workia/models/usuario.dart';
import 'package:workia/views/problems/problems_page.dart';
// Importar diÃ¡logo reutilizable para reportar problemas
import 'package:workia/widgets/dialogo_reporte_problema.dart';
// Para obtener nombres de clientes desde las asignaciones
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/viewmodels/empresa_viewmodel.dart';
import 'package:workia/domain/repositories/trabajo_asignado_repository.dart';
import 'package:workia/models/cliente.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/widgets/currency_text.dart';
import 'package:intl/intl.dart';

/// PÃ¡gina de agenda que combina un resumen del tablero con un
/// calendario, los trabajos del dÃ­a, acciones rÃ¡pidas y un
/// formulario para registrar actividades.  Las actividades
/// guardadas mediante el formulario se muestran en una lista.
/// Esta pÃ¡gina mantiene estado para conservar los datos del
/// formulario y la lista de actividades.
class AgendaPage extends StatefulWidget {
  const AgendaPage({
    super.key,
    required this.userName,
    required this.role,
    required this.userId,
    required this.empresaId,
  });
  final String userName;
  final String role;

  /// Identificador del usuario que ha iniciado sesiÃ³n.
  final String userId;

  /// Identificador de la empresa asociada al usuario.
  final String empresaId;

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  // Estado del calendario.  [_currentMonth] determina el mes actualmente
  // visible en el calendario.  [_selectedDate] guarda la fecha que el
  // usuario ha seleccionado para ver sus trabajos.  Cuando es nula,
  // no se muestra ninguna lista de trabajos para una fecha concreta.
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate = DateTime.now();
  DateTimeRange? _registeredHoursRange;
  double? _registeredHoursRangeTotal;
  String? _registeredHoursTechId; // null = todos (solo admin/supervisor)

  // Mapa que asigna a cada trabajo un color Ãºnico para
  // representarlo en el calendario.  De esta forma las fechas
  // con trabajos se colorean con diferentes tonos.  El color se
  // asigna la primera vez que se encuentra el trabajo.
  final Map<String, Color> _jobColors = {};

  // === Filtros y bÃºsqueda para los trabajos de un dÃ­a ===
  // Se han eliminado los campos de bÃºsqueda y estado a nivel de agenda.
  // El filtrado de trabajos se gestiona desde los modales donde se
  // muestran las listas de trabajos, por lo que no es necesario mantener
  // estos estados en el propio widget de la agenda.

  /// Devuelve un color asociado al identificador del trabajo.  Si
  /// aÃºn no se ha asignado, se elige el siguiente color de una
  /// lista predefinida de tonos y se guarda en [_jobColors].
  Color _colorForJob(String jobId) {
    final palette = [
      Theme.of(context).primaryColor,
      Colors.green,
      Theme.of(context).primaryColor.withValues(alpha: 0.8),
      Colors.orange,
      Colors.teal,
      Colors.red,
      Theme.of(context).primaryColor.withValues(alpha: 0.6),
      Colors.pink,
    ];
    if (_jobColors.containsKey(jobId)) {
      return _jobColors[jobId]!;
    }
    final color = palette[_jobColors.length % palette.length];
    _jobColors[jobId] = color;
    return color;
  }

  // Se eliminaron las variables asociadas al formulario de
  // registro de actividades (_selectedJob, _selectedStatus,
  // _startTime, _endTime, _breakController, _notesController y
  // _activities) porque este formulario ya no se utiliza.  Esto
  // simplifica el estado de la agenda.

  /// Lista de trabajos correspondientes a la fecha actualmente
  /// Lista de trabajos para la fecha seleccionada.  Aunque se mantiene
  /// aquÃ­ para fines internos (por ejemplo, mÃ©tricas), ya no se muestra
  /// debajo del calendario.  Al seleccionar una fecha se muestra un
  /// modal con los trabajos correspondientes.

  /// Convierte una lista de [TrabajoAsignado] en una lista de [Trabajo]
  /// utilizando la informaciÃ³n del catÃ¡logo de trabajos para completar
  /// campos como tÃ­tulo, descripciÃ³n, cliente y costo.  El estado,
  /// fechas y tÃ©cnicos se obtienen de la asignaciÃ³n.  Esta funciÃ³n
  /// facilita reutilizar componentes existentes que consumen instancias
  /// de [Trabajo] en lugar de [TrabajoAsignado].
  List<Trabajo> _mapAsignacionesToTrabajos(
    List<TrabajoAsignado> asignaciones,
    List<Trabajo> catalogo,
  ) {
    // Obtener nombres de clientes desde el view model para cada asignaciÃ³n.
    final clientesVM = context.read<ClientesViewModel>();
    final clientesList = clientesVM.clientes;
    final usuariosVM = context.read<UsuariosViewModel>();
    final usuariosList = usuariosVM.usuarios;
    return asignaciones.map((a) {
      // Buscar el trabajo de catÃ¡logo asociado o crear uno mÃ­nimo.
      final Trabajo base = catalogo.firstWhere(
        (t) => t.id == a.trabajoId,
        orElse: () => Trabajo(
          id: a.trabajoId,
          titulo: a.tituloTrabajo.isNotEmpty ? a.tituloTrabajo : a.trabajoId,
          cliente: '',
          clienteId: a.clienteId.isNotEmpty ? a.clienteId : '',
          fechaInicio: a.fechaInicio,
          fechaFin: a.fechaFin,
          estado: a.estado.replaceAll('_', ' '),
          descripcion: '',
          costo: 0.0,
          esCiclico: a.esCiclico,
          frecuenciaCiclico: a.frecuenciaCiclico,
          proximaFecha: a.proximaFecha,
          empleadosAsignados: a.tecnicosAsignados,
          clientesAsignados: const [],
          empresaId: a.empresaId,
        ),
      );
      // Obtener el nombre del cliente asociado a la asignaciÃ³n
      String clientName = '';
      if (a.clienteId.isNotEmpty) {
        final match = clientesList.firstWhere(
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
        clientName = match.nombre;
      }
      final clientesAsignados = <String>[];
      if (clientName.isNotEmpty) {
        clientesAsignados.add(clientName);
      } else if (base.cliente.isNotEmpty) {
        clientesAsignados.add(base.cliente);
      }

      // Convertir las IDs de tÃ©cnicos a nombres para mostrar en
      // filtros y tarjetas.  Si no se encuentra el usuario, se
      // conserva el ID.
      final List<String> techNames = a.tecnicosAsignados.map((techId) {
        final user = usuariosList.firstWhere(
          (u) => u.id == techId,
          orElse: () => Usuario(
            id: '',
            authUid: '',
            nombre: techId,
            email: '',
            idEmpresa: '',
            perfilId: '',
          ),
        );
        return user.nombre;
      }).toList();
      // Construir un trabajo utilizando la informaciÃ³n disponible.  Se
      // toma como base el trabajo de catÃ¡logo, pero se sobreescriben
      // campos especÃ­ficos de la asignaciÃ³n (fechas, estado, tÃ©cnicos).
      return Trabajo(
        id: a.id.isNotEmpty ? a.id : a.trabajoId,
        titulo: a.tituloTrabajo.isNotEmpty ? a.tituloTrabajo : base.titulo,
        cliente: clientName.isNotEmpty ? clientName : base.cliente,
        clienteId: a.clienteId.isNotEmpty ? a.clienteId : base.clienteId,
        fechaInicio: a.fechaInicio,
        fechaFin: a.fechaFin,
        estado: a.estado.replaceAll('_', ' '),
        descripcion: base.descripcion,
        costo: a.precioFinal,
        esCiclico: a.esCiclico,
        frecuenciaCiclico: a.frecuenciaCiclico,
        proximaFecha: a.proximaFecha,
        empleadosAsignados: techNames,
        clientesAsignados: clientesAsignados,
        empresaId: base.empresaId.isNotEmpty ? base.empresaId : a.empresaId,
        fechaCreacion: base.fechaCreacion,
        fechaActualizacion: base.fechaActualizacion,
        creadoPor: base.creadoPor,
        actualizadoPor: base.actualizadoPor,
        latitud: base.latitud,
        longitud: base.longitud,
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // Cargar problemas pendientes al iniciar la pÃ¡gina.  Se usa un
    // callback postâ€‘frame para acceder al contexto de Provider.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Por defecto, al entrar a la agenda se selecciona el dÃ­a actual.
      // Esto hace que "Horas registradas" se base en la fecha de hoy si no hay rango.
      _selectedDate ??= DateTime.now();
      context.read<ProblemasViewModel>().cargarProblemas(widget.empresaId);
      // Cargar trabajos asignados para mostrar el estado correcto en la agenda.
      await context.read<TrabajosAsignadosViewModel>().cargarTrabajosAsignados(
        widget.empresaId,
      );
      // Cargar todas las actividades para calcular mÃ©tricas
      context.read<ActividadesViewModel>().cargarTodasActividades(
        widget.empresaId,
      );
      // Cargar catÃ¡logo de trabajos para obtener informaciÃ³n de tÃ­tulo, cliente y costos.
      context.read<TrabajosViewModel>().cargarTrabajos(widget.empresaId);
      // Cargar clientes para disponer de nombres en filtros y tarjetas.
      context.read<ClientesViewModel>().cargarClientes(widget.empresaId);
      // Cargar usuarios para disponer de nombres de tÃ©cnicos en filtros.
      context.read<UsuariosViewModel>().cargarUsuarios(widget.empresaId);
      // Cargar horas registradas hoy (basado en Sesiones)
      context.read<SesionesViewModel>().loadRegisteredHoursForDate(
        widget.empresaId,
        DateTime.now(),
      );

      // Auto-finalización (opción A): solo el admin aplica la regla, y solo si hay configuración.
      /* if (widget.role == 'PERF_ADMIN') {
        final empresaVM = context.read<EmpresaViewModel>();
        if (empresaVM.empresa == null) {
          await empresaVM.cargarEmpresa(widget.empresaId);
        }
        final horasTolerancia = empresaVM.empresa?.autoFinalizarHoras;
        if (horasTolerancia != null && horasTolerancia > 0) {
          await context.read<TrabajoAsignadoRepository>().autoFinalizarTrabajosExpirados(
                widget.empresaId,
                horasTolerancia: horasTolerancia,
              );
          await context.read<TrabajosAsignadosViewModel>().cargarTrabajosAsignados(
                widget.empresaId,
              );
        }
      } */
    });
  }

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _buildRegisteredHoursFilterBar() {
    final t = AppLocalizations.of(context)!;
    final range = _registeredHoursRange;
    final usuariosVM = context.watch<UsuariosViewModel>();

    String techLabel() {
      if (_registeredHoursTechId == null) return t.allOption;
      final u = usuariosVM.usuarios.firstWhere(
        (u) => u.id == _registeredHoursTechId,
        orElse: () => Usuario(
          id: _registeredHoursTechId!,
          authUid: '',
          nombre: _registeredHoursTechId!,
          email: '',
          idEmpresa: '',
          perfilId: '',
        ),
      );
      return u.nombre.isNotEmpty ? u.nombre : t.allOption;
    }

    final tech = techLabel();
    final showTech = tech != t.allOption;

    final label = range == null
        ? '${t.registeredHoursMetric}: ${t.allOption}${showTech ? ' · $tech' : ''}'
        : '${t.registeredHoursMetric}: ${_fmtDate(range.start)} - ${_fmtDate(range.end)}${showTech ? ' · $tech' : ''}';

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.black54),
          ),
        ),
        IconButton(
          tooltip: 'Configurar',
          icon: const Icon(Icons.tune),
          onPressed: _openRegisteredHoursFiltersSheet,
        ),
      ],
    );
  }

  Future<void> _openRegisteredHoursFiltersSheet() async {
    final usuariosVM = context.read<UsuariosViewModel>();
    final theme = Theme.of(context);

    final techUsers = usuariosVM.usuarios
        .where((u) => u.perfilId == 'PERF_TEC' && u.activo)
        .toList()
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final range = _registeredHoursRange;

            Widget dateCard({
              required String label,
              required DateTime? value,
              required VoidCallback onTap,
            }) {
              return Expanded(
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.primary.withAlpha(80),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              label.toUpperCase(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          value == null ? '--' : _fmtDate(value),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.85,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Configurar Vista',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setStateModal(() {
                                _registeredHoursRange = null;
                                _registeredHoursRangeTotal = null;
                                _registeredHoursTechId = null;
                              });
                            },
                            child: const Text('Restablecer'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'RANGO DE FECHAS',
                        style: theme.textTheme.labelLarge?.copyWith(
                          letterSpacing: 1.2,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          dateCard(
                            label: 'Desde',
                            value: range?.start,
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                                initialDateRange: range ??
                                    DateTimeRange(
                                      start: DateTime(
                                        now.year,
                                        now.month,
                                        now.day,
                                      ),
                                      end: DateTime(
                                        now.year,
                                        now.month,
                                        now.day,
                                      ),
                                    ),
                              );
                              if (picked == null) return;
                              setStateModal(() {
                                _registeredHoursRange = DateTimeRange(
                                  start: _dayOnly(picked.start),
                                  end: _dayOnly(picked.end),
                                );
                                _registeredHoursRangeTotal = null;
                              });
                            },
                          ),
                          const SizedBox(width: 12),
                          dateCard(
                            label: 'Hasta',
                            value: range?.end,
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                                initialDateRange: range ??
                                    DateTimeRange(
                                      start: DateTime(
                                        now.year,
                                        now.month,
                                        now.day,
                                      ),
                                      end: DateTime(
                                        now.year,
                                        now.month,
                                        now.day,
                                      ),
                                    ),
                              );
                              if (picked == null) return;
                              setStateModal(() {
                                _registeredHoursRange = DateTimeRange(
                                  start: _dayOnly(picked.start),
                                  end: _dayOnly(picked.end),
                                );
                                _registeredHoursRangeTotal = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (widget.role != 'PERF_TEC') ...[
                        Text(
                          'USUARIO',
                          style: theme.textTheme.labelLarge?.copyWith(
                            letterSpacing: 1.2,
                            color: Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 2.2,
                            children: [
                              _userFilterTile(
                                context,
                                selected: _registeredHoursTechId == null,
                                title: 'Global',
                                subtitle: 'Todos los usuarios',
                                icon: Icons.all_inclusive,
                                onTap: () => setStateModal(
                                  () => _registeredHoursTechId = null,
                                ),
                              ),
                              ...techUsers.map((u) {
                                final selected = _registeredHoursTechId == u.id;
                                return _userFilterTile(
                                  context,
                                  selected: selected,
                                  title: u.nombre,
                                  subtitle: 'Tecnico',
                                  icon: Icons.engineering,
                                  onTap: () => setStateModal(
                                    () => _registeredHoursTechId = u.id,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                      SafeArea(
                        top: false,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              if (_registeredHoursRange != null) {
                                await _recomputeRegisteredHoursRangeTotal();
                              }
                              if (mounted) setState(() {});
                            },
                            child: const Text('Aplicar'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _userFilterTile(
    BuildContext context, {
    required bool selected,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withAlpha(25)
              : Colors.grey.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary
                    : Colors.grey.withAlpha(60),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recomputeRegisteredHoursRangeTotal() async {
    final range = _registeredHoursRange;
    if (range == null) return;

    final sesionesVM = context.read<SesionesViewModel>();
    await sesionesVM.loadAllRegisteredHours(widget.empresaId);
    if (!mounted) return;

    final start = _dayOnly(range.start);
    final endExclusive = _dayOnly(range.end).add(const Duration(days: 1));
    final nowLocal = DateTime.now();

    double sessionHoursWithinRange(SesionTrabajo s) {
      final startLocal = s.inicio.toLocal();
      final endLocal = (s.fin ?? nowLocal).toLocal();
      final effectiveStart = startLocal.isBefore(start) ? start : startLocal;
      final effectiveEnd =
          endLocal.isAfter(endExclusive) ? endExclusive : endLocal;
      final minutes = effectiveEnd.difference(effectiveStart).inMinutes;
      if (minutes <= 0) return 0.0;
      return minutes / 60.0;
    }

    final total = sesionesVM.allHistorySessions
        .where((s) {
          final startLocal = s.inicio.toLocal();
          return (startLocal.isAfter(start) ||
                  startLocal.isAtSameMomentAs(start)) &&
              startLocal.isBefore(endExclusive);
        })
        .where((s) {
          if (widget.role == 'PERF_TEC') return s.tecnicoId == widget.userId;
          if (_registeredHoursTechId != null) {
            return s.tecnicoId == _registeredHoursTechId;
          }
          return true;
        })
        .fold<double>(0.0, (sum, s) => sum + sessionHoursWithinRange(s));

    if (!mounted) return;
    setState(() => _registeredHoursRangeTotal = total);
  }

  // MÃ©todo eliminado: se deja la funcionalidad de reporte de problemas a
  // ProblemsPage y DialogoReporteProblema.  Este cuerpo se ha
  // eliminado completamente para evitar duplicaciÃ³n.

  // MÃ©todo eliminado: ver nota anterior.  La funcionalidad de reportar
  // problemas se delega al widget reutilizable y a ProblemsPage.

  // MÃ©todo eliminado: la lista completa de problemas se consulta en
  // ProblemsPage.  El administrador puede acceder a dicha pÃ¡gina a
  // travÃ©s del icono de notificaciones o las acciones rÃ¡pidas.
  // ======================================================================
  // DescripciÃ³n de cambios:
  //  - Se introduce un modal de detalle de trabajos por fecha que se
  //    muestra cuando el usuario toca un dÃ­a en el calendario que
  //    contiene al menos un trabajo.  Este modal reutiliza el estilo
  //    empleado por las tarjetas de mÃ©tricas, pero aÃ±ade filtros
  //    agrupados en forma de acordeÃ³n para cliente, tÃ©cnico y estado.
  //  - La lista de trabajos previamente incrustada en la vista
  //    (_buildTasksForSelectedDate) se reemplaza por este modal,
  //    de modo que la agenda sÃ³lo resalta la fecha seleccionada y
  //    delega la visualizaciÃ³n de los trabajos al modal.
  //  - Se aÃ±aden filtros similares a los del modal de trabajos por
  //    fecha en las otras mÃ©tricas.  Dependiendo de la mÃ©trica, se
  //    muestran filtros pertinentes (por ejemplo, por tÃ©cnico en la
  //    mÃ©trica de horas registradas).  Los filtros se presentan como
  //    ExpansionTile (acordeones) para ahorrar espacio y ordenar la
  //    interfaz.

  /// Shows a dialog allowing a technician to register a material expense.
  /// The user can select a type of expense and enter a description.
  /// On confirmation, the expense is added to the pending list in the
  /// [ExpensesRepository].
  void _showRegisterMaterialExpenseDialog() {
    final t = AppLocalizations.of(context)!;
    String selectedType = t.materialsExpenseLabel;
    final descriptionController = TextEditingController();

    showWorkiaBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t.registerMaterialExpenseTitle,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: InputDecoration(
                          labelText: t.expenseTypeLabel,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: t.materialsExpenseLabel,
                            child: Text(t.materialsExpenseLabel),
                          ),
                          DropdownMenuItem(
                            value: t.fuelExpenseLabel,
                            child: Text(t.fuelExpenseLabel),
                          ),
                          DropdownMenuItem(
                            value: t.salariesExpenseLabel,
                            child: Text(t.salariesExpenseLabel),
                          ),
                          DropdownMenuItem(
                            value: t.officeExpenseLabel,
                            child: Text(t.officeExpenseLabel),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setStateModal(() => selectedType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: t.expenseDescriptionLabel,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(t.cancelButton),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final desc = descriptionController.text.trim();
                                if (desc.isNotEmpty) {
                                  ExpensesRepository.addPending(
                                    MaterialExpense(
                                      type: selectedType,
                                      description: desc,
                                    ),
                                  );
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(t.expenseRegisteredMessage),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(t.registerButton),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Determina la etiqueta apropiada para el botÃ³n de acciÃ³n de una
  /// tarjeta de trabajo segÃºn el rol del usuario y el estado del
  /// trabajo.  Los roles de administrador y finanzas siempre ven
  /// "Ver Detalles" porque no realizan tareas operativas.  Los
  /// tÃ©cnicos ven acciones especÃ­ficas segÃºn el contexto: registrar
  /// una actividad para trabajos activos o iniciar un trabajo
  /// pendiente.  Cualquier otro estado muestra "Ver Detalles".

  @override
  void dispose() {
    // No hay controladores que desechar porque hemos eliminado
    // los formularios de registro de actividades de esta vista.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // backgroundColor: removed to use global theme
        body: RefreshIndicator(
          onRefresh: () async {
            final empresaId = widget.empresaId;
            await Future.wait([
              context.read<ProblemasViewModel>().cargarProblemas(empresaId),
              context
                  .read<TrabajosAsignadosViewModel>()
                  .cargarTrabajosAsignados(empresaId),
              context.read<ActividadesViewModel>().cargarTodasActividades(
                empresaId,
              ),
              context.read<TrabajosViewModel>().cargarTrabajos(empresaId),
              context.read<ClientesViewModel>().cargarClientes(empresaId),
              context.read<UsuariosViewModel>().cargarUsuarios(empresaId),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.agendaTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.agendaSubtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                _buildRegisteredHoursFilterBar(),
                const SizedBox(height: 8),
                _buildMetricsGrid(),
                const SizedBox(height: 16),
                // Calendario dinÃ¡mico que permite navegar entre meses y
                // seleccionar una fecha para ver los trabajos asignados.
                _buildCalendarSection(context),
                const SizedBox(height: 16),
                // Lista de trabajos para la fecha seleccionada.  Si no se
                // ha seleccionado una fecha, no se muestra ninguna lista.
                // Eliminado: ya no mostramos la lista de trabajos debajo
                // del calendario.  Al tocar una fecha se abre un modal
                // directamente, de manera similar a las tarjetas de mÃ©tricas.
                // El botÃ³n de problemas se ha movido al icono de
                // notificaciones en la barra superior.
              ],
            ),
          ),
        ),

      ),
    );
  }

  /// Top bar with avatar, name, role and icons.
  Widget _buildTopBar(BuildContext context) {
    // Compute the initials from the user's name.
    String initials() {
      final parts = widget.userName.trim().split(RegExp(r'\s+'));
      if (parts.isEmpty) return '';
      if (parts.length == 1) {
        return parts.first.substring(0, 1).toUpperCase();
      }
      return (parts.first[0] + parts.last[0]).toUpperCase();
    }

    // Derive a label for the role.
    String roleLabel() {
      switch (widget.role) {
        case 'PERF_ADMIN':
          return AppLocalizations.of(context)!.roleAdmin;
        case 'PERF_FIN':
          return AppLocalizations.of(context)!.roleFinance;
        case 'PERF_TEC':
          return AppLocalizations.of(context)!.roleTech;
        default:
          return widget.role;
      }
    }

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            // Open the user settings page when tapping the avatar.
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UserSettingsPage(
                  userName: widget.userName,
                  role: widget.role,
                ),
              ),
            );
          },
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              initials(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              roleLabel(),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const Spacer(),
        // Icono de notificaciones que muestra el listado de problemas.
        // Icono de notificaciones que muestra el listado de problemas.
        Builder(
          builder: (context) {
            final problemasVM = context.watch<ProblemasViewModel>();
            final asignadosVM = context.watch<TrabajosAsignadosViewModel>();

            var pendingProblems = problemasVM.problemas
                .where((p) => !p.resuelto && !p.ignorado)
                .toList();

            if (widget.role == 'PERF_TEC') {
              final myAssignments = asignadosVM.trabajos
                  .where((t) => t.tecnicosAsignados.contains(widget.userId))
                  .toList();

              pendingProblems = pendingProblems.where((p) {
                // 1. Reportado por mi
                if (p.reportadoPorId == widget.userId) return true;

                // 2. Relacionado con trabajo asignado a mi
                if (p.referenciaTipo == 'Trabajo' && p.referenciaId != null) {
                  final isMyAssignment = myAssignments.any(
                    (a) =>
                        a.id == p.referenciaId || a.trabajoId == p.referenciaId,
                  );
                  if (isMyAssignment) return true;
                }
                return false;
              }).toList();
            }

            final pendingCount = pendingProblems.length;

            return IconButton(
              icon: Badge(
                isLabelVisible: pendingCount > 0,
                label: Text('$pendingCount'),
                backgroundColor: Colors.red,
                child: const Icon(Icons.notifications),
              ),
              tooltip: AppLocalizations.of(context)!.problemsTooltip,
              onPressed: () {
                // Navegar a la pÃ¡gina de problemas.
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProblemsPage(
                      userName: widget.userName,
                      role: widget.role,
                    ),
                  ),
                );
              },
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // Navigate to user settings when tapping the settings icon.
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UserSettingsPage(
                  userName: widget.userName,
                  role: widget.role,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Nota: En esta versiÃ³n el historial y el reporte de problemas estÃ¡n
  // disponibles desde el icono de notificaciones en la barra superior.
  // Se ha eliminado el botÃ³n y el mÃ©todo especÃ­ficos que estaban aquÃ­
  // (_buildProblemHistoryButton y _showMyProblemsDialog) para evitar
  // duplicar funcionalidad.

  String _normalizeStatus(String status) {
    // Normalizamos cadenas para comparaciones seguras.
    // Mapeo a los 4 estados principales: en espera, iniciado, finalizado, cerrado.
    final lower = status.replaceAll('_', ' ').toLowerCase().trim();

    // Mapeos de "Pendiente" o variaciones a "En espera"
    if (lower == 'pendiente' ||
        lower == 'pending' ||
        lower == 'on hold' ||
        lower == 'en espera') {
      return 'en espera';
    }
    // Mapeos de "Iniciado"
    if (lower == 'iniciado' ||
        lower == 'en progreso' ||
        lower == 'en curso' ||
        lower == 'started' ||
        lower == 'in progress') {
      return 'iniciado';
    }
    // Mapeos de "Finalizado"
    if (lower == 'finalizado' ||
        lower == 'completo' ||
        lower == 'completado' ||
        lower == 'completed' ||
        lower == 'finished' ||
        lower == 'finalizada') {
      return 'finalizado';
    }
    // Mapeos de "Cerrado"
    if (lower == 'cerrado' || lower == 'closed') {
      return 'cerrado';
    }

    return lower;
  }

  /// Devuelve el texto localizado para el estado
  String _getStatusText(String status) {
    final normalized = _normalizeStatus(status);
    final t = AppLocalizations.of(context)!;

    switch (normalized) {
      case 'iniciado':
        return t.jobStatusStarted; // Asegurar tener esta key o 'Started'
      case 'finalizado':
        return t.jobStatusFinished;
      case 'en espera':
        return t.jobStatusOnHold;
      case 'cerrado':
        return t.jobStatusClosed;
      default:
        // Si no machea, devolver original a TitleCase
        if (status.isEmpty) return 'Sin Estado';
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  bool _isCompletedStatus(String status) {
    final normalized = _normalizeStatus(status);
    return normalized == 'finalizado' || normalized == 'cerrado';
  }

  bool _isPendingStatus(String status) {
    final normalized = _normalizeStatus(status);
    return normalized == 'en espera';
  }

  bool _isInProgressStatus(String status) {
    final normalized = _normalizeStatus(status);
    return normalized == 'iniciado';
  }

  /// Devuelve un color para el estado de un trabajo.
  Color _statusColor(String status) {
    final normalized = _normalizeStatus(status);
    switch (normalized) {
      case 'iniciado':
        return Colors.orange;
      case 'finalizado':
        return Colors.green;
      case 'en espera':
        return Theme.of(context).primaryColor; // Azul normalmente
      case 'cerrado':
        return Colors.grey.shade700;
      default:
        return Colors.grey;
    }
  }

  /// Muestra detalles para una mÃ©trica seleccionada en un fondo modal.
  /// Dependiendo de [metric] se calculan datos a partir del ViewModel y
  /// se presentan en una lista o tabla.  Las mÃ©tricas soportadas son
  /// "Trabajos Hoy", "Horas Registradas", "Trabajos Completados" y
  /// "Pendientes".  La funciÃ³n se encarga de filtrar por rol para
  /// mostrar sÃ³lo los datos relevantes del usuario actual cuando
  /// corresponde.
  Future<void> _showMetricDetails(String metric) async {
    final t = AppLocalizations.of(context)!;
    // Obtener los trabajos asignados y fusionarlos con el catÃ¡logo para
    // disponer de tÃ­tulos, clientes y costos.

    // FETCH ALL ASSIGNMENTS (Global History support)
    // We bypass the ViewModel's 'active' filter to show Finalized/Archived jobs.
    final asignadosRepo = context.read<TrabajoAsignadoRepository>();
    // Show a loading indicator ideally, but for now we await (might freeze slightly)
    // typically we'd show a dialog or spinner.
    final allAssignments = await asignadosRepo.obtenerTrabajosAsignados(
      widget.empresaId,
    );
    if (!mounted) return;

    final trabajosVM = context.read<TrabajosViewModel>();

    final asignados = allAssignments; // Use FULL list
    final converted = _mapAsignacionesToTrabajos(
      asignados,
      trabajosVM.trabajos,
    );

    // Sort by Date Descending (Newest first)
    converted.sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));

    // Filtrar por tÃ©cnico si el usuario tiene rol de tÃ©cnico.
    final relevant = widget.role == 'PERF_TEC'
        ? converted
              .where((t) => t.empleadosAsignados.contains(widget.userName))
              .toList()
        : converted;
    // Comparar contra la traducciÃ³n para soportar mÃºltiples idiomas.
    if (metric == t.jobsTodayMetric) {
      final today = DateTime.now();
      final jobsToday = relevant
          .where(
            (t) =>
                t.fechaInicio.year == today.year &&
                t.fechaInicio.month == today.month &&
                t.fechaInicio.day == today.day,
          )
          .toList();
      _showJobsModal(
        title: t.jobsTodayMetric,
        jobs: jobsToday,
        showStatusFilter: true,
        showClientFilter: true,

      );
      return;
    }
    if (metric == t.completedJobsMetric) {
      final completed = relevant
          .where((t) => _isCompletedStatus(t.estado))
          .toList();
      _showJobsModal(
        title: t.completedJobsMetric,
        jobs: completed,
        showStatusFilter: false,
        showClientFilter: true,

      );
      return;
    }
    if (metric == t.pendingJobsMetric) {
      final pending = relevant
          .where(
            (t) => _isPendingStatus(t.estado) || _isInProgressStatus(t.estado),
          )
          .toList();
      _showJobsModal(
        title: t.pendingJobsMetric,
        jobs: pending,
        showStatusFilter: false,
        showClientFilter: true,

      );
      return;
    }
    if (metric == t.registeredHoursMetric) {
      // Prioridad:
      // 1) Si el usuario ya seleccionÃ³ un rango manual, usarlo.
      // 2) Si el usuario seleccionÃ³ una fecha en el calendario (y no hay rango),
      //    mostrar solo esa fecha.
      // 3) Si no hay rango ni fecha seleccionada, usar el dÃ­a actual.
      if (_registeredHoursRange != null) {
        await _showRegisteredHoursRangeModal();
        return;
      }
      if (_selectedDate != null) {
        final d = _dayOnly(_selectedDate!);
        await _showRegisteredHoursRangeModal(
          rangeOverride: DateTimeRange(start: d, end: d),
          showRangeInHeader: false,
        );
        return;
      }

      final today = _dayOnly(DateTime.now());
      await _showRegisteredHoursRangeModal(
        rangeOverride: DateTimeRange(start: today, end: today),
        showRangeInHeader: false,
      );
      return;
/*
      final asignadosRepo = context.read<TrabajoAsignadoRepository>();
      
      final List<TrabajoAsignado> allAssignmentsInfo = await asignadosRepo.obtenerTrabajosAsignados(widget.empresaId);
      if (!mounted) return;
      
      // Horas históricas: mostrar todas las asignaciones con horas acumuladas.
      var assignmentsWithHours = allAssignmentsInfo
          .where((a) => a.horasAcumuladas.isNotEmpty)
          .toList();

      if (widget.role == 'PERF_TEC') {
        assignmentsWithHours = assignmentsWithHours
            .where(
              (a) =>
                  a.tecnicosAsignados.contains(widget.userId) ||
                  a.horasAcumuladas.containsKey(widget.userId),
            )
            .toList();
      }

      _showRegisteredHoursModal(assignmentsWithHours, date: DateTime.now());
      return;
*/
    }
  }

  Future<void> _showRegisteredHoursRangeModal({
    DateTimeRange? rangeOverride,
    bool showRangeInHeader = true,
  }) async {
    final range = rangeOverride ?? _registeredHoursRange;
    if (range == null) return;

    final sesionesVM = context.read<SesionesViewModel>();
    final asignadosRepo = context.read<TrabajoAsignadoRepository>();

    await sesionesVM.loadAllRegisteredHours(widget.empresaId);
    if (!mounted) return;

    final allAssignments = await asignadosRepo.obtenerTrabajosAsignados(
      widget.empresaId,
    );
    if (!mounted) return;

    final start = _dayOnly(range.start);
    final endExclusive = _dayOnly(range.end).add(const Duration(days: 1));
    final nowLocal = DateTime.now();

    double sessionHoursWithinRange(SesionTrabajo s) {
      final startLocal = s.inicio.toLocal();
      final endLocal = (s.fin ?? nowLocal).toLocal();
      final effectiveStart = startLocal.isBefore(start) ? start : startLocal;
      final effectiveEnd =
          endLocal.isAfter(endExclusive) ? endExclusive : endLocal;
      final minutes = effectiveEnd.difference(effectiveStart).inMinutes;
      if (minutes <= 0) return 0.0;
      return minutes / 60.0;
    }

    var sessions = sesionesVM.allHistorySessions.where((s) {
      final startLocal = s.inicio.toLocal();
      return (startLocal.isAfter(start) || startLocal.isAtSameMomentAs(start)) &&
          startLocal.isBefore(endExclusive);
    }).toList();

    if (widget.role == 'PERF_TEC') {
      sessions = sessions.where((s) => s.tecnicoId == widget.userId).toList();
    } else if (_registeredHoursTechId != null) {
      sessions =
          sessions.where((s) => s.tecnicoId == _registeredHoursTechId).toList();
    }

    final Map<String, Map<String, double>> hoursByTechByAssignment = {};
    for (final s in sessions) {
      final h = sessionHoursWithinRange(s);
      if (h <= 0) continue;
      hoursByTechByAssignment
          .putIfAbsent(s.tecnicoId, () => {})
          .update(
            s.trabajoAsignadoId,
            (v) => v + h,
            ifAbsent: () => h,
          );
    }

    final Set<String> assignmentIdsWithHours = hoursByTechByAssignment.values
        .expand((m) => m.keys)
        .toSet();

    var assignmentsInRange =
        allAssignments.where((a) => assignmentIdsWithHours.contains(a.id)).toList();

    if (widget.role == 'PERF_TEC') {
      assignmentsInRange = assignmentsInRange
          .where(
            (a) =>
                a.tecnicosAsignados.contains(widget.userId) ||
                a.horasAcumuladas.containsKey(widget.userId),
          )
          .toList();
    }

    await _showRegisteredHoursModal(
      assignmentsInRange,
      date: start,
      range: showRangeInHeader ? range : null,
      hoursByTechByAssignmentOverride: hoursByTechByAssignment,
    );
  }

  Future<void> _showSelectedDateHoursModal(DateTime date) async {
    final t = AppLocalizations.of(context)!;
    // `SesionesViewModel` ya no se usa aquÃ­; el cÃ¡lculo viene filtrado por rango/fecha.
    final usersVM = context.read<UsuariosViewModel>();

    String fmtDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    final sesionesVM = context.read<SesionesViewModel>();
    final Map<String, double> daily = sesionesVM.dailyHours;
    final entries = daily.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (widget.role == 'PERF_TEC') {
      final mine = daily[widget.userId] ?? 0.0;
      if (mine <= 0) return;
    } else {
      if (entries.isEmpty) return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${t.registeredHoursMetric} · ${fmtDate(date)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                if (widget.role == 'PERF_TEC') ...[
                  Text(
                    _formatHours(daily[widget.userId] ?? 0.0),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ] else ...[
                  ...entries.map((e) {
                    final tech = usersVM.usuarios.firstWhere(
                      (u) => u.id == e.key,
                      orElse: () => Usuario(
                        id: e.key,
                        authUid: '',
                        nombre: e.key,
                        email: '',
                        idEmpresa: '',
                        perfilId: '',
                      ),
                    );
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tech.nombre),
                      trailing: Text(
                        _formatHours(e.value),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows the Registered Hours modal with standardized filters and hierarchical view.
  /// Shows the Registered Hours modal with standardized filters and hierarchical view.
  Future<void> _showRegisteredHoursModal(
    List<TrabajoAsignado> assignmentsToday,
    {
      DateTime? date,
      DateTimeRange? range,
      Map<String, Map<String, double>>? hoursByTechByAssignmentOverride,
    }
  ) async {
    final t = AppLocalizations.of(context)!;
    final usuariosVM = context.read<UsuariosViewModel>();

    final clientesVM = context.read<ClientesViewModel>();
    final trabajosVM = context.read<TrabajosViewModel>();
/*
    final sesionesVM = context.read<SesionesViewModel>();

    // Horas registradas únicamente para la fecha seleccionada.
    // (Guard extra por si el repositorio/zonas horarias metieran sesiones fuera del día.)
    final sessions = sesionesVM.dailySessions
        .where((s) => DateUtils.isSameDay(s.inicio.toLocal(), date))
        .toList();

    final assignmentsTodayIds = assignmentsToday.map((a) => a.id).toSet();
    double sessionHours(SesionTrabajo s) {
      if (s.fin != null) return s.horas;
      final duration = DateTime.now().difference(s.inicio);
      return duration.inMinutes / 60.0;
    }

    final Map<String, Map<String, double>> hoursByTechByAssignment = {};
    final Map<String, Set<String>> techsByAssignment = {};
    for (final s in sessions) {
      if (!assignmentsTodayIds.contains(s.trabajoAsignadoId)) continue;
      final horas = sessionHours(s);
      if (horas <= 0) continue;
      hoursByTechByAssignment
          .putIfAbsent(s.tecnicoId, () => {})
          .update(
            s.trabajoAsignadoId,
            (v) => v + horas,
            ifAbsent: () => horas,
          );
      techsByAssignment
          .putIfAbsent(s.trabajoAsignadoId, () => <String>{})
          .add(s.tecnicoId);
    }

    // Modo histórico: reconstruir los mapas usando horas acumuladas por técnico
    // almacenadas en el documento de asignación.
    hoursByTechByAssignment.clear();
    techsByAssignment.clear();
    for (final a in assignmentsToday) {
      final entries = a.horasAcumuladas.entries.where((e) => e.value > 0);
      if (entries.isEmpty) continue;
      for (final e in entries) {
        // En PERF_TEC, el listado final se filtrará por widget.userId.
        hoursByTechByAssignment
            .putIfAbsent(e.key, () => {})
            .update(
              a.id,
              (v) => v + e.value,
              ifAbsent: () => e.value,
            );
        techsByAssignment.putIfAbsent(a.id, () => <String>{}).add(e.key);
      }
    }

    // 1. Prepare Data & Extract Options
*/

    // Las horas se calculan fuera y se inyectan al modal (por rango/fecha).
    // Si no se inyectan, usamos el snapshot `horasAcumuladas` del documento.
    final Map<String, Map<String, double>> hoursByTechByAssignment =
        hoursByTechByAssignmentOverride ?? <String, Map<String, double>>{};
    final Map<String, Set<String>> techsByAssignment = {};

    if (hoursByTechByAssignmentOverride == null) {
      for (final a in assignmentsToday) {
        final entries = a.horasAcumuladas.entries.where((e) => e.value > 0);
        if (entries.isEmpty) continue;
        for (final e in entries) {
          hoursByTechByAssignment
              .putIfAbsent(e.key, () => {})
              .update(a.id, (v) => v + e.value, ifAbsent: () => e.value);
          techsByAssignment.putIfAbsent(a.id, () => <String>{}).add(e.key);
        }
      }
    } else {
      for (final techEntry in hoursByTechByAssignment.entries) {
        final techId = techEntry.key;
        for (final aEntry in techEntry.value.entries) {
          if (aEntry.value <= 0) continue;
          techsByAssignment
              .putIfAbsent(aEntry.key, () => <String>{})
              .add(techId);
        }
      }
    }

    String headerTitle() {
      if (range != null) {
        return '${t.registeredHoursMetric} · ${_fmtDate(range!.start)} - ${_fmtDate(range!.end)}';
      }
      if (date != null) {
        return '${t.registeredHoursMetric} · ${_fmtDate(date!)}';
      }
      return t.registeredHoursMetric;
    }

    // 1. Prepare Data & Extract Options
    final clients = <String>{};
    final techIds = <String>{};
    final jobTitles = <String>{};

    // 2. Build Filter Options & Group Assignments by Technician
    final Map<String, List<TrabajoAsignado>> assignmentsByTech = {};

    for (var assignment in assignmentsToday) {
      // Solo consideramos los trabajos que tienen horas acumuladas para evitar listar trabajos en cero,
      // a menos que sea útil para ver quién está asignado. Como el objetivo es ver horas, filtramos:
      final involvedTechsForDayRaw = techsByAssignment[assignment.id];
      if (involvedTechsForDayRaw == null || involvedTechsForDayRaw.isEmpty) {
        continue;
      }

      // Horas históricas: permitir técnicos con horas aunque ya no estén en la lista
      // de asignados (por migraciones/cambios de asignación).
      final involvedTechsForDay = involvedTechsForDayRaw.toSet();
      if (involvedTechsForDay.isEmpty) continue;

      // Resolve Job Base for Filters
      final jobBase = trabajosVM.trabajos.firstWhere(
        (j) => j.id == assignment.trabajoId,
        orElse: () => Trabajo(
          id: '',
          titulo: '',
          cliente: '',
          estado: '',
          fechaInicio: DateTime.now(),
          fechaFin: DateTime.now(),
        ),
      );

      // Resolve Client Name
      String clientName = jobBase.cliente;
      if (clientName.isEmpty && assignment.clienteId.isNotEmpty) {
        // Try cache or skip, logic handled in display.
        // For filter list, we might miss it if logic is only in UI.
        // Let's do simple resolve if needed, or rely on jobBase.
        // (User fixed this previously with VM lookup, but for filter set we can be lenient or do quick lookup if performance allows)
        // Let's skip heavy lookup here to avoid 300 lookups. relying on jobBase.
      }
      clients.add(clientName.isNotEmpty ? clientName : 'Sin Cliente');

      // Job Title for Filter
      final title = jobBase.titulo.isNotEmpty ? jobBase.titulo : 'Sin Título';
      jobTitles.add(title);

      for (var techId in involvedTechsForDay) {
        // PERF_TEC filter check
        if (widget.role == 'PERF_TEC' && techId != widget.userId) continue;

        assignmentsByTech.putIfAbsent(techId, () => []).add(assignment);
        techIds.add(techId);
      }
    }

    final allValue = t.allOption;
    final Set<String> selectedClients = {};
    final Set<String> selectedJobs = {};

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            // 3. Apply Filters in UI
            // We filter the 'assignmentsByTech' map entry by entry or rebuild it.
            // Easiest is to iterate keys and filter the list.

            final Map<String, List<TrabajoAsignado>> filteredAssignmentsByTech =
                {};

            for (var entry in assignmentsByTech.entries) {
              final techId = entry.key;
              final assignments = entry.value;

              // Filter Assignments (Client / Status)
              final filteredList = assignments.where((a) {
                final j = trabajosVM.trabajos.firstWhere(
                  (j) => j.id == a.trabajoId,
                  orElse: () => Trabajo(
                    id: '',
                    titulo: '',
                    cliente: '',
                    estado: '',
                    fechaInicio: DateTime.now(),
                    fechaFin: DateTime.now(),
                  ),
                );

                // Client Check
                String cName = j.cliente;
                if (cName.isEmpty && a.clienteId.isNotEmpty) {
                  final c = clientesVM.clientes.firstWhere(
                    (c) => c.id == a.clienteId,
                    orElse: () => const Cliente(
                      id: '',
                      nombre: '',
                      razonSocial: '',
                      personaContacto: '',
                      telefono: '',
                      correo: '',
                      direccion: '',
                    ),
                  );
                  if (c.id.isNotEmpty) cName = c.nombre;
                }
                if (cName.isEmpty) cName = 'Sin Cliente';

                if (selectedClients.isNotEmpty &&
                    !selectedClients.contains(cName))
                  return false;

                // Job Title Check
                final jTitle = j.titulo.isNotEmpty ? j.titulo : 'Sin Título';
                if (selectedJobs.isNotEmpty && !selectedJobs.contains(jTitle))
                  return false;

                return true;
              }).toList();

              if (filteredList.isNotEmpty) {
                filteredAssignmentsByTech[techId] = filteredList;
              }
            }

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.85,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                headerTitle(),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),

                      // Filters Accordion
                      ExpansionTile(
                        title: Text(t.filtersTitle),
                        children: [
                          const SizedBox(height: 8),
                          // Client Filter
                          if (clients.isNotEmpty)
                            DropdownSearch<String>(
                              items: (String filter, dynamic props) {
                                final all = [allValue, ...clients];
                                if (filter.isEmpty) return all;
                                return all
                                    .where(
                                      (i) => i.toLowerCase().contains(
                                        filter.toLowerCase(),
                                      ),
                                    )
                                    .toList();
                              },
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: t.clientLabel,
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                              onChanged: (val) {
                                if (val == null) return;
                                setStateModal(() {
                                  if (val == allValue) {
                                    selectedClients.clear();
                                  } else {
                                    selectedClients.clear();
                                    selectedClients.add(val);
                                  }
                                });
                              },
                              selectedItem: selectedClients.isEmpty
                                  ? allValue
                                  : selectedClients.first,
                              popupProps: const PopupProps.menu(
                                showSearchBox: true,
                              ),
                            ),
                          const SizedBox(height: 8),

                          // Job Filter
                          if (jobTitles.isNotEmpty)
                            DropdownSearch<String>(
                              items: (filter, _) {
                                final list = [allValue, ...jobTitles];
                                return filter.isEmpty
                                    ? list
                                    : list
                                          .where(
                                            (i) => i.toLowerCase().contains(
                                              filter.toLowerCase(),
                                            ),
                                          )
                                          .toList();
                              },
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: t.jobLabel,
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                              onChanged: (val) {
                                if (val == null) return;
                                setStateModal(() {
                                  if (val == allValue)
                                    selectedJobs.clear();
                                  else {
                                    selectedJobs.clear();
                                    selectedJobs.add(val);
                                  }
                                });
                              },
                              selectedItem: selectedJobs.isEmpty
                                  ? allValue
                                  : selectedJobs.first,
                              popupProps: const PopupProps.menu(
                                showSearchBox: true,
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),

                      // List
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredAssignmentsByTech.length,
                          itemBuilder: (context, index) {
                            final techId = filteredAssignmentsByTech.keys
                                .elementAt(index);
                            final relevantAssignments =
                                filteredAssignmentsByTech[techId]!;

                            // Calculate Total Hours for Tech from Assignments (Total Historical)
                            double techTotal = 0.0;
                            final byAssignment =
                                hoursByTechByAssignment[techId] ?? const {};
                            for (var a in relevantAssignments) {
                              techTotal += byAssignment[a.id] ?? 0.0;
                            }

                            // Get Daily Hours Sum from Sessions
                            // This is just for the "Registered" total label in the card header if we want it?
                            // Or we keep techTotal as Historical.
                            // Let's use historical techTotal for the header to match JobDetail view.

                            final u = usuariosVM.usuarios.firstWhere(
                              (u) => u.id == techId,
                              orElse: () => Usuario(
                                id: '',
                                authUid: '',
                                nombre: 'Unknown',
                                email: '',
                                idEmpresa: '',
                                perfilId: '',
                              ),
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                title: Text(
                                  u.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${t.hoursPrefix} ${_formatHours(techTotal)}',
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  child: Text(
                                    u.nombre.isNotEmpty
                                        ? u.nombre[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                children: relevantAssignments.map((assignment) {
                                  // Resolve Job for Title/Client
                                  final job = trabajosVM.trabajos.firstWhere(
                                    (j) => j.id == assignment.trabajoId,
                                    orElse: () => Trabajo(
                                      id: assignment.trabajoId,
                                      titulo: assignment.tituloTrabajo,
                                      cliente: '',
                                      estado: '',
                                      fechaInicio: DateTime.now(),
                                      fechaFin: DateTime.now(),
                                      costo: assignment.precioFinal,
                                      clientesAsignados: [],
                                      esCiclico: false,
                                      descripcion: '',
                                      empresaId: assignment.empresaId,
                                      empleadosAsignados: [],
                                    ),
                                  );

                                  String clientName = job.cliente;
                                  if (clientName.isEmpty &&
                                      assignment.clienteId.isNotEmpty) {
                                    final client = clientesVM.clientes
                                        .firstWhere(
                                          (c) => c.id == assignment.clienteId,
                                          orElse: () => const Cliente(
                                            id: '',
                                            nombre: '',
                                            razonSocial: '',
                                            personaContacto: '',
                                            telefono: '',
                                            correo: '',
                                            direccion: '',
                                          ),
                                        );
                                    if (client.id.isNotEmpty) {
                                      clientName = client.nombre;
                                      // Update local dummy job for consistency if needed,
                                      // but we just render 'clientName' below.
                                    }
                                  }



                                  // Total Accumulated Hours (from Assignment snapshot)
                                  final totalHours =
                                      (hoursByTechByAssignment[techId]
                                              ?[assignment.id]) ??
                                      0.0;

                                  return ListTile(
                                    title: Text(
                                      job.titulo.isNotEmpty
                                          ? job.titulo
                                          : 'Sin TÃ­tulo',
                                    ),
                                    subtitle: Text(
                                      clientName.isNotEmpty
                                          ? clientName
                                          : 'Sin Cliente',
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Horas: ${_formatHours(totalHours)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => JobDetailPage(
                                            job: job,
                                            role: widget.role,
                                            userName: widget.userName,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatHours(double hours) {
    if (hours <= 0) return '0h 0m';
    // If hours is very small (e.g. seconds) but positive, show 1m
    if (hours * 60 < 0.5) return '0h 1m';

    final int h = hours.truncate();
    final int m = ((hours - h) * 60).round();
    return '${h}h ${m}m';
  }

  /// Muestra un modal con los trabajos asignados para una fecha
  /// concreta.  Se encarga de filtrar los trabajos por el rango
  /// correspondiente y por el rol del usuario (tÃ©cnico u otros).
  void _showJobsForDate(DateTime date) {
    final t = AppLocalizations.of(context)!;
    final locale = t.localeName;
    // Obtener trabajos asignados convertidos a trabajos del catÃ¡logo
    final asignadosVM = context.read<TrabajosAsignadosViewModel>();
    final trabajosVM = context.read<TrabajosViewModel>();
    final asignados = asignadosVM.trabajos;
    final converted = _mapAsignacionesToTrabajos(
      asignados,
      trabajosVM.trabajos,
    );
    final selectedDay = DateTime(date.year, date.month, date.day);
    final jobsForDate = converted.where((t) {
      final start = DateTime(
        t.fechaInicio.year,
        t.fechaInicio.month,
        t.fechaInicio.day,
      );
      final end = DateTime(t.fechaFin.year, t.fechaFin.month, t.fechaFin.day);
      final fallsOnDate =
          selectedDay.compareTo(start) >= 0 && selectedDay.compareTo(end) <= 0;
      if (widget.role == 'PERF_TEC') {
        return fallsOnDate && t.empleadosAsignados.contains(widget.userName);
      }
      return fallsOnDate;
    }).toList();
    // Guardar en el estado la lista de trabajos para la fecha seleccionada.
    // Ya no se muestra una lista debajo del calendario; se utiliza
    // internamente (p. ej., para mÃ©tricas o posibles futuras
    // funcionalidades).
    final formattedDate = DateFormat.yMd(locale).format(selectedDay);
    // Mostrar el modal y, al cerrarse, limpiar la selecciÃ³n y la lista de trabajos.
    _showJobsModal(
      title: t.jobsForDateTitle(formattedDate),
      jobs: jobsForDate,
      showStatusFilter: true,
      showClientFilter: true,

    );
  }

  /// Despliega un modal de lista de trabajos con filtros en forma de
  /// acordeÃ³n.  Este mÃ©todo se utiliza tanto para mostrar los
  /// trabajos de una fecha seleccionada como para los detalles de
  /// mÃ©tricas basadas en trabajos.  Los filtros de cliente,
  /// tÃ©cnico y estado pueden habilitarse o deshabilitarse segÃºn
  /// corresponda en cada caso.
  Future<void> _showJobsModal({
    required String title,
    required List<Trabajo> jobs,
    bool showStatusFilter = true,
    bool showClientFilter = true,
    Map<String, String>? extraInfo,
  }) {
    final t = AppLocalizations.of(context)!;
    final locale = t.localeName;
    final dateFormatter = DateFormat.yMd(locale);
    final timeFormatter = DateFormat.Hm(locale);
    final allValue = t.allOption;

    // Conjuntos con las opciones de filtros disponibles.
    final clients = <String>{};
    final statuses = <String>{};
    // Acceder al ViewModel de usuarios una sola vez para convertir ids a nombres.
    final usuariosVM = context.read<UsuariosViewModel>();
    for (final job in jobs) {
      clients.add(job.cliente);
      clients.addAll(job.clientesAsignados);
      statuses.add(_normalizeStatus(job.estado));
    }
    // Conjuntos de filtros seleccionados.  Al usar variables
    // definidas fuera del builder, estas persistirÃ¡n entre
    // reconstrucciones dentro del modal.
    final Set<String> selectedClients = {};
    final Set<String> selectedStatuses = {};
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            // Filtrar la lista de trabajos segÃºn los filtros seleccionados
            final usuariosVMLocal = context.read<UsuariosViewModel>();
            final filtered = jobs.where((job) {
              final clientOk =
                  selectedClients.isEmpty ||
                  selectedClients.contains(job.cliente) ||
                  job.clientesAsignados.any((c) => selectedClients.contains(c));
              final statusOk =
                  selectedStatuses.isEmpty ||
                  selectedStatuses.contains(_normalizeStatus(job.estado));
              return clientOk && statusOk;
            }).toList();

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.85,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    children: [
                      // Encabezado con tÃ­tulo y botÃ³n de cierre
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      // Contenido scrollable: filtros y lista
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Filtros agrupados en acordeÃ³n
                              ExpansionTile(
                                title: Text(t.filtersTitle),
                                children: [
                                  const SizedBox(height: 8),

                                  // ===== FILTRO POR ESTADO =====
                                  if (showStatusFilter && statuses.isNotEmpty)
                                    DropdownSearch<String>(
                                      items: (filter, _) {
                                        final all = [allValue, ...statuses];
                                        final f = filter.toLowerCase();
                                        if (f.isEmpty) return all;
                                        return all.where((e) {
                                          final label = e == allValue
                                              ? allValue
                                              : _getStatusText(e).toLowerCase();
                                          return label.contains(f) ||
                                              e.toLowerCase().contains(f);
                                        }).toList();
                                      },
                                      itemAsString: (item) {
                                        if (item == allValue) return allValue;
                                        return _getStatusText(item);
                                      },
                                      selectedItem: selectedStatuses.isEmpty
                                          ? allValue
                                          : selectedStatuses.first,
                                      decoratorProps: DropDownDecoratorProps(
                                        decoration: InputDecoration(
                                          labelText: t.statusLabel,
                                        ),
                                      ),
                                      popupProps: const PopupProps.menu(
                                        showSearchBox: true,
                                      ),
                                      onChanged: (value) {
                                        setStateModal(() {
                                          selectedStatuses.clear();
                                          if (value != null &&
                                              value != allValue) {
                                            selectedStatuses.add(value);
                                          }
                                        });
                                      },
                                    ),

                                  const SizedBox(height: 12),

                                  // ===== FILTRO POR CLIENTE =====
                                  if (showClientFilter && clients.isNotEmpty)
                                    DropdownSearch<String>(
                                      items: (filter, _) {
                                        final all = [allValue, ...clients];
                                        if (filter.isEmpty) {
                                          return all;
                                        }
                                        final f = filter.toLowerCase();
                                        return all
                                            .where(
                                              (e) =>
                                                  e.toLowerCase().contains(f),
                                            )
                                            .toList();
                                      },
                                      selectedItem: selectedClients.isEmpty
                                          ? allValue
                                          : selectedClients.first,
                                      decoratorProps: DropDownDecoratorProps(
                                        decoration: InputDecoration(
                                          labelText: t.clientLabel,
                                        ),
                                      ),
                                      popupProps: const PopupProps.menu(
                                        showSearchBox: true,
                                      ),
                                      onChanged: (value) {
                                        setStateModal(() {
                                          selectedClients.clear();
                                          if (value != null &&
                                              value != allValue) {
                                            selectedClients.add(value);
                                          }
                                        });
                                      },
                                    ),

                                  const SizedBox(height: 12),

                                  const SizedBox(height: 16),
                                ],
                              ),

                              const SizedBox(height: 8),
                              if (filtered.isEmpty)
                                Text(t.noJobsFilterMessage)
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final job = filtered[index];
                                    final clientNames =
                                        job.clientesAsignados.isNotEmpty
                                        ? job.clientesAsignados.join(', ')
                                        : job.cliente;
                                    final dateRange =
                                        '${dateFormatter.format(job.fechaInicio)} - ${dateFormatter.format(job.fechaFin)}';
                                    final timeRange =
                                        '${timeFormatter.format(job.fechaInicio)} - ${timeFormatter.format(job.fechaFin)}';
                                    final extra = extraInfo?[job.id];
                                    Widget secondaryWidget;
                                    if (extra != null) {
                                      secondaryWidget = Text(extra);
                                    } else if (widget.role == 'PERF_ADMIN') {
                                      secondaryWidget = CurrencyText(
                                        job.costo,
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    } else {
                                      final text = widget.role == 'PERF_TEC'
                                          ? dateRange
                                          : timeRange;
                                      secondaryWidget = Text(text);
                                    }

                                    final usuariosModal = context
                                        .read<UsuariosViewModel>();
                                    final techNames =
                                        job.empleadosAsignados.isNotEmpty
                                        ? job.empleadosAsignados
                                              .map((id) {
                                                final u = usuariosModal.usuarios
                                                    .firstWhere(
                                                      (user) => user.id == id,
                                                      orElse: () => Usuario(
                                                        id: '',
                                                        authUid: '',
                                                        nombre: id,
                                                        email: '',
                                                        idEmpresa: '',
                                                        perfilId: '',
                                                      ),
                                                    );
                                                return u.nombre;
                                              })
                                              .join(', ')
                                        : '';
                                    return ListTile(
                                      leading: const Icon(Icons.work_outline),
                                      title: Text(job.titulo),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            clientNames.isNotEmpty
                                                ? clientNames
                                                : t.withoutClient,
                                          ),
                                          secondaryWidget,
                                          if (techNames.isNotEmpty)
                                            Text(
                                              '${t.techniciansPrefix}$techNames',
                                            ),
                                        ],
                                      ),
                                      trailing: Chip(
                                        label: Text(_getStatusText(job.estado)),
                                        backgroundColor: _statusColor(
                                          job.estado,
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => JobDetailPage(
                                              job: job,
                                              role: widget.role,
                                              userName: widget.userName,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// BotÃ³n para administradores que navega a la lista completa de
  /// problemas reportados.  En lugar de abrir un diÃ¡logo local,
  /// redirige a la [ProblemsPage] para consultar todos los
  /// problemas pendientes.
  // _buildAdminProblemsButton quedÃ³ sin uso tras la refactorizaciÃ³n que
  // centraliza la navegaciÃ³n a la pÃ¡gina de problemas. Se ha
  // eliminado el contenido de este mÃ©todo para evitar advertencias de
  // "unused_element". Si en el futuro se necesita un botÃ³n de
  // administraciÃ³n especÃ­fico, puede reintroducirse aquÃ­.
  // ignore: unused_element
  Widget _buildAdminProblemsButton(BuildContext context) {
    return const SizedBox.shrink();
  }

  /// Four metric cards laid out in a 2Ã—2 grid.
  Widget _buildMetricsGrid() {
    // Calcular mÃ©tricas utilizando los trabajos asignados.  Se fusionan
    // las asignaciones con el catÃ¡logo para disponer de informaciÃ³n
    // descriptiva y luego se filtra por tÃ©cnico cuando corresponde.
    final asignadosVM = context.watch<TrabajosAsignadosViewModel>();
    final trabajosVM = context.watch<TrabajosViewModel>();
    final asignados = asignadosVM.trabajos;
    final converted = _mapAsignacionesToTrabajos(
      asignados,
      trabajosVM.trabajos,
    );
    final relevantJobs = widget.role == 'PERF_TEC'
        ? converted
              .where((t) => t.empleadosAsignados.contains(widget.userName))
              .toList()
        : converted;
    
    final selectedDate = _selectedDate ?? DateTime.now();
    final today = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    final jobsToday = relevantJobs.where((t) {
      final start = DateTime(
        t.fechaInicio.year,
        t.fechaInicio.month,
        t.fechaInicio.day,
      );
      final end = DateTime(t.fechaFin.year, t.fechaFin.month, t.fechaFin.day);
      return today.compareTo(start) >= 0 && today.compareTo(end) <= 0;
    }).toList();
    final completedJobs = relevantJobs
        .where((t) => _isCompletedStatus(t.estado))
        .toList();
    final pendingJobs = relevantJobs
        .where(
          (t) => _isPendingStatus(t.estado) || _isInProgressStatus(t.estado),
        )
        .toList();
    // NUEVO: Calcular horas registradas sumando las horas acumuladas 
    // de los trabajos que están programados para el día seleccionado.
    // Esto vincula las horas mostradas a la "fecha del trabajo" en lugar
    // de a la "fecha de la sesión".
    // (Histórico) No dependemos de sesiones del día aquí.

    // Horas registradas para la fecha seleccionada, pero solo para trabajos
    // programados/activos ese día (evita mostrar horas en fechas sin trabajos).
    final range = _registeredHoursRange;
    final sesionesVM = context.watch<SesionesViewModel>();

    String horasStr;
    if (range != null) {
      final total = _registeredHoursRangeTotal;
      if (total == null) {
        horasStr = '...';
      } else if (total == total.roundToDouble()) {
        horasStr = total.toStringAsFixed(0);
      } else {
        horasStr = total.toStringAsFixed(1);
      }
    } else {
      final dailyHours = sesionesVM.dailyHours;
      final double totalHoras = widget.role == 'PERF_TEC'
          ? (dailyHours[widget.userId] ?? 0.0)
          : dailyHours.values.fold(0.0, (s, v) => s + v);
      if (totalHoras == totalHoras.roundToDouble()) {
        horasStr = totalHoras.toStringAsFixed(0);
      } else {
        horasStr = totalHoras.toStringAsFixed(1);
      }
    }

    return GridView.count(
      crossAxisCount: 2,
      // Ajustar el aspect ratio para hacer las tarjetas mÃ¡s anchas
      // que altas, pero con suficiente altura para textos largos.
      childAspectRatio: 1.5,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _MetricCard(
          title: AppLocalizations.of(context)!.jobsTodayMetric,
          value: '${jobsToday.length}',
          color: Theme.of(context).primaryColor,
          // Pasar el texto traducido como identificador de mÃ©trica.  Esto permite
          // que el mÃ©todo _showMetricDetails compare contra el valor
          // traducido y funcione independientemente del idioma seleccionado.
          onTap: () =>
              _showMetricDetails(AppLocalizations.of(context)!.jobsTodayMetric),
        ),
        _MetricCard(
          title: AppLocalizations.of(context)!.registeredHoursMetric,
          value: horasStr,
          color: Colors.green,
          onTap: () => _showMetricDetails(
            AppLocalizations.of(context)!.registeredHoursMetric,
          ),
        ),
        _MetricCard(
          title: AppLocalizations.of(context)!.completedJobsMetric,
          value: '${completedJobs.length}',
          color: Theme.of(context).primaryColor,
          onTap: () => _showMetricDetails(
            AppLocalizations.of(context)!.completedJobsMetric,
          ),
        ),
        _MetricCard(
          title: AppLocalizations.of(context)!.pendingJobsMetric,
          value: '${pendingJobs.length}',
          color: Colors.orange,
          onTap: () => _showMetricDetails(
            AppLocalizations.of(context)!.pendingJobsMetric,
          ),
        ),
      ],
    );
  }

  /// Calendar heading and a basic placeholder grid for dates.
  Widget _buildCalendarSection(BuildContext context) {
    // Lista de nombres de los meses en espaÃ±ol.
    final locale = Localizations.localeOf(context).toString();
    final TextStyle? headingStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final monthLabel = DateFormat.yMMMM(locale).format(_currentMonth);

    // Calcular los dÃ­as del mes y las celdas necesarias para construir
    // el calendario.  Cada fila tiene siete columnas (lunesâ€‘domingo).
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final daysInMonth = DateUtils.getDaysInMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    // Convertir weekday (lunes=1..domingo=7) a Ã­ndice basado en lunes=0.
    int startIndex = firstDayOfMonth.weekday - 1;
    if (startIndex < 0) startIndex = 0;
    final List<DateTime?> cells = [];
    // AÃ±adir celdas vacÃ­as para el inicio de la semana.
    for (int i = 0; i < startIndex; i++) {
      cells.add(null);
    }
    // AÃ±adir cada dÃ­a del mes.
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(_currentMonth.year, _currentMonth.month, d));
    }
    // Rellenar el resto para completar semanas completas (42 celdas mÃ¡ximo).
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    // FunciÃ³n auxiliar para renderizar una celda del calendario.
    Widget buildCell(DateTime? date) {
      final bool isSelected =
          _selectedDate != null &&
          date != null &&
          date.year == _selectedDate!.year &&
          date.month == _selectedDate!.month &&
          date.day == _selectedDate!.day;
      // Obtener lista de trabajos que abarcan esta fecha para
      // colorear la celda con franjas.  Ahora utilizamos las
      // asignaciones convertidas a trabajos para asegurar que
      // consideramos el estado y las fechas correctas.  Filtramos
      // por tÃ©cnico si el rol es de tÃ©cnico.
      final List<Trabajo> jobsOnDate = [];
      if (date != null) {
        final asignadosVM = context.watch<TrabajosAsignadosViewModel>();
        final trabajosVM = context.watch<TrabajosViewModel>();
        final asignaciones = asignadosVM.trabajos;
        final converted = _mapAsignacionesToTrabajos(
          asignaciones,
          trabajosVM.trabajos,
        );
        final List<Trabajo> trabajos = widget.role == 'PERF_TEC'
            ? converted
                  .where((t) => t.empleadosAsignados.contains(widget.userName))
                  .toList()
            : converted;
        final d = DateTime(date.year, date.month, date.day);
        for (final t in trabajos) {
          final start = DateTime(
            t.fechaInicio.year,
            t.fechaInicio.month,
            t.fechaInicio.day,
          );
          final end = DateTime(
            t.fechaFin.year,
            t.fechaFin.month,
            t.fechaFin.day,
          );
          if (d.compareTo(start) >= 0 && d.compareTo(end) <= 0) {
            jobsOnDate.add(t);
          }
        }
      }
      // Seleccionar hasta cuatro trabajos para pintar franjas; si hay mÃ¡s
      // se omiten los adicionales.
      final stripes = jobsOnDate.length > 4
          ? jobsOnDate.sublist(0, 4)
          : jobsOnDate;
      return GestureDetector(
        onTap: date == null
            ? null
            : () async {
                // Al seleccionar una fecha, actualizamos la selecciÃ³n
                // y limpiamos la lista de trabajos del dÃ­a anterior.  Si
                // Posteriormente detectamos trabajos, se asignarÃ¡ de nuevo
                // en `_showJobsForDate`.
                final sesionesVM = context.read<SesionesViewModel>();
                if (jobsOnDate.isNotEmpty) {
                  await sesionesVM.loadRegisteredHoursForDate(
                    widget.empresaId,
                    date,
                  );
                } else {
                  // Si no hay trabajos ese dÃ­a, no mostrar horas registradas.
                  sesionesVM.clearDailyRegisteredHours();
                }
                setState(() {
                  _selectedDate = date;
                });

                // await _showSelectedDateHoursModal(date);
                // if (!mounted) return;
                // Si hay trabajos en la fecha, mostrar el modal de trabajos;
                // dentro de este mÃ©todo se asignan `_selectedDateJobs` y se
                // gestionarÃ¡ la limpieza al cerrar el modal.
                if (jobsOnDate.isNotEmpty) {
                  _showJobsForDate(date);
                }
              },
        child: Container(
          height: 40,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Dibujar franjas horizontales de colores detrÃ¡s del nÃºmero
              if (stripes.isNotEmpty)
                Positioned.fill(
                  child: Row(
                    children: [
                      // Para cada trabajo seleccionado, crear un segmento horizontal con
                      // color especÃ­fico.  Usamos List.generate para evitar problemas
                      // de cierre de parÃ©ntesis en los bucles for.
                      ...List.generate(stripes.length, (i) {
                        return Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              // `withOpacity` estÃ¡ deprecado.  Usamos `withAlpha` con
                              // valores enteros para la opacidad (0â€“255).
                              color: _colorForJob(
                                stripes[i].id,
                              ).withAlpha(isSelected ? 128 : 77),
                              borderRadius: BorderRadius.horizontal(
                                left: i == 0
                                    ? const Radius.circular(8)
                                    : Radius.zero,
                                right: i == stripes.length - 1
                                    ? const Radius.circular(8)
                                    : Radius.zero,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              // Etiqueta de nÃºmero de trabajos (tooltip).  Se muestra
              // Ãºnicamente cuando hay mÃ¡s de un trabajo para la fecha.
              if (jobsOnDate.length > 1 && date != null)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${jobsOnDate.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // NÃºmero del dÃ­a
              Center(
                child: Text(
                  date != null ? '${date.day}' : '',
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: date != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(monthLabel, style: headingStyle),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month - 1,
                        1,
                      );
                      // Al cambiar de mes se elimina la selecciÃ³n de fecha
                      // y se limpia la lista de trabajos asociados.
                      _selectedDate = null;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month + 1,
                        1,
                      );
                      // Limpiar la fecha seleccionada y la lista de trabajos
                      _selectedDate = null;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Encabezados de dÃ­as de la semana (lunes a domingo)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Center(
                child: Text(DateFormat.E(locale).format(DateTime(2024, 1, 1))),
              ),
            ), // Monday
            Expanded(
              child: Center(
                child: Text(DateFormat.E(locale).format(DateTime(2024, 1, 2))),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(DateFormat.E(locale).format(DateTime(2024, 1, 3))),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(DateFormat.E(locale).format(DateTime(2024, 1, 4))),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(DateFormat.E(locale).format(DateTime(2024, 1, 5))),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(DateFormat.E(locale).format(DateTime(2024, 1, 6))),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(DateFormat.E(locale).format(DateTime(2024, 1, 7))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // ConstrucciÃ³n de las filas del calendario
        Table(
          border: TableBorder.symmetric(
            inside: const BorderSide(color: Colors.transparent),
          ),
          children: [
            for (int i = 0; i < cells.length; i += 7)
              TableRow(
                children: [for (int j = 0; j < 7; j++) buildCell(cells[i + j])],
              ),
          ],
        ),
      ],
    );
  }

  /// Helper to build a row for the calendar table.
  // Este mÃ©todo ya no se utiliza. Se mantiene un stub para evitar
  // advertencias por elemento no utilizado. Devuelve una fila vacÃ­a
  // sin celdas interactivas.
  // ignore: unused_element
  // ignore: unused_element
  TableRow _buildCalendarRow(List<String> cells, {bool header = false}) {
    if (header) {
      // Placeholder to avoid unused parameter warning.
    }
    // Genera una fila vac?a con tantas celdas como elementos tenga la lista.
    return TableRow(children: [for (var _ in cells) const SizedBox.shrink()]);
  }

  /// Section listing todayâ€™s jobs with status badges and actions.

  /// Section of quick action buttons.
  // ignore: unused_element
  Widget _buildQuickActionsSection(BuildContext context) {
    final TextStyle? sectionTitleStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.quickActionsTitle,
          style: sectionTitleStyle,
        ),
        const SizedBox(height: 8),
        // Removed "Registrar Llegada" action (admins/technicians no longer track arrivals).
        _ActionButton(
          label: AppLocalizations.of(context)!.reportProblemAction,
          color: Colors.red,
          // Al presionar se muestra un diÃ¡logo reutilizable para reportar
          // problemas (DialogoReporteProblema) que gestiona el formulario.
          onTap: () {
            // Capturar viewmodels y datos antes de abrir el diÃ¡logo para
            // evitar usar context despuÃ©s de operaciones async.
            final trabajosVM = context.read<TrabajosViewModel>();
            final gastosVM = context.read<GastosViewModel>();
            final problemasVM = context.read<ProblemasViewModel>();
            final jobs = trabajosVM.trabajos;
            final gastos = gastosVM.gastos;
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              enableDrag: false,
              builder: (_) => DialogoReporteProblema(
                userName: widget.userName,
                role: widget.role,
                jobs: jobs,
                gastos: gastos,
                onSave: (problem) async {
                  await problemasVM.agregar(problem);
                },
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        // Technicians register material expenses; other roles keep the original button.
        if (widget.role == 'PERF_TEC') ...[
          _ActionButton(
            label: AppLocalizations.of(context)!.registerMaterialsAction,
            color: Theme.of(context).primaryColor,
            onTap: _showRegisterMaterialExpenseDialog,
          ),
          const SizedBox(height: 6),
        ] else ...[
          _ActionButton(
            label: AppLocalizations.of(context)!.requestMaterialsAction,
            color: Theme.of(context).primaryColor,
            onTap: () {},
          ),
          const SizedBox(height: 6),
        ],
        // Removed "Ver Historial" action.
        // Only administrators can view the list of reported problems.
        if (widget.role == 'PERF_ADMIN') ...[
          _ActionButton(
            label: AppLocalizations.of(context)!.viewProblemsAction,
            color: Colors.orange,
            onTap: () {
              // Navegar a la pÃ¡gina de problemas para que los
              // administradores consulten todas las incidencias.
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
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  // Se eliminÃ³ el formulario de registro de actividades porque la
  // funcionalidad se gestiona ahora fuera de esta pÃ¡gina.

  // Se eliminÃ³ el mÃ©todo _clearForm porque ya no se utiliza.

  // Se eliminÃ³ el mÃ©todo _registerActivity porque el registro de
  // actividades se maneja fuera de esta pÃ¡gina.

  // Se eliminÃ³ el mÃ©todo _buildActivitiesList porque ya no se utiliza.
}

/// Simple model class for an activity record.
// Se eliminÃ³ la clase interna _Activity porque el registro de
// actividades se maneja en otra parte de la aplicaciÃ³n.

/// A reusable card for metric values on the dashboard.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
  });
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Standardized Card styling to match ClientsPage and DashboardPage
    final cardContent = Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: Padding(
        // Reducir el padding para hacer mÃ¡s compacta la tarjeta de mÃ©tricas.
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                // Reducir el tamaÃ±o de fuente para una tarjeta mÃ¡s pequeÃ±a.
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: cardContent,
      );
    }
    return cardContent;
  }
}

/// A reusable button for quick actions.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        child: Text(label),
      ),
    );
  }
}

String _formatFecha(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final y = date.year.toString();
  return '$d/$m/$y';
}
