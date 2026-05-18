import 'package:flutter/material.dart';
import '../services/export_service.dart';
import 'package:workia/l10n/app_localizations.dart';

/// Diálogo para seleccionar el formato de exportación.
///
/// Muestra un BottomSheet con las opciones de formato disponibles:
/// - CSV: Simple, se abre en Excel
/// - PDF: Profesional con gráficas
/// - Excel: Completo y editable
class ExportFormatDialog extends StatelessWidget {
  const ExportFormatDialog({super.key});

  /// Muestra el diálogo y retorna el formato seleccionado.
  ///
  /// Retorna null si el usuario cancela la selección.
  static Future<FormatoExportacion?> show(BuildContext context) {
    return showModalBottomSheet<FormatoExportacion>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ExportFormatDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.selectFormatTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.selectFormatMessage,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Opción CSV
          _FormatOption(
            icon: Icons.description,
            iconColor: Colors.green,
            title: AppLocalizations.of(context)!.csvFormatLabel,
            description: AppLocalizations.of(context)!.csvDescription,
            onTap: () => Navigator.pop(context, FormatoExportacion.csv),
          ),
          const Divider(),

          // Opción PDF
          _FormatOption(
            icon: Icons.picture_as_pdf,
            iconColor: Colors.red,
            title: AppLocalizations.of(context)!.pdfFormatLabel,
            description: AppLocalizations.of(context)!.pdfDescription,
            onTap: () => Navigator.pop(context, FormatoExportacion.pdf),
          ),
          const Divider(),

          // Opción Excel
          _FormatOption(
            icon: Icons.table_chart,
            iconColor: Theme.of(context).primaryColor,
            title: AppLocalizations.of(context)!.excelFormatLabel,
            description: AppLocalizations.of(context)!.excelDescription,
            onTap: () => Navigator.pop(context, FormatoExportacion.excel),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Widget para mostrar una opción de formato.
class _FormatOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _FormatOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
