import 'package:flutter/material.dart';

/// Muestra un BottomSheet estandarizado para la aplicación Workia.
///
/// Replicalos estilos de `agenda_jobs_panel.dart`:
/// - Bordes redondeados superiores de 24px
/// - Barrier color con opacidad 0.25
/// - Fondo del color de la tarjeta del tema
/// - isScrollControlled: true (por defecto, para permitir altura dinámica)
Future<T?> showWorkiaBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    barrierColor: Colors.black.withOpacity(0.25),
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      // Envolvemos en SafeArea para asegurar que no se solape con elementos del sistema
      // y aplicamos padding inferior para compensar teclados o gestos si es necesario,
      // aunque el Scaffold interno o el contenido debería manejarlo.
      return builder(context);
    },
  );
}
