import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/job.dart';
import '../../models/gasto.dart';
import '../../l10n/app_localizations.dart';

/// Genera un archivo Excel (.xlsx) con los datos de balance.
///
/// El Excel incluye múltiples hojas:
/// - Resumen: Totales con formato
/// - Ingresos: Tabla detallada de trabajos completados
/// - Gastos: Tabla detallada de gastos
class ExcelExporter {
  /// Genera el archivo Excel a partir de los datos proporcionados.
  ///
  /// [datos] debe contener:
  /// - resumen: Map con ingresos, gastos, balance
  /// - trabajos: `List<Trabajo>` de trabajos completados
  /// - gastos: `List<Gasto>`
  /// - periodo: Map con inicio y fin (DateTime)
  ///
  /// [nombreRango] es el nombre del rango seleccionado (ej: "Este Mes")
  /// [locale] es el locale actual para localizar el contenido
  ///
  /// Retorna el Excel como Uint8List
  Uint8List generar(
    Map<String, dynamic> datos,
    String nombreRango,
    Locale locale,
  ) {
    // Crear un contexto de localización mock para obtener las traducciones
    // Nota: En un escenario real, pasaríamos AppLocalizations directamente
    final l10n = lookupAppLocalizations(locale);
    final excel = Excel.createExcel();
    final formatoFecha = DateFormat('dd/MM/yyyy');
    final exchangeRate = (datos['exchangeRate'] as num?)?.toDouble() ?? 1.0;
    final currencySymbol = (datos['currencySymbol'] as String?) ?? '\$';

    // Extraer datos
    final resumen = datos['resumen'] as Map<String, dynamic>;
    final trabajos = datos['trabajos'] as List<Trabajo>;
    final trabajosTodos =
        (datos['trabajosTodos'] as List<Trabajo>?) ?? trabajos;
    final gastos = datos['gastos'] as List<Gasto>;
    final periodo = datos['periodo'] as Map<String, dynamic>;
    final fechaInicio = periodo['inicio'] as DateTime?;
    final fechaFin = periodo['fin'] as DateTime?;

    final totalIngresos =
        ((resumen['ingresos'] as num?)?.toDouble() ?? 0.0) * exchangeRate;
    final totalGastos =
        ((resumen['gastos'] as num?)?.toDouble() ?? 0.0) * exchangeRate;
    final balance =
        ((resumen['balance'] as num?)?.toDouble() ?? 0.0) * exchangeRate;

    final trabajoTituloPorId = <String, String>{
      for (final t in trabajosTodos) t.id: t.titulo,
    };

    final clientesById =
        (datos['clientesById'] as Map?)?.cast<String, String>() ?? const {};
    final tiposGastoById =
        (datos['tiposGastoById'] as Map?)?.cast<String, String>() ?? const {};

    // Ordenar por fecha (de menor a mayor) para exportación.
    final trabajosSorted = List<Trabajo>.from(trabajos)
      ..sort((a, b) {
        final c = a.fechaFin.compareTo(b.fechaFin);
        if (c != 0) return c;
        return a.fechaInicio.compareTo(b.fechaInicio);
      });
    final gastosSorted = List<Gasto>.from(gastos)
      ..sort((a, b) => a.fechaGasto.compareTo(b.fechaGasto));

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#E5E7EB'),
      verticalAlign: VerticalAlign.Center,
    );
    final titleStyle = CellStyle(bold: true, fontSize: 16);
    final subtitleStyle = CellStyle(fontColorHex: ExcelColor.fromHexString('#6B7280'));
    final dateStyle = CellStyle(
      numberFormat: NumFormat.custom(formatCode: 'dd/mm/yyyy'),
    );
    final currencyStyle = CellStyle(
      numberFormat: NumFormat.custom(
        formatCode: currencySymbol == 'L' ? r'"L"#,##0.00' : r'"$"#,##0.00',
      ),
      horizontalAlign: HorizontalAlign.Right,
    );
    final wrapStyle = CellStyle(textWrapping: TextWrapping.WrapText);
    final zebraFill = ExcelColor.fromHexString('#F9FAFB');

    // === HOJA DE RESUMEN ===
    final sheetResumen = excel[l10n.exportSummarySheet];
    // Asegurar que Excel abra por defecto la hoja de Resumen (evita archivo "vacío"
    // cuando se eliminó Sheet1 y el defaultSheet queda apuntando a una hoja inexistente).
    excel.setDefaultSheet(l10n.exportSummarySheet);
    sheetResumen.setColumnWidth(0, 28);
    sheetResumen.setColumnWidth(1, 18);

    // Título
    sheetResumen.cell(CellIndex.indexByString('A1')).value = TextCellValue(
      l10n.exportBalanceReport,
    );
    sheetResumen.cell(CellIndex.indexByString('A1')).cellStyle = titleStyle;

    // Período
    sheetResumen.cell(CellIndex.indexByString('A2')).value = TextCellValue(
      '${l10n.exportPeriod}: $nombreRango',
    );
    if (fechaInicio != null && fechaFin != null) {
      sheetResumen.cell(CellIndex.indexByString('A3')).value = TextCellValue(
        '${formatoFecha.format(fechaInicio)} - ${formatoFecha.format(fechaFin)}',
      );
      sheetResumen.cell(CellIndex.indexByString('A3')).cellStyle = subtitleStyle;
    }
    sheetResumen.cell(CellIndex.indexByString('A4')).value = TextCellValue(
      'Fecha de generación: ${formatoFecha.format(DateTime.now())}',
    );
    sheetResumen.cell(CellIndex.indexByString('A4')).cellStyle = subtitleStyle;

    // Encabezados de tabla
    sheetResumen.cell(CellIndex.indexByString('A5')).value = TextCellValue(
      l10n.exportConcept,
    );
    sheetResumen.cell(CellIndex.indexByString('B5')).value = TextCellValue(
      l10n.exportAmount,
    );
    sheetResumen.cell(CellIndex.indexByString('A5')).cellStyle = headerStyle;
    sheetResumen.cell(CellIndex.indexByString('B5')).cellStyle = headerStyle;

    // Datos de resumen
    sheetResumen.cell(CellIndex.indexByString('A6')).value = TextCellValue(
      l10n.exportTotalIncome,
    );
    sheetResumen.cell(CellIndex.indexByString('B6')).value = DoubleCellValue(
      totalIngresos,
    );
    sheetResumen.cell(CellIndex.indexByString('A6')).cellStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'),
    );
    sheetResumen.cell(CellIndex.indexByString('B6')).cellStyle = currencyStyle
        .copyWith(backgroundColorHexVal: ExcelColor.fromHexString('#E8F5E9'));

    sheetResumen.cell(CellIndex.indexByString('A7')).value = TextCellValue(
      l10n.exportTotalExpenses,
    );
    sheetResumen.cell(CellIndex.indexByString('B7')).value = DoubleCellValue(
      totalGastos,
    );
    sheetResumen.cell(CellIndex.indexByString('A7')).cellStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#FFEBEE'),
    );
    sheetResumen.cell(CellIndex.indexByString('B7')).cellStyle = currencyStyle
        .copyWith(backgroundColorHexVal: ExcelColor.fromHexString('#FFEBEE'));

    sheetResumen.cell(CellIndex.indexByString('A8')).value = TextCellValue(
      l10n.exportNetBalance,
    );
    sheetResumen.cell(CellIndex.indexByString('B8')).value = DoubleCellValue(
      balance,
    );
    sheetResumen.cell(CellIndex.indexByString('A8')).cellStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'),
    );
    sheetResumen.cell(CellIndex.indexByString('B8')).cellStyle = currencyStyle
        .copyWith(
          boldVal: true,
          backgroundColorHexVal: ExcelColor.fromHexString('#E3F2FD'),
        );

    // === HOJA DE INGRESOS ===
    final sheetIngresos = excel[l10n.exportIncomeSheet];
    sheetIngresos.setColumnWidth(0, 12);
    sheetIngresos.setColumnWidth(1, 12);
    sheetIngresos.setColumnWidth(2, 24);
    sheetIngresos.setColumnWidth(3, 30);
    sheetIngresos.setColumnWidth(4, 14);

    // Encabezados
    sheetIngresos.cell(CellIndex.indexByString('A1')).value = TextCellValue(
      l10n.exportStartDate,
    );
    sheetIngresos.cell(CellIndex.indexByString('B1')).value = TextCellValue(
      l10n.exportEndDate,
    );
    sheetIngresos.cell(CellIndex.indexByString('C1')).value = TextCellValue(
      l10n.exportClient,
    );
    sheetIngresos.cell(CellIndex.indexByString('D1')).value = TextCellValue(
      l10n.exportJob,
    );
    sheetIngresos.cell(CellIndex.indexByString('E1')).value = TextCellValue(
      l10n.exportAmount,
    );

    for (var col in ['A1', 'B1', 'C1', 'D1', 'E1']) {
      sheetIngresos.cell(CellIndex.indexByString(col)).cellStyle = headerStyle;
    }

    // Datos de ingresos
    int rowIngresos = 2;
    double totalIngresosDetalle = 0.0;
    for (final trabajo in trabajosSorted) {
      final bg = rowIngresos.isEven ? zebraFill : ExcelColor.none;

      final clientName =
          (trabajo.clienteId.isNotEmpty ? clientesById[trabajo.clienteId] : null) ??
          (trabajo.cliente.trim().isNotEmpty ? trabajo.cliente.trim() : null) ??
          'N/A';
      final jobTitle =
          trabajo.titulo.trim().isNotEmpty ? trabajo.titulo.trim() : 'N/A';
      final monto = (trabajo.costo * exchangeRate);
      totalIngresosDetalle += monto;

      final cellA = sheetIngresos.cell(CellIndex.indexByString('A$rowIngresos'));
      cellA.value = DateCellValue.fromDateTime(trabajo.fechaInicio);
      cellA.cellStyle = dateStyle.copyWith(backgroundColorHexVal: bg);

      final cellB = sheetIngresos.cell(CellIndex.indexByString('B$rowIngresos'));
      cellB.value = DateCellValue.fromDateTime(trabajo.fechaFin);
      cellB.cellStyle = dateStyle.copyWith(backgroundColorHexVal: bg);

      final cellC = sheetIngresos.cell(CellIndex.indexByString('C$rowIngresos'));
      cellC.value = TextCellValue(clientName);
      cellC.cellStyle = CellStyle(backgroundColorHex: bg);

      final cellD = sheetIngresos.cell(CellIndex.indexByString('D$rowIngresos'));
      cellD.value = TextCellValue(jobTitle);
      cellD.cellStyle = wrapStyle.copyWith(backgroundColorHexVal: bg);

      final cellE = sheetIngresos.cell(CellIndex.indexByString('E$rowIngresos'));
      cellE.value = DoubleCellValue(monto);
      cellE.cellStyle = currencyStyle.copyWith(backgroundColorHexVal: bg);
      rowIngresos++;
    }

    if (trabajosSorted.isEmpty) {
      sheetIngresos.cell(CellIndex.indexByString('A2')).value = TextCellValue(
        l10n.exportNoIncomeMessage,
      );
    } else {
      final totalRow = rowIngresos;
      sheetIngresos.cell(CellIndex.indexByString('D$totalRow')).value =
          TextCellValue('TOTAL');
      sheetIngresos.cell(CellIndex.indexByString('D$totalRow')).cellStyle =
          headerStyle;
      sheetIngresos.cell(CellIndex.indexByString('E$totalRow')).value =
          DoubleCellValue(double.parse(totalIngresosDetalle.toStringAsFixed(2)));
      sheetIngresos.cell(CellIndex.indexByString('E$totalRow')).cellStyle =
          currencyStyle.copyWith(
            boldVal: true,
            backgroundColorHexVal: ExcelColor.fromHexString('#E5E7EB'),
          );
    }

    // === HOJA DE GASTOS ===
    final sheetGastos = excel[l10n.exportExpensesSheet];
    sheetGastos.setColumnWidth(0, 12);
    sheetGastos.setColumnWidth(1, 26);
    sheetGastos.setColumnWidth(2, 40);
    sheetGastos.setColumnWidth(3, 14);

    // Encabezados
    sheetGastos.cell(CellIndex.indexByString('A1')).value = TextCellValue(
      l10n.exportDate,
    );
    sheetGastos.cell(CellIndex.indexByString('B1')).value = TextCellValue(
      l10n.exportJob,
    );
    sheetGastos.cell(CellIndex.indexByString('C1')).value = TextCellValue(
      l10n.exportDescription,
    );
    sheetGastos.cell(CellIndex.indexByString('D1')).value = TextCellValue(
      l10n.exportAmount,
    );

    for (var col in ['A1', 'B1', 'C1', 'D1']) {
      sheetGastos.cell(CellIndex.indexByString(col)).cellStyle = headerStyle;
    }

    // Datos de gastos
    int rowGastos = 2;
    double totalGastosDetalle = 0.0;
    for (final gasto in gastosSorted) {
      final bg = rowGastos.isEven ? zebraFill : ExcelColor.none;
      final tituloTrabajo =
          (gasto.trabajoAsignadoId.isNotEmpty
                  ? trabajoTituloPorId[gasto.trabajoAsignadoId]
                  : null) ??
              (gasto.trabajoId.isNotEmpty
                  ? trabajoTituloPorId[gasto.trabajoId]
                  : null) ??
              'N/A';

      final tipoGastoNombre = gasto.idTipoGasto.isNotEmpty
          ? (tiposGastoById[gasto.idTipoGasto] ?? '')
          : '';

      final cellA = sheetGastos.cell(CellIndex.indexByString('A$rowGastos'));
      cellA.value = DateCellValue.fromDateTime(gasto.fechaGasto);
      cellA.cellStyle = dateStyle.copyWith(backgroundColorHexVal: bg);

      final cellB = sheetGastos.cell(CellIndex.indexByString('B$rowGastos'));
      cellB.value = TextCellValue(
        tituloTrabajo.trim().isEmpty ? 'N/A' : tituloTrabajo,
      );
      cellB.cellStyle = wrapStyle.copyWith(backgroundColorHexVal: bg);

      final cellC = sheetGastos.cell(CellIndex.indexByString('C$rowGastos'));
      final desc = gasto.descripcion.trim().isNotEmpty
          ? gasto.descripcion.trim()
          : (tipoGastoNombre.trim().isNotEmpty ? tipoGastoNombre : 'N/A');
      cellC.value = TextCellValue(desc);
      cellC.cellStyle = wrapStyle.copyWith(backgroundColorHexVal: bg);

      final cellD = sheetGastos.cell(CellIndex.indexByString('D$rowGastos'));
      final monto = gasto.monto * exchangeRate;
      totalGastosDetalle += monto;
      cellD.value = DoubleCellValue(monto);
      cellD.cellStyle = currencyStyle.copyWith(backgroundColorHexVal: bg);
      rowGastos++;
    }

    if (gastosSorted.isEmpty) {
      sheetGastos.cell(CellIndex.indexByString('A2')).value = TextCellValue(
        l10n.exportNoExpensesMessage,
      );
    } else {
      final totalRow = rowGastos;
      sheetGastos.cell(CellIndex.indexByString('C$totalRow')).value =
          TextCellValue('TOTAL');
      sheetGastos.cell(CellIndex.indexByString('C$totalRow')).cellStyle =
          headerStyle;
      sheetGastos.cell(CellIndex.indexByString('D$totalRow')).value =
          DoubleCellValue(double.parse(totalGastosDetalle.toStringAsFixed(2)));
      sheetGastos.cell(CellIndex.indexByString('D$totalRow')).cellStyle =
          currencyStyle.copyWith(
            boldVal: true,
            backgroundColorHexVal: ExcelColor.fromHexString('#E5E7EB'),
          );
    }

    // Eliminar hoja por defecto si quedó creada (después de setDefaultSheet).
    try {
      if (excel.sheets.keys.contains('Sheet1')) {
        excel.delete('Sheet1');
      }
    } catch (_) {}

    // Guardar y retornar
    final encoded = excel.encode();
    return Uint8List.fromList(encoded ?? <int>[]);
  }
}
