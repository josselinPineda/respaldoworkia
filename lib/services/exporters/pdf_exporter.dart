import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../models/job.dart';
import '../../models/gasto.dart';
import '../../l10n/app_localizations.dart';

/// Genera un documento PDF profesional con los datos de balance.
///
/// El PDF incluye:
/// - Encabezado con título y período
/// - Tabla de resumen con totales
/// - Tablas detalladas de ingresos y gastos
/// - Pie de página con fecha de generación
class PdfExporter {
  /// Genera el documento PDF a partir de los datos proporcionados.
  ///
  /// [datos] debe contener:
  /// - resumen: Map con ingresos, gastos, balance
  /// - trabajos: List<Trabajo> de trabajos completados
  /// - gastos: List<Gasto>
  /// - periodo: Map con inicio y fin (DateTime)
  ///
  /// [nombreRango] es el nombre del rango seleccionado (ej: "Este Mes")
  /// [locale] es el locale actual para localizar el contenido
  ///
  /// Retorna el PDF como Uint8List
  Future<Uint8List> generar(
    Map<String, dynamic> datos,
    String nombreRango,
    Locale locale,
  ) async {
    final l10n = lookupAppLocalizations(locale);
    final pdf = pw.Document();
    final formatoFecha = DateFormat('dd/MM/yyyy');
    final exchangeRate = (datos['exchangeRate'] as num?)?.toDouble() ?? 1.0;
    final currencySymbol = (datos['currencySymbol'] as String?) ?? '\$';
    final formatoMoneda = NumberFormat.currency(symbol: '', decimalDigits: 2);

    // Extraer datos
    final resumen = datos['resumen'] as Map<String, dynamic>;
    final trabajos = datos['trabajos'] as List<Trabajo>;
    final trabajosTodos =
        (datos['trabajosTodos'] as List<Trabajo>?) ?? trabajos;
    final gastos = datos['gastos'] as List<Gasto>;
    final periodo = datos['periodo'] as Map<String, dynamic>;
    final fechaInicio = periodo['inicio'] as DateTime?;
    final fechaFin = periodo['fin'] as DateTime?;

    final clientesById =
        (datos['clientesById'] as Map?)?.cast<String, String>() ?? const {};
    final tiposGastoById =
        (datos['tiposGastoById'] as Map?)?.cast<String, String>() ?? const {};

    final trabajoTituloPorId = <String, String>{
      for (final t in trabajosTodos) t.id: t.titulo,
    };

    // Ordenar por fecha (de menor a mayor) para exportación.
    final trabajosSorted = List<Trabajo>.from(trabajos)
      ..sort((a, b) {
        final c = a.fechaFin.compareTo(b.fechaFin);
        if (c != 0) return c;
        return a.fechaInicio.compareTo(b.fechaInicio);
      });
    final gastosSorted = List<Gasto>.from(gastos)
      ..sort((a, b) => a.fechaGasto.compareTo(b.fechaGasto));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Encabezado
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  l10n.exportBalanceReport,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '${l10n.exportPeriod}: $nombreRango',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                if (fechaInicio != null && fechaFin != null)
                  pw.Text(
                    '${formatoFecha.format(fechaInicio)} - ${formatoFecha.format(fechaFin)}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                pw.SizedBox(height: 20),
              ],
            ),
          ),

          // Tabla de Resumen
          pw.Text(
            l10n.exportSummarySheet,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: [
              _buildTableRow(
                l10n.exportConcept,
                l10n.exportAmount,
                isHeader: true,
              ),
              _buildTableRow(
                l10n.exportTotalIncome,
                '$currencySymbol${formatoMoneda.format(((resumen['ingresos'] as num?)?.toDouble() ?? 0.0) * exchangeRate)}',
                color: PdfColors.green50,
              ),
              _buildTableRow(
                l10n.exportTotalExpenses,
                '$currencySymbol${formatoMoneda.format(((resumen['gastos'] as num?)?.toDouble() ?? 0.0) * exchangeRate)}',
                color: PdfColors.red50,
              ),
              _buildTableRow(
                l10n.exportNetBalance,
                '$currencySymbol${formatoMoneda.format(((resumen['balance'] as num?)?.toDouble() ?? 0.0) * exchangeRate)}',
                color: PdfColors.blue50,
                isBold: true,
              ),
            ],
          ),
          pw.SizedBox(height: 30),

          // Detalle de Ingresos
          pw.Text(
            l10n.exportIncomeSheet,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          if (trabajosSorted.isNotEmpty)
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(1.5),
              },
              children: [
                _buildTableRow5(
                  l10n.exportStartDate,
                  l10n.exportEndDate,
                  l10n.exportClient,
                  l10n.exportJob,
                  l10n.exportAmount,
                  isHeader: true,
                ),
                ...trabajosSorted.map(
                  (t) => _buildTableRow5(
                    formatoFecha.format(t.fechaInicio),
                    formatoFecha.format(t.fechaFin),
                    _displayText(
                      t.cliente.trim().isNotEmpty
                          ? t.cliente
                          : (t.clienteId.isNotEmpty
                                ? (clientesById[t.clienteId] ?? '')
                                : ''),
                      fallback: l10n.exportClient,
                    ),
                    _displayText(
                      t.titulo.trim().isNotEmpty
                          ? t.titulo
                          : (t.id.isNotEmpty ? t.id : ''),
                      fallback: l10n.exportJob,
                    ),
                    '$currencySymbol${formatoMoneda.format(t.costo * exchangeRate)}',
                  ),
                ),
              ],
            )
          else
            pw.Text(
              l10n.exportNoIncomeMessage,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          pw.SizedBox(height: 30),

          // Detalle de Gastos
          pw.Text(
            l10n.exportExpensesSheet,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          if (gastosSorted.isNotEmpty)
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(2.2),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                _buildTableRow4(
                  l10n.exportDate,
                  l10n.exportJob,
                  l10n.exportDescription,
                  l10n.exportAmount,
                  isHeader: true,
                ),
                ...gastosSorted.map(
                  (g) {
                    final tituloTrabajo =
                        (g.trabajoAsignadoId.isNotEmpty
                                ? trabajoTituloPorId[g.trabajoAsignadoId]
                                : null) ??
                        (g.trabajoId.isNotEmpty
                                ? trabajoTituloPorId[g.trabajoId]
                                : null) ??
                        '';

                    final tipoGastoNombre = g.idTipoGasto.isNotEmpty
                        ? (tiposGastoById[g.idTipoGasto] ?? '')
                        : '';

                    return _buildTableRow4(
                      formatoFecha.format(g.fechaGasto),
                      _displayText(
                        tituloTrabajo.trim().isNotEmpty ? tituloTrabajo : '',
                        fallback: 'Sin trabajo',
                      ),
                      _displayText(
                        g.descripcion.trim().isNotEmpty
                            ? g.descripcion
                            : tipoGastoNombre,
                        fallback: l10n.exportDescription,
                      ),
                      '$currencySymbol${formatoMoneda.format(g.monto * exchangeRate)}',
                    );
                  },
                ),
              ],
            )
          else
            pw.Text(
              l10n.exportNoExpensesMessage,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Generado el ${formatoFecha.format(DateTime.now())} - Página ${context.pageNumber}/${context.pagesCount}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  String _displayText(
    String value, {
    required String fallback,
  }) {
    final v = value.trim();
    if (v.isEmpty) return '($fallback)';
    return v;
  }

  /// Construye una fila de tabla con 2 columnas
  pw.TableRow _buildTableRow(
    String col1,
    String col2, {
    bool isHeader = false,
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.TableRow(
      decoration: color != null
          ? pw.BoxDecoration(color: color)
          : (isHeader
                ? const pw.BoxDecoration(color: PdfColors.grey300)
                : null),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            col1,
            style: pw.TextStyle(
              fontWeight: (isHeader || isBold)
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            col2,
            style: pw.TextStyle(
              fontWeight: (isHeader || isBold)
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  /// Construye una fila de tabla con 5 columnas
  pw.TableRow _buildTableRow5(
    String col1,
    String col2,
    String col3,
    String col4,
    String col5, {
    bool isHeader = false,
  }) {
    return pw.TableRow(
      decoration: isHeader
          ? const pw.BoxDecoration(color: PdfColors.grey300)
          : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            col1,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 10,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            col2,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 10,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            col3,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 10,
            ),
            maxLines: isHeader ? 1 : 2,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            col4,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 10,
            ),
            maxLines: isHeader ? 1 : 2,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            col5,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  /// Construye una fila de tabla con 3 columnas
  pw.TableRow _buildTableRow3(
    String col1,
    String col2,
    String col3, {
    bool isHeader = false,
  }) {
    return pw.TableRow(
      decoration: isHeader
          ? const pw.BoxDecoration(color: PdfColors.grey300)
          : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            col1,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 10,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            col2,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 10,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            col3,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  /// Construye una fila de tabla con 4 columnas
  pw.TableRow _buildTableRow4(
    String col1,
    String col2,
    String col3,
    String col4, {
    bool isHeader = false,
  }) {
    return pw.TableRow(
      decoration: isHeader
          ? const pw.BoxDecoration(color: PdfColors.grey300)
          : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            col1,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 10,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            col2,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 10,
            ),
            maxLines: isHeader ? 1 : 2,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            col3,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 10,
            ),
            maxLines: isHeader ? 1 : 2,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            col4,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}
