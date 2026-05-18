import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workia/features/balance/presentation/viewmodels/balance_viewmodel.dart';
import 'package:workia/features/balance/presentation/widgets/balance_charts.dart';
import 'package:workia/features/balance/presentation/widgets/balance_summary_card.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/widgets/currency_text.dart';
import 'package:workia/presentation/viewmodels/empresa_viewmodel.dart';
import 'package:workia/services/export_service.dart';
import 'package:workia/features/settings/presentation/views/user_settings_screen.dart';
import 'package:workia/widgets/export_format_dialog.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({
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
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  String _selectedRange = '';
  List<String> _ranges = [];
  final ExportService _exportService = ExportService();
  bool _exportando = false;
  Set<String> _selectedChart = {'summary'};
  int _pieTouchedIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Cargar empresa para tener la tasa de cambio actual (y reflejar cambios
      // cuando el admin borra/actualiza la tasa).
      await context.read<EmpresaViewModel>().cargarEmpresa(widget.empresaId);

      final t = AppLocalizations.of(context)!;
      _ranges = [
        t.thisMonthOption,
        t.lastMonthOption,
        t.lastYearOption,
        t.allLabel,
      ];

      if (DateTime.now().day <= 7) {
        _selectedRange = t.lastMonthOption;
      } else {
        _selectedRange = t.thisMonthOption;
      }

      _runCalculo();
    });
  }

  void _runCalculo() {
    if (_ranges.isEmpty) return;
    final t = AppLocalizations.of(context)!;
    final now = DateTime.now();
    DateTime inicio;
    DateTime fin;

    if (_selectedRange == t.thisMonthOption) {
      inicio = DateTime(now.year, now.month, 1);
      fin = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
    } else if (_selectedRange == t.lastMonthOption) {
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      inicio = DateTime(lastMonth.year, lastMonth.month, 1);
      fin = DateTime(lastMonth.year, lastMonth.month + 1, 0, 23, 59, 59, 999);
    } else if (_selectedRange == t.lastYearOption) {
      inicio = DateTime(now.year, 1, 1);
      fin = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    } else {
      inicio = DateTime(2000, 1, 1);
      fin = DateTime(2100, 12, 31, 23, 59, 59, 999);
    }

    final vm = context.read<BalanceViewModel>();
    vm.calcular(inicio, fin, widget.empresaId);
  }

  String _initials() {
    final parts = widget.userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> _exportarDatos() async {
    final formato = await ExportFormatDialog.show(context);
    if (formato == null || !mounted) return;

    setState(() {
      _exportando = true;
    });

    final t = AppLocalizations.of(context)!;

    try {
      final vm = context.read<BalanceViewModel>();
      final datos = vm.obtenerDatosParaExportar();
      final locale = Localizations.localeOf(context);

      // Moneda: si hay tasa de cambio, exportar en moneda local (L); si no, USD.
      final empresaVM = context.read<EmpresaViewModel>();
      final tasa = empresaVM.empresa?.tasaCambio;
      final isSpanish = locale.languageCode == 'es';
      final hasExchange = isSpanish && tasa != null && tasa > 0;
      datos['exchangeRate'] = hasExchange ? tasa : 1.0;
      datos['currencySymbol'] = hasExchange ? 'L' : '\$';

      final rutaArchivo = await _exportService.exportar(
        formato,
        datos,
        _selectedRange,
        locale,
      );

      if (!mounted) return;

      setState(() {
        _exportando = false;
      });

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
    final vm = context.watch<BalanceViewModel>();
    final incomes = vm.ingresos;
    final expenses = vm.gastos;
    final balance = vm.balance;
    final margin = vm.margen;
    final t = AppLocalizations.of(context)!;

    final empresaVM = context.watch<EmpresaViewModel>();
    final tasa = empresaVM.empresa?.tasaCambio;
    final locale = Localizations.localeOf(context);
    final isSpanish = locale.languageCode == 'es';
    final hasExchange = isSpanish && tasa != null && tasa > 0;
    final currencySymbol = hasExchange ? 'L' : '\$';
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScaleFactorOf(context);
    final kpiAspectRatio =
        (screenWidth < 360 || textScale > 1.1) ? 1.6 : 2.0;

    String formatCurrency(double amount) {
      double displayAmount = amount;
      if (hasExchange) {
        displayAmount = amount * tasa;
      }
      return '$currencySymbol${displayAmount.toStringAsFixed(2)}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.balanceTitle),
        actions: [
          IconButton(
            icon: _exportando
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : const Icon(Icons.download),
            onPressed: _exportando ? null : _exportarDatos,
            tooltip: 'Exportar datos',
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserSettingsScreen(
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
      body: vm.cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<String>(
                    value: _selectedRange,
                    items: _ranges
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRange = value;
                        });
                        _runCalculo();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: kpiAspectRatio,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      BalanceSummaryCard(
                        label: t.incomesLabel,
                        value: formatCurrency(incomes),
                        color: Theme.of(context).colorScheme.tertiary,
                        icon: Icons.arrow_upward,
                      ),
                      BalanceSummaryCard(
                        label: t.expensesLabel,
                        value: formatCurrency(expenses),
                        color: Theme.of(context).colorScheme.error,
                        icon: Icons.arrow_downward,
                      ),
                      BalanceSummaryCard(
                        label: t.netBalanceLabel,
                        value: formatCurrency(balance),
                        color: Theme.of(context).colorScheme.primary,
                        icon: Icons.account_balance_wallet,
                      ),
                      BalanceSummaryCard(
                        label: t.marginLabel,
                        value: '${margin.toStringAsFixed(1)}%',
                        color: Theme.of(context).colorScheme.secondary,
                        icon: Icons.percent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (incomes > 0 || expenses > 0) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      t.financialEvolutionTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'summary',
                            label: Text(t.chartSummaryLabel),
                            icon: const Icon(Icons.pie_chart),
                          ),
                          ButtonSegment(
                            value: 'daily',
                            label: Text(t.chartDailyLabel),
                            icon: const Icon(Icons.bar_chart),
                          ),
                          ButtonSegment(
                            value: 'cumulative',
                            label: Text(t.chartCumulativeLabel),
                            icon: const Icon(Icons.show_chart),
                          ),
                        ],
                        selected: _selectedChart,
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _selectedChart = newSelection;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_selectedChart.contains('summary'))
                      SizedBox(
                        height: 300,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback:
                                  (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection ==
                                              null) {
                                        _pieTouchedIndex = -1;
                                        return;
                                      }
                                      _pieTouchedIndex = pieTouchResponse
                                          .touchedSection!
                                          .touchedSectionIndex;
                                    });
                                  },
                            ),
                            sections: [
                              PieChartSectionData(
                                color: Colors.green,
                                value: incomes,
                                title: incomes > 0
                                    ? '${((incomes / (incomes + expenses)) * 100).toStringAsFixed(0)}%'
                                    : '',
                                radius: _pieTouchedIndex == 0 ? 110 : 100,
                                titleStyle: TextStyle(
                                  fontSize: _pieTouchedIndex == 0 ? 18 : 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                badgeWidget: _pieTouchedIndex == 0
                                    ? Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: CurrencyText(
                                          incomes,
                                          prefix: '${t.incomesLabel}\n',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    : null,
                                badgePositionPercentageOffset: 1.3,
                              ),
                              PieChartSectionData(
                                color: Colors.red,
                                value: expenses,
                                title: expenses > 0
                                    ? '${((expenses / (incomes + expenses)) * 100).toStringAsFixed(0)}%'
                                    : '',
                                radius: _pieTouchedIndex == 1 ? 110 : 100,
                                titleStyle: TextStyle(
                                  fontSize: _pieTouchedIndex == 1 ? 18 : 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                badgeWidget: _pieTouchedIndex == 1
                                    ? Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: CurrencyText(
                                          expenses,
                                          prefix: '${t.expensesLabel}\n',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    : null,
                                badgePositionPercentageOffset: 1.3,
                              ),
                            ],
                            sectionsSpace: 4,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                    if (_selectedChart.contains('daily'))
                      BalanceCharts(
                        ingresosPorFecha: vm.ingresosPorFecha,
                        gastosPorFecha: vm.gastosPorFecha,
                        showBarChart: true,
                        showLineChart: false,
                        exchangeRate: hasExchange ? tasa : null,
                        currencySymbol: currencySymbol,
                      ),
                    if (_selectedChart.contains('cumulative'))
                      BalanceCharts(
                        ingresosPorFecha: vm.ingresosPorFecha,
                        gastosPorFecha: vm.gastosPorFecha,
                        showBarChart: false,
                        showLineChart: true,
                        exchangeRate: hasExchange ? tasa : null,
                        currencySymbol: currencySymbol,
                      ),
                  ] else
                    Text(
                      t.noDataMessage,
                      style: const TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
    );
  }
}
