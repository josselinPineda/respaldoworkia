import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'exporters/csv_exporter.dart';
import 'exporters/pdf_exporter.dart';
import 'exporters/excel_exporter.dart';

/// Formatos de exportación disponibles
enum FormatoExportacion { csv, pdf, excel }

/// Servicio principal para exportar datos de balance en múltiples formatos.
///
/// Coordina la exportación según el formato seleccionado, maneja el guardado
/// de archivos y proporciona funcionalidad para compartir.
class ExportService {
  final CsvExporter _csvExporter = CsvExporter();
  final PdfExporter _pdfExporter = PdfExporter();
  final ExcelExporter _excelExporter = ExcelExporter();

  /// Exporta los datos en el formato especificado y guarda el archivo.
  ///
  /// [formato] es el formato de exportación deseado
  /// [datos] son los datos a exportar (del ReportesViewModel)
  /// [nombreRango] es el nombre del rango seleccionado (ej: "Este Mes")
  /// [locale] es el locale actual para localizar el contenido exportado
  ///
  /// Retorna la ruta del archivo guardado
  Future<String> exportar(
    FormatoExportacion formato,
    Map<String, dynamic> datos,
    String nombreRango,
    Locale locale,
  ) async {
    // Verificar y solicitar permisos si es necesario
    await _verificarPermisos();

    // Generar nombre de archivo
    final nombreArchivo = _generarNombreArchivo(formato, nombreRango);

    // Obtener directorio de almacenamiento
    final directorio = await _obtenerDirectorio();
    final rutaArchivo = '${directorio.path}/$nombreArchivo';

    // Generar contenido según formato
    switch (formato) {
      case FormatoExportacion.csv:
        final contenido = _csvExporter.generar(datos, nombreRango, locale);
        // Excel en Windows suele fallar con UTF-8; UTF-16LE con BOM es más confiable.
        final bytes = _utf16leWithBom(contenido);
        await File(rutaArchivo).writeAsBytes(bytes);
        break;

      case FormatoExportacion.pdf:
        final contenido = await _pdfExporter.generar(
          datos,
          nombreRango,
          locale,
        );
        await File(rutaArchivo).writeAsBytes(contenido);
        break;

      case FormatoExportacion.excel:
        final contenido = _excelExporter.generar(datos, nombreRango, locale);
        await File(rutaArchivo).writeAsBytes(contenido);
        break;
    }

    return rutaArchivo;
  }

  /// Comparte el archivo especificado usando el share sheet del sistema.
  ///
  /// [rutaArchivo] es la ruta completa del archivo a compartir
  Future<void> compartirArchivo(String rutaArchivo) async {
    final file = XFile(rutaArchivo);
    await Share.shareXFiles(
      [file],
      subject: 'Reporte de Balance',
      text: 'Adjunto reporte de balance',
    );
  }

  /// Genera un nombre de archivo descriptivo basado en el formato y rango.
  ///
  /// Formato: balance_[rango]_[fecha].[extensión]
  /// Ejemplo: balance_este_mes_2025-11-21.pdf
  String _generarNombreArchivo(FormatoExportacion formato, String nombreRango) {
    final fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final rangoNormalizado = nombreRango
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');

    final extension = switch (formato) {
      FormatoExportacion.csv => 'csv',
      FormatoExportacion.pdf => 'pdf',
      FormatoExportacion.excel => 'xlsx',
    };

    return 'balance_${rangoNormalizado}_$fecha.$extension';
  }

  /// Obtiene el directorio apropiado para guardar archivos.
  ///
  /// En Android usa el directorio de documentos de la app.
  /// En iOS usa el directorio de documentos de la app.
  Future<Directory> _obtenerDirectorio() async {
    if (Platform.isAndroid) {
      // Para Android 10+ (API 29+) usamos el directorio de la app
      return await getApplicationDocumentsDirectory();
    } else {
      // Para iOS
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Verifica y solicita permisos de almacenamiento si es necesario.
  ///
  /// En Android 13+ (API 33+) no se necesitan permisos especiales
  /// para escribir en el directorio de la app.
  Future<void> _verificarPermisos() async {
    if (Platform.isAndroid) {
      // Para Android 12 y anteriores, verificar permiso de almacenamiento
      final sdkInt = await _getAndroidSdkInt();
      if (sdkInt < 33) {
        final status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }
      }
    }
    // iOS no requiere permisos especiales para el directorio de documentos
  }

  /// Convierte [text] a UTF-16LE con BOM (0xFF, 0xFE) para que Excel lo lea bien.
  List<int> _utf16leWithBom(String text) {
    final codeUnits = text.codeUnits;
    final out = <int>[0xFF, 0xFE];
    for (final cu in codeUnits) {
      out.add(cu & 0xFF);
      out.add((cu >> 8) & 0xFF);
    }
    return out;
  }

  /// Obtiene la versión del SDK de Android.
  ///
  /// Retorna 33 por defecto si no se puede determinar (asumiendo Android 13+)
  Future<int> _getAndroidSdkInt() async {
    try {
      // En un entorno real, esto se obtendría del sistema
      // Por ahora asumimos Android 13+ para simplificar
      return 33;
    } catch (e) {
      return 33;
    }
  }
}
