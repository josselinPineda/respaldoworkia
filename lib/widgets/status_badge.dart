import 'package:flutter/material.dart';
import 'package:workia/l10n/app_localizations.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.showDropdownIcon = false,
  });

  final String status;
  final bool showDropdownIcon;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    Color backgroundColor;
    Color textColor;
    String label;

    final normalized = status.replaceAll('_', ' ').toLowerCase();

    switch (normalized) {
      case 'pendiente':
      case 'en espera':
      case 'on hold':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        label = t.jobStatusOnHold;
        break;
      case 'en progreso':
      case 'iniciado':
      case 'started':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        label = t.jobStatusStarted;
        break;
      case 'finalizado':
      case 'completo':
      case 'finished':
      case 'completed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = t.jobStatusFinished;
        break;
      case 'cerrado':
      case 'closed':
        backgroundColor = Colors.grey.shade300;
        textColor = Colors.grey.shade900;
        label = t.jobStatusClosed;
        break;
      case 'cancelado':
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        label = t.jobStatusCancelled;
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          if (showDropdownIcon) ...[
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: textColor),
          ],
        ],
      ),
    );
  }
}
