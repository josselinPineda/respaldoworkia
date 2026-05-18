import 'package:flutter/material.dart';
import 'package:workia/features/activities/domain/entities/actividad.dart';
import 'package:workia/l10n/app_localizations.dart';

class ActivityItem extends StatelessWidget {
  const ActivityItem({
    super.key,
    required this.actividad,
    this.showClient = true,
    this.clienteNombre,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final Actividad actividad;
  final bool showClient;
  final String? clienteNombre;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final fecha = actividad.fechaActividad;
    final material = actividad.materialesUsados;
    final notas = actividad.notas;
    final tecnicoNombre = actividad.tecnicoNombre.isNotEmpty
        ? actividad.tecnicoNombre
        : t.unknownTechnicianLabel;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${fecha.day}/${fecha.month}/${fecha.year}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Container con horas eliminado por solicitud del usuario
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit?.call();
                        } else if (value == 'delete') {
                          onDelete?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                const SizedBox(width: 8),
                                Text(t.editButton),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20),
                                const SizedBox(width: 8),
                                Text(t.deleteButton),
                              ],
                            ),
                          ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.more_vert, size: 20),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Technician Name
              Row(
                children: [
                  Icon(Icons.engineering, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    tecnicoNombre,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (showClient && clienteNombre != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.business, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      clienteNombre!,
                      style: TextStyle(
                        color: Colors.blueGrey.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              const Divider(height: 16),
              Text(
                actividad.descripcion.trim().isEmpty
                    ? t.noDescriptionLabel
                    : actividad.descripcion,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
              if (notas.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.yellow.shade100),
                  ),
                  child: Text(
                    '${t.notesPrefix}$notas',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.brown.shade700,
                    ),
                  ),
                ),
              ],
              if (material != null && material.nombre.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.blueGrey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${t.materialPrefix}${material.nombre} (${material.cantidad} x ${material.precioUnitario})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
