import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workia/features/activities/domain/entities/actividad.dart';
import 'package:workia/models/gasto.dart';
import 'package:workia/models/cliente.dart';
import 'package:workia/models/trabajo_asignado.dart';
import 'package:workia/features/activities/presentation/viewmodels/actividades_viewmodel.dart';
import 'package:workia/presentation/viewmodels/gastos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:workia/l10n/app_localizations.dart';

/// Diálogo reutilizable para registrar una actividad.
///
/// Permite ingresar descripción, horas, notas y materiales opcionales.
/// Si se ingresan materiales, se crea automáticamente un gasto asociado.
class ActivityDialog extends StatefulWidget {
  final String trabajoId;
  final String trabajoAsignadoId; // Puede estar vacío si se selecciona cliente
  final String clienteId; // Puede estar vacío si se selecciona cliente
  final String empresaId;
  final String userId;
  final String userName; // Para fallback si no se encuentra el usuario
  final List<Cliente>?
  availableClients; // Lista de clientes disponibles para seleccionar
  final List<TrabajoAsignado>? availableAssignments; // Asignaciones disponibles
  final Actividad? existingActivity; // Actividad existente para edición

  const ActivityDialog({
    super.key,
    required this.trabajoId,
    required this.trabajoAsignadoId,
    required this.clienteId,
    required this.empresaId,
    required this.userId,
    required this.userName,
    this.availableClients,
    this.availableAssignments,
    this.existingActivity,
  });

  @override
  State<ActivityDialog> createState() => _ActivityDialogState();
}

class _ActivityDialogState extends State<ActivityDialog> {
  late TextEditingController _descripcionCtrl;
  late TextEditingController _notasCtrl;
  late TextEditingController _materialNombreCtrl;
  late TextEditingController _materialCantidadCtrl;
  late TextEditingController _materialCostoCtrl;

  Cliente? _selectedCliente;
  bool _materialsExpanded = false;

  @override
  void initState() {
    super.initState();

    final activity = widget.existingActivity;

    if (activity != null) {
      _descripcionCtrl = TextEditingController(text: activity.descripcion);
      _notasCtrl = TextEditingController(text: activity.notas);
    } else {
      _descripcionCtrl = TextEditingController();
      _notasCtrl = TextEditingController();
    }

    // Initialize material controllers if materials exist
    _materialNombreCtrl = TextEditingController(
      text: activity?.materialesUsados?.nombre ?? '',
    );
    _materialCantidadCtrl = TextEditingController(
      text: activity?.materialesUsados?.cantidad.toString() ?? '',
    );
    _materialCostoCtrl = TextEditingController(
      text: activity?.materialesUsados?.precioUnitario.toString() ?? '',
    );

    if (activity?.materialesUsados != null) {
      _materialsExpanded = true;
    }

    // Inicializar cliente seleccionado
    if (widget.clienteId.isNotEmpty && widget.availableClients != null) {
      try {
        _selectedCliente = widget.availableClients!.firstWhere(
          (c) => c.id == widget.clienteId,
        );
      } catch (_) {}
    } else if (activity != null &&
        activity.clienteId.isNotEmpty &&
        widget.availableClients != null) {
      try {
        _selectedCliente = widget.availableClients!.firstWhere(
          (c) => c.id == activity.clienteId,
        );
      } catch (_) {}
    }

    // Cargar tipos de gasto para asegurar que estén disponibles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gastosVM = context.read<GastosViewModel>();
      if (gastosVM.tipos.isEmpty) {
        gastosVM.cargarTipos(widget.empresaId);
      }
    });
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _notasCtrl.dispose();
    _materialNombreCtrl.dispose();
    _materialCantidadCtrl.dispose();
    _materialCostoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showClientSelector =
        widget.availableClients != null && widget.availableClients!.isNotEmpty;

    final t = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.registerJobActivityTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Selector de cliente (si hay múltiples clientes disponibles)
                    if (showClientSelector) ...[
                      DropdownSearch<Cliente>(
                        items: (String? filter, LoadProps? loadProps) {
                          return widget.availableClients!;
                        },
                        itemAsString: (Cliente c) => c.nombre,
                        selectedItem: _selectedCliente,
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              labelText: t.searchClientLabel,
                            ),
                          ),
                        ),
                        decoratorProps: DropDownDecoratorProps(
                          decoration: InputDecoration(
                            labelText: '${t.clientLabel} *',
                          ),
                        ),
                        compareFn: (item, selectedItem) =>
                            item.id == selectedItem.id,
                        onChanged: (Cliente? data) {
                          setState(() {
                            _selectedCliente = data;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _descripcionCtrl,
                      decoration: InputDecoration(
                        labelText: t.activityDescriptionLabel,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notasCtrl,
                      decoration: InputDecoration(labelText: t.notesLabel),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    // Sección de materiales con diseño más limpio e integrado
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          leading: Icon(
                            Icons.construction_outlined,
                            color: _materialsExpanded
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).hintColor,
                          ),
                          title: Text(
                            t.materialsOptionalLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _materialsExpanded
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                            ),
                          ),
                          initiallyExpanded: _materialsExpanded,
                          onExpansionChanged: (bool expanded) {
                            setState(() {
                              _materialsExpanded = expanded;
                            });
                          },
                          children: [
                            const SizedBox(height: 12),
                            TextField(
                              controller: _materialNombreCtrl,
                              decoration: InputDecoration(
                                labelText: t.materialNameLabel,
                                isDense: true,
                                filled: true,
                                fillColor: Theme.of(context).canvasColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _materialCantidadCtrl,
                                    decoration: InputDecoration(
                                      labelText: t.quantityLabel,
                                      isDense: true,
                                      filled: true,
                                      fillColor: Theme.of(context).canvasColor,
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _materialCostoCtrl,
                                    decoration: InputDecoration(
                                      labelText: t.unitCostLabel,
                                      isDense: true,
                                      filled: true,
                                      fillColor: Theme.of(context).canvasColor,
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(t.cancelButton),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveActivity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(t.saveButton),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveActivity() async {
    final t = AppLocalizations.of(context)!;
    final desc = _descripcionCtrl.text.trim();
    final notas = _notasCtrl.text.trim();

    if (desc.isEmpty) {
      // Validar campos requeridos
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t.activityDescriptionLabel}: ${t.requiredError}'),
        ),
      );
      return;
    }

    // Si hay selector de cliente, validar que se haya seleccionado
    final showClientSelector =
        widget.availableClients != null && widget.availableClients!.isNotEmpty;
    if (showClientSelector && _selectedCliente == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.mustSelectClient)));
      return;
    }

    // Horas automáticas en 0.0 ya que se calculan por asignación de trabajo
    final horas = 0.0;

    // Parsear materiales
    final matNombre = _materialNombreCtrl.text.trim();
    final matCantStr = _materialCantidadCtrl.text.trim();
    final matCostoStr = _materialCostoCtrl.text.trim();
    MaterialesUsados? materiales;

    if (matNombre.isNotEmpty &&
        matCantStr.isNotEmpty &&
        matCostoStr.isNotEmpty) {
      final cant = int.tryParse(matCantStr) ?? 0;
      final costo = double.tryParse(matCostoStr) ?? 0.0;
      if (cant > 0 && costo >= 0) {
        materiales = MaterialesUsados(
          nombre: matNombre,
          cantidad: cant,
          precioUnitario: costo,
        );
      }
    }

    // Determinar clienteId y trabajoAsignadoId
    String finalClienteId = widget.clienteId;
    String finalTrabajoAsignadoId = widget.trabajoAsignadoId;

    if (_selectedCliente != null) {
      finalClienteId = _selectedCliente!.id;
      // Buscar la asignación correspondiente al cliente seleccionado
      if (widget.availableAssignments != null) {
        try {
          final assignment = widget.availableAssignments!.firstWhere(
            (a) => a.clienteId == _selectedCliente!.id,
          );
          finalTrabajoAsignadoId = assignment.id;
        } catch (_) {
          // Si no se encuentra asignación en la lista disponible:
          // Validar si el cliente seleccionado es el mismo que se pasó por parámetros
          // y si ya venía un trabajoAsignadoId válido.
          if (_selectedCliente!.id == widget.clienteId &&
              widget.trabajoAsignadoId.isNotEmpty) {
            finalTrabajoAsignadoId = widget.trabajoAsignadoId;
          } else {
            finalTrabajoAsignadoId = '';
          }
        }
      }
    }

    // Obtener información del usuario actual
    final usuariosVM = context.read<UsuariosViewModel>();
    String tecnicoId = widget.userId;
    String tecnicoNombre = widget.userName;
    try {
      // Intentar buscar por ID primero, luego por nombre
      final usuario = usuariosVM.usuarios.firstWhere(
        (u) => u.id == widget.userId || u.nombre == widget.userName,
      );
      tecnicoId = usuario.id;
      tecnicoNombre = usuario.nombre;
    } catch (_) {
      // Mantener valores por defecto
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final actividadId =
        widget.existingActivity?.id ?? 'ACT_${widget.trabajoId}_$timestamp';

    final actividad = Actividad(
      id: actividadId,
      trabajoId: widget.trabajoId,
      trabajoAsignadoId: finalTrabajoAsignadoId,
      clienteId: finalClienteId,
      empresaId: widget.empresaId,
      tecnicoId: tecnicoId,
      tecnicoNombre: tecnicoNombre,
      fechaActividad: widget.existingActivity?.fechaActividad ?? DateTime.now(),
      descripcion: desc,
      horasTrabajadas: horas,
      materialesUsados: materiales,
      notas: notas,
      activo: true,
      creadoPor: widget.existingActivity?.creadoPor ?? tecnicoId,
      actualizadoPor: tecnicoId,
      fechaCreacion: widget.existingActivity?.fechaCreacion ?? DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );

    // Guardar actividad
    final actividadesVM = context.read<ActividadesViewModel>();

    if (widget.existingActivity != null) {
      await actividadesVM.actualizar(actividad);
    } else {
      await actividadesVM.agregar(actividad);
    }

    if (!mounted) return;

    // Si hay asignación, actualizar TrabajosAsignadosViewModel para métricas
    if (finalTrabajoAsignadoId.isNotEmpty) {
      final trabajosAsignadosVM = context.read<TrabajosAsignadosViewModel>();
      // Note: logic might be needed here to update metrics correctly on edit?
      // For now, we just ensure it's added if it's new.
      if (widget.existingActivity == null) {
        trabajosAsignadosVM.agregarActividad(finalTrabajoAsignadoId, actividad);
      }
    }

    // Crear gasto automático si hay materiales
    if (materiales != null) {
      final gastosVM = context.read<GastosViewModel>();

      // Asegurar que los tipos estén cargados antes de buscar
      if (gastosVM.tipos.isEmpty) {
        await gastosVM.cargarTipos(widget.empresaId);
      }

      String tipoGastoId = '';
      try {
        // Buscar tipo "Material" o "Materiales"
        final tipo = gastosVM.tipos.firstWhere(
          (t) => t.nombre.toLowerCase().contains('material'),
          orElse: () => gastosVM.tipos.isNotEmpty
              ? gastosVM.tipos.first
              : throw Exception('No expense types available'),
        );
        tipoGastoId = tipo.id;
      } catch (e) {
        // Error silently ignored
      }

      if (tipoGastoId.isNotEmpty) {
        final totalMaterial = materiales.cantidad * materiales.precioUnitario;
        final nuevoGasto = Gasto(
          id: '', // ID vacío para creación
          fechaGasto: DateTime.now(),
          monto: totalMaterial,
          empresaId: widget.empresaId,
          trabajoId: widget.trabajoId,
          clienteId: finalClienteId,
          trabajoAsignadoId: finalTrabajoAsignadoId,
          idTipoGasto: tipoGastoId,
          descripcion:
              'Materiales para actividad: $desc - ${materiales.nombre} (x${materiales.cantidad})',
          creadoPor: tecnicoId,
          actualizadoPor: tecnicoId,
          fechaCreacion: DateTime.now(),
          fechaActualizacion: DateTime.now(),
          urlComprobante: '', // Campo requerido
          activo: true,
        );
        await gastosVM.agregar(nuevoGasto);
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
      if (materiales != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.materialsRegisteredSuccess)));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.activityRegisteredSuccess)));
      }
    }
  }
}
