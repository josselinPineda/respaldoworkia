import 'package:flutter/material.dart';
import '../models/job.dart';

// Importamos dropdown_search para crear filtros con búsqueda y selección
// múltiple.  Ver https://pub.dev/packages/dropdown_search para detalles.
import 'package:dropdown_search/dropdown_search.dart';
import 'package:workia/l10n/app_localizations.dart';

/// Signature for loading a list of jobs for a given day.
typedef JobsLoader = Future<List<Trabajo>> Function(DateTime date);

/// Muestra un panel flotante (bottom sheet) con el listado de trabajos para
/// la fecha dada, incluyendo filtros por estado, cliente, técnico y rango de
/// fechas.  Permite buscar por título, cliente o descripción.
Future<void> showJobsForDatePanel({
  required BuildContext context,
  required DateTime date,
  required JobsLoader loader,
}) async {
  // Normalizamos la fecha inicial al día.
  final DateTime initialDay = DateUtils.dateOnly(date);
  // Carga inicial de trabajos únicamente para el día seleccionado.
  List<Trabajo> trabajos = await loader(initialDay);
  // Rango inicial de fechas (solo un día).
  DateTime rangeStart = initialDay;
  DateTime rangeEnd = initialDay;
  // Controlador para búsqueda por texto.
  final searchCtrl = TextEditingController();
  // Filtros por estado, cliente y técnico.  Los valores 'Todos' indican
  // selección nula (sin filtro).
  String estadoFilter = 'Todos';
  // Lista de clientes seleccionados para filtrado (multi selección).  Vacía
  // significa que se incluyen todos los clientes.
  List<String> clienteFilterList = [];
  // Lista de técnicos seleccionados para filtrado (multi selección).  Vacía
  // significa que se incluyen todos los técnicos.
  List<String> tecnicoFilterList = [];
  // Bandera para mostrar indicador de carga mientras se cargan trabajos
  // adicionales al cambiar el rango.
  bool cargando = false;

  /// Devuelve una lista única de todos los clientes presentes en [jobs].
  List<String> _obtenerClientes(List<Trabajo> jobs) {
    final set = <String>{};
    for (final t in jobs) {
      if (t.clientesAsignados.isNotEmpty) {
        set.addAll(t.clientesAsignados);
      } else {
        set.add(t.cliente);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Devuelve una lista única de todos los técnicos (empleados asignados) presentes en [jobs].
  List<String> _obtenerTecnicos(List<Trabajo> jobs) {
    final set = <String>{};
    for (final t in jobs) {
      set.addAll(t.empleadosAsignados);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Filtra la lista [trabajos] en función de los parámetros de búsqueda y filtros.
  List<Trabajo> applyFilters() {
    final query = searchCtrl.text.trim().toLowerCase();
    return trabajos.where((t) {
      // Comprobar si el trabajo ocurre dentro del rango seleccionado.
      final jobStart = DateUtils.dateOnly(t.fechaInicio);
      final jobEnd = DateUtils.dateOnly(t.fechaFin);
      final insideRange =
          !rangeEnd.isBefore(jobStart) && !rangeStart.isAfter(jobEnd);
      // Búsqueda textual: título, cliente principal, clientes asignados y descripción.
      final matchesQuery =
          query.isEmpty ||
          t.titulo.toLowerCase().contains(query) ||
          t.cliente.toLowerCase().contains(query) ||
          t.descripcion.toLowerCase().contains(query) ||
          t.clientesAsignados.any((c) => c.toLowerCase().contains(query));
      // Filtro de estado (cadena única).  Si es "Todos" se ignora.
      final matchesEstado =
          estadoFilter == 'Todos' ||
          t.estado.toLowerCase() == estadoFilter.toLowerCase();
      // Filtro de clientes (lista múltiple).  Si la lista está vacía se ignora.
      final matchesCliente =
          clienteFilterList.isEmpty ||
          clienteFilterList.any(
            (c) => t.cliente == c || t.clientesAsignados.contains(c),
          );
      // Filtro de técnicos (lista múltiple).  Si la lista está vacía se ignora.
      final matchesTecnico =
          tecnicoFilterList.isEmpty ||
          tecnicoFilterList.any((tec) => t.empleadosAsignados.contains(tec));
      return insideRange &&
          matchesQuery &&
          matchesEstado &&
          matchesCliente &&
          matchesTecnico;
    }).toList()..sort(
      (a, b) => a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase()),
    );
  }

  /// Carga trabajos para un rango de fechas desde [start] hasta [end] (inclusive),
  /// acumulando resultados únicos por identificador.
  Future<void> cargarTrabajosParaRango(
    DateTime start,
    DateTime end,
    void Function(void Function()) setState,
  ) async {
    // Normalizar a inicios de día.
    final DateTime s = DateUtils.dateOnly(start);
    final DateTime e = DateUtils.dateOnly(end);
    // Mostrar indicador de carga.
    setState(() => cargando = true);
    final List<Trabajo> nuevos = [];
    final Set<String> ids = {};
    DateTime current = s;
    // Recorrer cada día en el rango.
    while (!current.isAfter(e)) {
      final list = await loader(current);
      for (final t in list) {
        if (ids.add(t.id)) {
          nuevos.add(t);
        }
      }
      current = current.add(const Duration(days: 1));
    }
    // Actualizar lista de trabajos y bandera de carga.
    setState(() {
      trabajos = nuevos;
      cargando = false;
    });
  }

  if (!context.mounted) return;
  // Mostrar el panel.
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    isDismissible: false,
    barrierColor: Colors.black.withOpacity(0.25),
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          // Localizations for dynamic strings
          final t = AppLocalizations.of(ctx)!;
          // Recalcular las listas de clientes y técnicos cada vez que los trabajos cambian.
          final clientesUnicos = _obtenerClientes(trabajos);
          final tecnicosUnicos = _obtenerTecnicos(trabajos);
          // Normalize default filter value to current locale's 'all' option
          if (estadoFilter == 'Todos' || estadoFilter == 'All') {
            estadoFilter = t.allOption;
          }
          // Calcular si la fecha seleccionada es hoy para mostrar un título amigable.
          final hoy =
              rangeStart == rangeEnd &&
              DateUtils.isSameDay(rangeStart, DateTime.now());
          final titulo = hoy
              ? t.todayJobsLabel
              : '${t.jobsOfPrefix}${_formatFecha(rangeStart)}${rangeStart == rangeEnd ? '' : ' - ${_formatFecha(rangeEnd)}'}';
          final trabajosFiltrados = applyFilters();
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado con título y botón de cierre.
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            titulo,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Buscador.
                    TextField(
                      controller: searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: t.searchJobOrClientPlaceholder,

                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Acordeón de filtros utilizando dropdown_search para permitir
                    // selección con búsqueda y multi selección.  Al hacer clic
                    // en el encabezado, se despliega para mostrar los campos.
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        childrenPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          t.filtersTitle,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        children: [
                          // Estado: selección simple (incluye 'Todos' que corresponde a null).  A partir de
                          // dropdown_search 6.x, la lista de ítems debe proporcionarse mediante una
                          // función.  El parámetro decoratorProps se usa para definir la decoración.
                          DropdownSearch<String>(
                            items: (String filter, LoadProps? loadProps) => [
                              t.allOption,
                              t.jobStatusPending,
                              t.jobStatusInProgress,
                              t.jobStatusCompleted,
                              t.jobStatusCancelled,
                            ],
                            selectedItem: estadoFilter == t.allOption
                                ? null
                                : estadoFilter,
                            decoratorProps: DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: t.statusLabel,
                                isDense: true,
                              ),
                            ),
                            popupProps: const PopupProps.menu(
                              showSearchBox: true,
                            ),
                            onChanged: (String? value) {
                              setState(() {
                                estadoFilter = value ?? t.allOption;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          // Cliente: multi selección.  A partir de dropdown_search 6.x, la lista de
                          // ítems debe proporcionarse mediante una función.  Usamos decoratorProps
                          // para el InputDecoration.
                          DropdownSearch<String>.multiSelection(
                            items: (String filter, LoadProps? loadProps) =>
                                clientesUnicos,
                            selectedItems: clienteFilterList,
                            decoratorProps: DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: t.clientLabel,
                                isDense: true,
                              ),
                            ),
                            popupProps: const PopupPropsMultiSelection.menu(
                              showSearchBox: true,
                            ),
                            onChanged: (List<String> values) {
                              setState(() {
                                clienteFilterList = values;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          // Técnico: multi selección.  Lista a través de una función.
                          DropdownSearch<String>.multiSelection(
                            items: (String filter, LoadProps? loadProps) =>
                                tecnicosUnicos,
                            selectedItems: tecnicoFilterList,
                            decoratorProps: DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: t.techniciansLabel,
                                isDense: true,
                              ),
                            ),
                            popupProps: const PopupPropsMultiSelection.menu(
                              showSearchBox: true,
                            ),
                            onChanged: (List<String> values) {
                              setState(() {
                                tecnicoFilterList = values;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          // Rango de fechas: se muestran dos calendarios para seleccionar las
                          // fechas de inicio y fin. Cada calendario está limitado en altura para
                          // evitar desbordes y permite seleccionar las fechas directamente dentro del panel.
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.fromDateLabel,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 300,
                                child: CalendarDatePicker(
                                  initialDate: rangeStart,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  currentDate: DateTime.now(),
                                  onDateChanged: (DateTime newDate) {
                                    // Si la nueva fecha de inicio es posterior a la fecha final, ajustamos la fecha final.
                                    setState(() {
                                      rangeStart = DateUtils.dateOnly(newDate);
                                      if (rangeEnd.isBefore(rangeStart)) {
                                        rangeEnd = rangeStart;
                                      }
                                    });
                                    // Recargar trabajos para el nuevo rango.
                                    cargarTrabajosParaRango(
                                      rangeStart,
                                      rangeEnd,
                                      setState,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                t.toDateLabel,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 300,
                                child: CalendarDatePicker(
                                  initialDate: rangeEnd,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  currentDate: DateTime.now(),
                                  onDateChanged: (DateTime newDate) {
                                    // Si la nueva fecha final es anterior a la fecha inicio, ajustamos la fecha inicio.
                                    setState(() {
                                      rangeEnd = DateUtils.dateOnly(newDate);
                                      if (rangeEnd.isBefore(rangeStart)) {
                                        rangeStart = rangeEnd;
                                      }
                                    });
                                    // Recargar trabajos para el nuevo rango.
                                    cargarTrabajosParaRango(
                                      rangeStart,
                                      rangeEnd,
                                      setState,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Muestra el rango seleccionado debajo de los calendarios.
                              Text(
                                'Rango seleccionado: ${_formatFecha(rangeStart)} - ${_formatFecha(rangeEnd)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // El rango de fechas se gestiona dentro del acordeón de filtros mediante
                    // dos calendarios (inicio y fin).  Esto permite elegir un rango
                    // directamente en el panel, sin abrir diálogos adicionales.
                    // Botón para limpiar filtros.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () async {
                          searchCtrl.clear();
                          estadoFilter = 'Todos';
                          clienteFilterList = [];
                          tecnicoFilterList = [];
                          rangeStart = initialDay;
                          rangeEnd = initialDay;
                          // Recargar trabajos sólo para la fecha inicial.
                          await cargarTrabajosParaRango(
                            rangeStart,
                            rangeEnd,
                            setState,
                          );
                        },
                        child: Text(t.clearFiltersButton),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Lista de trabajos (o indicador de carga).
                    Expanded(
                      child: cargando
                          ? const Center(child: CircularProgressIndicator())
                          : trabajosFiltrados.isEmpty
                          ? Center(child: Text(t.noJobsForRangeMessage))
                          : ListView.builder(
                              itemCount: trabajosFiltrados.length,
                              itemBuilder: (ctx, i) =>
                                  _TrabajoRowDetailed(trabajosFiltrados[i]),
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

/// Tarjeta con todos los detalles de un trabajo, similar al diseño de la
/// captura de ejemplo.  Muestra el título, clientes, rango de horas,
/// técnicos y un chip de estado con color.
class _TrabajoRowDetailed extends StatelessWidget {
  final Trabajo t;
  const _TrabajoRowDetailed(this.t);

  @override
  Widget build(BuildContext context) {
    // Construir listas de clientes y técnicos para mostrar.
    final clientes = t.clientesAsignados.isNotEmpty
        ? t.clientesAsignados
        : [t.cliente];
    final tecnicos = t.empleadosAsignados;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono a la izquierda.
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: const Icon(Icons.work, size: 20),
            ),
            const SizedBox(width: 12),
            // Área de texto.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          t.titulo,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _EstadoChip(estado: t.estado),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Clientes.
                  Text(
                    'Clientes: ${clientes.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  // Hora.
                  Text(
                    'Hora: ${_formatRangoHora(t.fechaInicio, t.fechaFin)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  // Técnicos.
                  Text(
                    'Técnicos: ${tecnicos.isNotEmpty ? tecnicos.join(', ') : '—'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip de estado reutilizable con colores según el valor de estado.
class _EstadoChip extends StatelessWidget {
  final String estado;
  const _EstadoChip({required this.estado});

  Color _color(BuildContext context) {
    // Normalizamos el estado reemplazando guiones bajos por espacios y
    // convirtiendo a minúsculas para uniformidad.  Esto permite
    // interpretar valores provenientes de Firestore como 'En_progreso'.
    final e = estado.replaceAll('_', ' ').toLowerCase();
    switch (e) {
      case 'completo':
      case 'finalizado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      case 'en progreso':
        return Colors.orange;
      case 'pendiente':
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c),
      ),
    );
  }
}

/// Formatea una fecha en formato DD/MM/AAAA.
String _formatFecha(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final y = date.year.toString();
  return '$d/$m/$y';
}

/// Formatea el rango de horas de un trabajo como 'hh:mm - hh:mm'.
String _formatRangoHora(DateTime ini, DateTime fin) {
  String two(int n) => n.toString().padLeft(2, '0');
  final di = '${two(ini.hour)}:${two(ini.minute)}';
  final df = '${two(fin.hour)}:${two(fin.minute)}';
  return '$di - $df';
}
