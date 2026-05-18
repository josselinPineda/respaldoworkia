import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/job.dart';
import '../../models/gasto.dart';
import '../../l10n/app_localizations.dart';

/// Genera un archivo CSV con los datos de balance.
///
/// El CSV incluye:
/// - Encabezado con título y período
/// - Sección de resumen (ingresos, gastos, balance)
/// - Detalle de ingresos (trabajos completados)
/// - Detalle de gastos
class CsvExporter {
  /// Genera el contenido CSV a partir de los datos proporcionados.
  ///
  /// [datos] debe contener:
  /// - resumen: Map con ingresos, gastos, balance
  /// - trabajos: List<Trabajo> de trabajos completados
  /// - gastos: List<Gasto>
  /// - periodo: Map con inicio y fin (DateTime)
  ///
  /// [nombreRango] es el nombre del rango seleccionado (ej: "Este Mes")
  /// [locale] es el locale actual para localizar el contenido
  String generar(
    Map<String, dynamic> datos,
    String nombreRango,
    Locale locale,
  ) {
    final l10n = lookupAppLocalizations(locale);
    final buffer = StringBuffer();
    final formatoFecha = DateFormat('dd/MM/yyyy');
    final exchangeRate = (datos['exchangeRate'] as num?)?.toDouble() ?? 1.0;
    final currencySymbol = (datos['currencySymbol'] as String?) ?? '\$';
    final formatoMoneda = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final _csvDelimiter = locale.languageCode == 'es' ? ';' : ',';

    // Extraer datos
    final resumen = datos['resumen'] as Map<String, dynamic>;
    final trabajos = datos['trabajos'] as List<Trabajo>;
    final trabajosTodos =
        (datos['trabajosTodos'] as List<Trabajo>?) ?? trabajos;
    final gastos = datos['gastos'] as List<Gasto>;
    final periodo = datos['periodo'] as Map<String, dynamic>;
    final fechaInicio = periodo['inicio'] as DateTime?;
    final fechaFin = periodo['fin'] as DateTime?;

    final trabajoTituloPorId = <String, String>{
      for (final t in trabajosTodos) t.id: t.titulo,
    };
    final clientesById =
        (datos['clientesById'] as Map?)?.cast<String, String>() ?? const {};
    final tiposGastoById =
        (datos['tiposGastoById'] as Map?)?.cast<String, String>() ?? const {};

    void writelnRow(List<String?> cells) {
      buffer.writeln(_csvRow(cells, delimiter: _csvDelimiter));
    }

    // Encabezado
    buffer.writeln('sep=$_csvDelimiter');
    // Asegurar 2 columnas para que Excel mantenga el formato visual.
    writelnRow([l10n.exportBalanceReport, '']);
    if (fechaInicio != null && fechaFin != null) {
      writelnRow([
        l10n.exportPeriod,
        '$nombreRango (${formatoFecha.format(fechaInicio)} - ${formatoFecha.format(fechaFin)})',
      ]);
    } else {
      writelnRow([l10n.exportPeriod, nombreRango]);
    }
    writelnRow(['Fecha de generación', formatoFecha.format(DateTime.now())]);
    buffer.writeln();

    // Resumen
    buffer.writeln(l10n.exportSummarySheet.toUpperCase());
    writelnRow([l10n.exportConcept, l10n.exportAmount]);
    writelnRow([
      l10n.exportTotalIncome,
      '$currencySymbol${formatoMoneda.format(((resumen['ingresos'] as num?)?.toDouble() ?? 0.0) * exchangeRate)}',
    ]);
    writelnRow([
      l10n.exportTotalExpenses,
      '$currencySymbol${formatoMoneda.format(((resumen['gastos'] as num?)?.toDouble() ?? 0.0) * exchangeRate)}',
    ]);
    writelnRow([
      l10n.exportNetBalance,
      '$currencySymbol${formatoMoneda.format(((resumen['balance'] as num?)?.toDouble() ?? 0.0) * exchangeRate)}',
    ]);
    buffer.writeln();

    // Ordenar por fecha (de menor a mayor) para exportación.
    final trabajosSorted = List<Trabajo>.from(trabajos)
      ..sort((a, b) {
        final c = a.fechaFin.compareTo(b.fechaFin);
        if (c != 0) return c;
        return a.fechaInicio.compareTo(b.fechaInicio);
      });
    final gastosSorted = List<Gasto>.from(gastos)
      ..sort((a, b) => a.fechaGasto.compareTo(b.fechaGasto));

    // Detalle de Ingresos
    buffer.writeln('${l10n.exportIncomeSheet.toUpperCase()}');
    writelnRow([
      l10n.exportStartDate,
      l10n.exportEndDate,
      l10n.exportClient,
      l10n.exportJob,
      l10n.exportAmount,
    ]);
    if (trabajosSorted.isEmpty) {
      writelnRow(['', '', '', l10n.exportNoIncomeMessage, '']);
    } else {
      for (final trabajo in trabajosSorted) {
        final clientName =
            (trabajo.clienteId.isNotEmpty ? clientesById[trabajo.clienteId] : null) ??
            (trabajo.cliente.trim().isNotEmpty ? trabajo.cliente.trim() : null) ??
            'N/A';
        final jobTitle =
            trabajo.titulo.trim().isNotEmpty ? trabajo.titulo.trim() : 'N/A';

        writelnRow([
          formatoFecha.format(trabajo.fechaInicio),
          formatoFecha.format(trabajo.fechaFin),
          clientName,
          jobTitle,
          '$currencySymbol${formatoMoneda.format(trabajo.costo * exchangeRate)}',
        ]);
      }
    }
    buffer.writeln();

    // Detalle de Gastos
    buffer.writeln('${l10n.exportExpensesSheet.toUpperCase()}');
    writelnRow([
      l10n.exportDate,
      l10n.exportJob,
      l10n.exportDescription,
      l10n.exportAmount,
    ]);
    if (gastosSorted.isEmpty) {
      writelnRow(['', '', l10n.exportNoExpensesMessage, '']);
    } else {
      for (final gasto in gastosSorted) {
        final tituloTrabajo =
            (gasto.trabajoAsignadoId.isNotEmpty
                    ? trabajoTituloPorId[gasto.trabajoAsignadoId]
                    : null) ??
            (gasto.trabajoId.isNotEmpty
                    ? trabajoTituloPorId[gasto.trabajoId]
                    : null) ??
            (gasto.idTipoGasto.isNotEmpty
                    ? tiposGastoById[gasto.idTipoGasto]
                    : null) ??
            'N/A';

        writelnRow([
          formatoFecha.format(gasto.fechaGasto),
          tituloTrabajo.trim().isEmpty ? 'N/A' : tituloTrabajo,
          gasto.descripcion.trim().isNotEmpty
              ? gasto.descripcion.trim()
              : ((gasto.idTipoGasto.isNotEmpty
                          ? tiposGastoById[gasto.idTipoGasto]
                          : null) ??
                      'N/A'),
          '$currencySymbol${formatoMoneda.format(gasto.monto * exchangeRate)}',
        ]);
      }
    }

    return buffer.toString();
  }

  String _csvRow(List<String?> cells, {required String delimiter}) {
    return cells.map((c) => _csvCell(c ?? '')).join(delimiter);
  }

  String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    // Para mantener consistencia y evitar problemas con separadores/saltos,
    // siempre citamos las celdas.
    return '"$escaped"';
  }
}
