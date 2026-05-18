import 'package:flutter/material.dart';

import 'package:workia/views/settings/user_settings_page.dart';
import 'package:provider/provider.dart';
import 'package:workia/presentation/viewmodels/reportes_viewmodel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:workia/services/export_service.dart';
import 'package:workia/widgets/export_format_dialog.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/widgets/currency_text.dart';
import 'package:workia/presentation/viewmodels/empresa_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/presentation/viewmodels/gastos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';

/// Page summarizing financial performance such as income,
/// expenses and net balance over a selected period.  This simple
/// implementation uses static numbers and a dropdown to select
/// time ranges.  A real implementation would include charts and
/// dynamic data retrieval.
class BalancePage extends StatefulWidget {
  const BalancePage({
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

  /// Optional report controller.  If not provided a new
  /// controller will be created using default job and expenses
  /// controllers.
  /// Controlador opcional para calcular los reportes.  Si no se
  /// proporciona, se utilizará la instancia global en español
  /// [ControladoresApp.reportes], de tipo [ControladorReportes].
  // El controlador de reportes se gestiona ahora a través del
  // ReportesViewModel y Provider.  Por compatibilidad se elimina
  // esta propiedad.
  // final ControladorReportes? reportController;

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  String _selectedRange = '';
  List<String> _ranges = [];
  final ExportService _exportService = ExportService();
  bool _exportando = false;
  Set<String> _selectedChart = {'summary'};
  int _pieTouchedIndex = -1;
  DateTimeRange? _customDateRange;
  bool _useCustomRange = false;

  @override
  void initState() {
    super.initState();
    // Ejecutar el cálculo inicial después del primer frame para
    // asegurar que el contexto esté disponible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmpresaViewModel>().cargarEmpresa(widget.empresaId);
      context.read<GastosViewModel>().cargarTipos(widget.empresaId);
      context.read<ClientesViewModel>().cargarClientes(widget.empresaId);
      // Inicializar los rangos con las traducciones
      final t = AppLocalizations.of(context)!;
      _ranges = [
        'Hoy',
        'Esta Semana',
        t.thisMonthOption,
        'Este A\u00F1o',
      ];

      _selectedRange = 'Hoy';

      _runCalculo();
    });
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _openBalanceFiltersSheet() async {
    final theme = Theme.of(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final range = _customDateRange;

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

            Future<void> pickRange() async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                initialDateRange: range ??
                    DateTimeRange(
                      start: DateTime.now().subtract(const Duration(days: 7)),
                      end: DateTime.now(),
                    ),
              );
              if (picked == null) return;
              setStateModal(() {
                _customDateRange = picked;
                _useCustomRange = true;
              });
            }

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.72,
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
                                _customDateRange = null;
                                _useCustomRange = false;
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
                            onTap: pickRange,
                          ),
                          const SizedBox(width: 12),
                          dateCard(
                            label: 'Hasta',
                            value: range?.end,
                            onTap: pickRange,
                          ),
                        ],
                      ),
                      const Spacer(),
                      SafeArea(
                        top: false,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {});
                              _runCalculo();
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

  /// Calcula los reportes para el rango seleccionado utilizando
  /// el ReportesViewModel.  Determina el rango de fechas según
  /// [_selectedRange] y solicita el cálculo al view model.
  void _runCalculo() {
    if (_ranges.isEmpty)
      return; // Esperar a que se inicialicen las traducciones
    final t = AppLocalizations.of(context)!;
    final now = DateTime.now();
    DateTime inicio;
    DateTime fin;
    if (_useCustomRange && _customDateRange != null) {
      inicio = DateTime(
        _customDateRange!.start.year,
        _customDateRange!.start.month,
        _customDateRange!.start.day,
      );
      fin = DateTime(
        _customDateRange!.end.year,
        _customDateRange!.end.month,
        _customDateRange!.end.day,
        23,
        59,
        59,
        999,
      );
    } else
    if (_selectedRange == 'Hoy') {
      inicio = DateTime(now.year, now.month, now.day);
      fin = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    } else if (_selectedRange == 'Esta Semana') {
      final startOfWeek = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - DateTime.monday));
      inicio = startOfWeek;
      fin = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
    } else if (_selectedRange == t.thisMonthOption) {
      inicio = DateTime(now.year, now.month, 1);
      fin = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
    } else if (_selectedRange == 'Este A\u00F1o') {
      inicio = DateTime(now.year, 1, 1);
      fin = DateTime(now.year, 12, 31, 23, 59, 59, 999);
    } else {
      // Fallback: mes actual
      inicio = DateTime(now.year, now.month, 1);
      fin = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
    }
    // Solicitar el cálculo al view model
    final vm = context.read<ReportesViewModel>();
    vm.calcular(inicio, fin, widget.empresaId);
  }

  /// Compute the initials of the current user's name.
  String _initials() {
    final parts = widget.userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Exporta los datos de balance en el formato seleccionado por el usuario.
  Future<void> _exportarDatos() async {
    // Mostrar diálogo de selección de formato
    final formato = await ExportFormatDialog.show(context);
    if (formato == null || !mounted) {
      return;
    }

    setState(() {
      _exportando = true;
    });

    final t = AppLocalizations.of(context)!;

    try {
      // Obtener datos del view model
      final reportes = context.read<ReportesViewModel>();
      final datos = reportes.obtenerDatosParaExportar();

      // Enriquecer datos para exportación (PDF/Excel/CSV) con nombres legibles
      final clientesVM = context.read<ClientesViewModel>();
      final gastosVM = context.read<GastosViewModel>();
      final empresaVM = context.read<EmpresaViewModel>();
      datos['clientesById'] = {
        for (final c in clientesVM.clientes) c.id: c.nombre,
      };
      datos['tiposGastoById'] = {
        for (final tG in gastosVM.tipos) tG.id: tG.nombre,
      };
      // Moneda: si hay tasa de cambio, exportar en moneda local (peso); si no, USD.
      final locale = Localizations.localeOf(context);
      final tasa = empresaVM.empresa?.tasaCambio;
      final hasExchange = tasa != null && tasa > 0;
      datos['exchangeRate'] = hasExchange ? tasa : 1.0;
      // Si hay tasa, exportar en moneda local (Lempira). Si no, USD.
      datos['currencySymbol'] = hasExchange ? 'L' : '\$';

      // Obtener el locale actual
      // (ya obtenido arriba)

      // Exportar
      final rutaArchivo = await _exportService.exportar(
        formato,
        datos,
        _selectedRange,
        locale, // Pasar el locale
      );

      if (!mounted) return;

      setState(() {
        _exportando = false;
      });

      // Mostrar mensaje de éxito con opción de compartir
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.fileSavedSuccess),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: t.shareAction,
            textColor: Colors.white,
            onPressed: () async {
              await _exportService.compartirArchivo(rutaArchivo);
            },
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _exportando = false;
      });

      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.exportError(e.toString())),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportes = context.watch<ReportesViewModel>();
    final incomes = reportes.ingresos;
    final expenses = reportes.gastos;
    final balance = reportes.balance;
    final margin = reportes.margen;
    final t = AppLocalizations.of(context)!;

    final empresaVM = context.watch<EmpresaViewModel>();
    final tasa = empresaVM.empresa?.tasaCambio;
    final locale = Localizations.localeOf(context);
    final isSpanish = locale.languageCode == 'es';
    final hasExchange = isSpanish && tasa != null && tasa > 0;
    final currencySymbol = hasExchange ? 'L' : '\$';
    final exchangeRate = hasExchange ? tasa : 1.0;

    bool dentroRango(DateTime d) {
      final inicio = reportes.fechaInicio;
      final fin = reportes.fechaFin;
      if (inicio == null || fin == null) return true;
      return !d.isBefore(inicio) && !d.isAfter(fin);
    }

    int trabajosCompletadosCount = reportes.trabajosCalculados.where((job) {
      final e = job.estado.toLowerCase();
      final esCompletado =
          e == 'completo' || e == 'finalizado' || e == 'completado';
      return esCompletado && dentroRango(job.fechaFin);
    }).length;
    
    int gastosCount = reportes.gastosCalculados.length;

    // Load ClientesVM and GastosVM for naming
    final clientesVM = context.read<ClientesViewModel>();
    final gastosVM = context.read<GastosViewModel>();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRange,
                  icon: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor, size: 16),
                  dropdownColor: Colors.white,
                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                  items: _ranges.map((r) {
                    return DropdownMenuItem(value: r, child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(r),
                    ));
                  }).toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        _selectedRange = value;
                        _useCustomRange = false;
                      });
                      _runCalculo();
                    }
                  },
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.tune, color: Theme.of(context).primaryColor),
              tooltip: 'Configurar vista',
              onPressed: _openBalanceFiltersSheet,
            ),
            IconButton(
              icon: _exportando
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).primaryColor))
                  : Icon(Icons.download, color: Theme.of(context).primaryColor),
              onPressed: _exportando ? null : _exportarDatos,
              tooltip: 'Exportar datos',
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => UserSettingsPage(userName: widget.userName, role: widget.role)));
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 16, left: 4),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(_initials(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: false,
            indicatorColor: Theme.of(context).primaryColor,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.point_of_sale), text: 'Trabajos'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Gastos'),
              Tab(icon: Icon(Icons.account_balance_wallet), text: 'Finanzas'),
              Tab(icon: Icon(Icons.business), text: 'Clientes'),
            ],
          ),
        ),
        backgroundColor: Colors.grey[50], // Fondo claro para resaltar tarjetas
        body: TabBarView(
          children: [
            // TAB 1: VENTAS (Ingresos)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _SummaryCard(
                        label: 'Ingresos Totales',
                        value: Text('$currencySymbol${(incomes * exchangeRate).toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold)),
                        color: Colors.green,
                        icon: Icons.attach_money,
                      ),
                      _SummaryCard(
                        label: 'N\u00B0 de Trabajos',
                        value: Text('$trabajosCompletadosCount', style: const TextStyle(color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold)),
                        color: Colors.blue,
                        icon: Icons.receipt,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ChartContainer(
                    title: 'Ingresos por Período',
                    child: _BalanceCharts(
                      ingresosPorFecha: reportes.ingresosPorFecha,
                      gastosPorFecha: reportes.gastosPorFecha,
                      showBarChart: true,
                      showLineChart: false,
                      showIncomes: true,
                      showExpenses: false,
                      currencySymbol: currencySymbol,
                      exchangeRate: exchangeRate,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ChartContainer(
                    title: 'Ganancias por Técnico',
                    child: _TechniciansChart(
                      ingresosPorTecnico: reportes.ingresosPorTecnico,
                      usuariosVM: context.read<UsuariosViewModel>(),
                      currencySymbol: currencySymbol,
                      exchangeRate: exchangeRate,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            // TAB 2: GASTOS
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _SummaryCard(
                        label: 'Gastos Totales',
                        value: Text('$currencySymbol${(expenses * exchangeRate).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
                        color: Colors.red,
                        icon: Icons.money_off,
                      ),
                      _SummaryCard(
                        label: 'N° de Gastos',
                        value: Text('$gastosCount', style: const TextStyle(color: Colors.orange, fontSize: 20, fontWeight: FontWeight.bold)),
                        color: Colors.orange,
                        icon: Icons.receipt_long,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ChartContainer(
                    title: 'Gastos por Período',
                    child: _BalanceCharts(
                      ingresosPorFecha: reportes.ingresosPorFecha,
                      gastosPorFecha: reportes.gastosPorFecha,
                      showBarChart: true,
                      showLineChart: false,
                      showIncomes: false,
                      showExpenses: true,
                      currencySymbol: currencySymbol,
                      exchangeRate: exchangeRate,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ChartContainer(
                    title: 'Gastos por Categoría',
                    child: _GastosTipoChart(
                      gastosPorTipo: reportes.gastosPorTipo,
                      gastosVM: gastosVM,
                      currencySymbol: currencySymbol,
                      exchangeRate: exchangeRate,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            // TAB 3: FINANZAS (Resumen)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _SummaryCard(
                        label: 'Balance Neto',
                        value: Text('$currencySymbol${(balance * exchangeRate).toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
                        color: Theme.of(context).primaryColor,
                        icon: Icons.account_balance_wallet,
                      ),
                      _SummaryCard(
                        label: 'Margen',
                        value: Text('${margin.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.purple, fontSize: 20, fontWeight: FontWeight.bold)),
                        color: Colors.purple,
                        icon: Icons.percent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ChartContainer(
                    title: 'Resumen Ingresos vs Gastos',
                    child: _SummaryPieChart(
                      incomes: incomes,
                      expenses: expenses,
                      currencySymbol: currencySymbol,
                      exchangeRate: exchangeRate,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ChartContainer(
                    title: 'Evolución del Balance',
                    child: _BalanceCharts(
                      ingresosPorFecha: reportes.ingresosPorFecha,
                      gastosPorFecha: reportes.gastosPorFecha,
                      showBarChart: false,
                      showLineChart: true,
                      currencySymbol: currencySymbol,
                      exchangeRate: exchangeRate,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            // TAB 4: CLIENTES
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChartContainer(
                    title: 'Ingresos por Cliente',
                    child: _ClientesChart(
                      ingresosPorCliente: reportes.ingresosPorCliente,
                      clientesVM: clientesVM,
                      currencySymbol: currencySymbol,
                      exchangeRate: exchangeRate,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ChartContainer(
                    title: 'Trabajos más Frecuentes',
                    child: _TrabajosFrecuentesChart(
                      trabajosFrecuentes: reportes.trabajosFrecuentes,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartContainer({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.bar_chart, color: Theme.of(context).primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _SummaryPieChart extends StatelessWidget {
  const _SummaryPieChart({
    required this.incomes,
    required this.expenses,
    this.currencySymbol = 'L',
    this.exchangeRate = 1.0,
  });

  final double incomes;
  final double expenses;
  final String currencySymbol;
  final double exchangeRate;

  @override
  Widget build(BuildContext context) {
    if (incomes == 0 && expenses == 0) {
      return const Center(child: Text('No hay datos', style: TextStyle(color: Colors.grey)));
    }

    final colors = [Colors.green, Colors.red];
    double total = incomes + expenses;

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 35,
                sections: List.generate(2, (index) {
                  final monto = index == 0 ? incomes : expenses;
                  final percentage = total > 0 ? (monto / total) * 100 : 0.0;
                  
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: monto,
                    title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                    radius: 40,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                    ),
                    badgeWidget: null,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: 2,
              itemBuilder: (context, index) {
                final monto = index == 0 ? incomes : expenses;
                final itemName = index == 0 ? "Ingresos" : "Gastos";
                final percentage = total > 0 ? (monto / total) * 100 : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors[index % colors.length],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$itemName\nL ${(monto * exchangeRate).toStringAsFixed(2)} (${percentage.toStringAsFixed(0)}%)',
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GastosTipoChart extends StatelessWidget {
  final Map<String, double> gastosPorTipo;
  final GastosViewModel gastosVM;
  final String currencySymbol;
  final double exchangeRate;

  const _GastosTipoChart({
    required this.gastosPorTipo,
    required this.gastosVM,
    this.currencySymbol = 'L',
    this.exchangeRate = 1.0,
  });

  String _resolveName(String id) {
    if (id == 'Sin Clasificar') return id;
    try {
      return gastosVM.tipos.firstWhere((t) => t.id == id).nombre;
    } catch (_) {
      return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ocultar entradas cuyo tipo ya fue eliminado (evita IDs raros en pantalla)
    final validTypeIds = gastosVM.tipos.map((t) => t.id).toSet();
    final filteredEntries = gastosPorTipo.entries
        .where((e) => e.key == 'Sin Clasificar' || validTypeIds.contains(e.key))
        .toList();

    if (filteredEntries.isEmpty) {
      return const Center(child: Text('No hay datos', style: TextStyle(color: Colors.grey)));
    }

    final entries = filteredEntries;
    entries.sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      Colors.redAccent,
      Colors.orange,
      Colors.deepOrange,
      Colors.pink,
      Colors.purpleAccent,
      Colors.brown
    ];

    double total = entries.fold(0.0, (sum, e) => sum + e.value.toDouble());

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 35,
                sections: List.generate(entries.length, (index) {
                  final monto = entries[index].value.toDouble();
                  final percentage = total > 0 ? (monto / total) * 100 : 0.0;
                  
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: monto,
                    title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                    radius: 40,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                    ),
                    badgeWidget: null,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final monto = entries[index].value.toDouble();
                final itemName = _resolveName(entries[index].key);
                final percentage = total > 0 ? (monto / total) * 100 : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors[index % colors.length],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$itemName\nL ${(monto * exchangeRate).toStringAsFixed(2)} (${percentage.toStringAsFixed(0)}%)',
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientesChart extends StatelessWidget {
  final Map<String, double> ingresosPorCliente;
  final ClientesViewModel clientesVM;
  final String currencySymbol;
  final double exchangeRate;

  const _ClientesChart({
    required this.ingresosPorCliente,
    required this.clientesVM,
    this.currencySymbol = 'L',
    this.exchangeRate = 1.0,
  });

  String _resolveName(String id) {
    if (id == 'Sin Cliente') return id;
    try {
      return clientesVM.clientes.firstWhere((c) => c.id == id).nombre;
    } catch (_) {
      return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ingresosPorCliente.isEmpty) {
      return const Center(child: Text('No hay datos', style: TextStyle(color: Colors.grey)));
    }

    final entries = ingresosPorCliente.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal
    ];

    double total = ingresosPorCliente.values.fold(0.0, (sum, val) => sum + val.toDouble());

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 35,
                sections: List.generate(entries.length, (index) {
                  final monto = entries[index].value.toDouble();
                  final percentage = total > 0 ? (monto / total) * 100 : 0.0;
                  
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: monto,
                    title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                    radius: 40,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                    ),
                    badgeWidget: null,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final monto = entries[index].value.toDouble();
                final itemName = _resolveName(entries[index].key);
                final percentage = total > 0 ? (monto / total) * 100 : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors[index % colors.length],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$itemName\nL ${(monto * exchangeRate).toStringAsFixed(2)} (${percentage.toStringAsFixed(0)}%)',
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TrabajosFrecuentesChart extends StatelessWidget {
  final Map<String, int> trabajosFrecuentes;

  const _TrabajosFrecuentesChart({
    required this.trabajosFrecuentes,
  });

  String _resolveName(String id) {
    return id;
  }

  @override
  Widget build(BuildContext context) {
    if (trabajosFrecuentes.isEmpty) {
      return const Center(child: Text('No hay datos', style: TextStyle(color: Colors.grey)));
    }

    final entries = trabajosFrecuentes.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.redAccent,
      Colors.pink
    ];

    double total = trabajosFrecuentes.values.fold(0.0, (sum, val) => sum + val.toDouble());

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 35,
                sections: List.generate(entries.length, (index) {
                  final monto = entries[index].value.toDouble();
                  final percentage = total > 0 ? (monto / total) * 100 : 0.0;
                  
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: monto,
                    title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                    radius: 40,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                    ),
                    badgeWidget: null,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final monto = entries[index].value.toDouble();
                final itemName = _resolveName(entries[index].key);
                final percentage = total > 0 ? (monto / total) * 100 : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors[index % colors.length],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$itemName\n${monto.toInt()} (${percentage.toStringAsFixed(0)}%)',
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final Widget value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Icon(icon, color: color.withOpacity(0.7), size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: DefaultTextStyle(
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: color,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ) ??
                        const TextStyle(),
                    child: value,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCharts extends StatefulWidget {
  const _BalanceCharts({
    required this.ingresosPorFecha,
    required this.gastosPorFecha,
    this.showBarChart = true,
    this.showLineChart = true,
    this.showIncomes = true,
    this.showExpenses = true,
    this.currencySymbol = 'L',
    this.exchangeRate = 1.0,
  });

  final Map<DateTime, double> ingresosPorFecha;
  final Map<DateTime, double> gastosPorFecha;
  final bool showBarChart;
  final bool showLineChart;
  final bool showIncomes;
  final bool showExpenses;
  final String currencySymbol;
  final double exchangeRate;

  @override
  State<_BalanceCharts> createState() => _BalanceChartsState();
}

enum _BarRodKind { income, expense }

class _BalanceChartsState extends State<_BalanceCharts> {
  int _touchedIndex = -1;

  double convert(double value) {
    return value * widget.exchangeRate;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final rodKinds = <_BarRodKind>[
      if (widget.showIncomes) _BarRodKind.income,
      if (widget.showExpenses) _BarRodKind.expense,
    ];
    // Fechas relevantes según las series visibles (evita barras vacías)
    final Set<DateTime> fechasSet;
    if (widget.showIncomes && widget.showExpenses) {
      fechasSet = {
        ...widget.ingresosPorFecha.keys,
        ...widget.gastosPorFecha.keys,
      };
    } else if (widget.showIncomes) {
      fechasSet = {...widget.ingresosPorFecha.keys};
    } else if (widget.showExpenses) {
      fechasSet = {...widget.gastosPorFecha.keys};
    } else {
      fechasSet = <DateTime>{};
    }

    final fechas = fechasSet.toList()..sort();

    if (fechas.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (widget.showBarChart) ...[
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        Theme.of(context).colorScheme.inverseSurface,
                    tooltipHorizontalAlignment: FLHorizontalAlignment.right,
                    tooltipMargin: -10,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final fecha = fechas[group.x.toInt()];
                      final kind = rodIndex >= 0 && rodIndex < rodKinds.length
                          ? rodKinds[rodIndex]
                          : _BarRodKind.income;
                      final tipo = kind == _BarRodKind.income
                          ? t.incomeLabelSingular
                          : t.expenseLabelSingular;
                      return BarTooltipItem(
                        '${fecha.day}/${fecha.month}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text:
                                '$tipo: ${widget.currencySymbol}${convert(rod.toY).toStringAsFixed(2)}',
                            style: TextStyle(
                              color: kind == _BarRodKind.income
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          barTouchResponse == null ||
                          barTouchResponse.spot == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          barTouchResponse.spot!.touchedBarGroupIndex;
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= fechas.length) {
                          return const SizedBox.shrink();
                        }
                        // Mostrar solo algunas fechas para evitar saturación
                        if (fechas.length > 7 &&
                            index % (fechas.length ~/ 5) != 0) {
                          return const SizedBox.shrink();
                        }
                        final fecha = fechas[index];
                        return SideTitleWidget(
                          meta: meta,
                          space: 16,
                          child: Text(
                            '${fecha.day}/${fecha.month}',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 38,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '${widget.currencySymbol}${convert(value).toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(fechas.length, (index) {
                  final fecha = fechas[index];
                  final ingreso = widget.ingresosPorFecha[fecha] ?? 0;
                  final gasto = widget.gastosPorFecha[fecha] ?? 0;
                  final rods = <BarChartRodData>[
                    if (widget.showIncomes)
                      BarChartRodData(
                        toY: ingreso,
                        color: Colors.green,
                        width: 12,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    if (widget.showExpenses)
                      BarChartRodData(
                        toY: gasto,
                        color: Colors.red,
                        width: 12,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                  ];
                  return BarChartGroupData(
                    x: index,
                    barRods: rods,
                    showingTooltipIndicators: _touchedIndex == index
                        ? List.generate(rods.length, (i) => i)
                        : [],
                  );
                }),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
        if (widget.showLineChart) ...[
          const SizedBox(height: 32),
          Text(
            t.accumulatedBalanceTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        Theme.of(context).colorScheme.inverseSurface,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final flSpot = barSpot;
                        final index = flSpot.x.toInt();
                        if (index < 0 || index >= fechas.length) return null;
                        final fecha = fechas[index];
                        return LineTooltipItem(
                          '${fecha.day}/${fecha.month}\n${widget.currencySymbol}${convert(flSpot.y).toStringAsFixed(2)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= fechas.length) {
                          return const SizedBox.shrink();
                        }
                        if (fechas.length > 7 &&
                            index % (fechas.length ~/ 5) != 0) {
                          return const SizedBox.shrink();
                        }
                        final fecha = fechas[index];
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            '${fecha.day}/${fecha.month}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${widget.currencySymbol}${convert(value).toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(fechas.length, (index) {
                      // Calcular balance acumulado hasta esta fecha
                      double acumulado = 0;
                      for (int i = 0; i <= index; i++) {
                        final f = fechas[i];
                        acumulado +=
                            (widget.ingresosPorFecha[f] ?? 0) -
                            (widget.gastosPorFecha[f] ?? 0);
                      }
                      return FlSpot(index.toDouble(), acumulado);
                    }),
                    isCurved: true,
                    color: Theme.of(context).primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Theme.of(context).primaryColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.3),
                          Theme.of(context).primaryColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TechniciansChart extends StatelessWidget {
  final Map<String, double> ingresosPorTecnico;
  final UsuariosViewModel usuariosVM;
  final String currencySymbol;
  final double exchangeRate;

  const _TechniciansChart({
    required this.ingresosPorTecnico,
    required this.usuariosVM,
    this.currencySymbol = 'L',
    this.exchangeRate = 1.0,
  });

  String _resolveName(String id) {
    if (id == 'Sin Asignar' || id.isEmpty) return 'Sin Asignar';
    try {
      final user = usuariosVM.usuarios.firstWhere((u) => u.id == id);
      return user.nombre;
    } catch (_) {
      return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ingresosPorTecnico.isEmpty) {
      return const Center(child: Text('No hay datos', style: TextStyle(color: Colors.grey)));
    }

    final entries = ingresosPorTecnico.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      Colors.deepPurple,
      Colors.purple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue
    ];

    double total = ingresosPorTecnico.values.fold(0.0, (sum, val) => sum + val.toDouble());

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 35,
                sections: List.generate(entries.length, (index) {
                  final monto = entries[index].value.toDouble();
                  final percentage = total > 0 ? (monto / total) * 100 : 0.0;
                  
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: monto,
                    title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                    radius: 40,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                    ),
                    badgeWidget: null,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final monto = entries[index].value.toDouble();
                final itemName = _resolveName(entries[index].key);
                final percentage = total > 0 ? (monto / total) * 100 : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors[index % colors.length],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$itemName\nL ${(monto * exchangeRate).toStringAsFixed(2)} (${percentage.toStringAsFixed(0)}%)',
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
