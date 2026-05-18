import 'package:workia/models/job.dart';
import 'package:workia/models/usuario.dart';
import 'package:workia/presentation/viewmodels/empresa_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Form screen for creating a new job or editing an existing one.
/// When [job] is null a new job is added; otherwise the existing
/// job is updated.  The form collects title, client, start and
/// end dates and status.
class JobFormScreen extends StatefulWidget {
  const JobFormScreen({super.key, this.job, required this.role});
  final Job? job;

  /// Rol del usuario que edita o crea el trabajo.  Esto se utiliza
  /// para determinar si puede ver o editar campos como el costo y
  /// para ajustar la interfaz.
  final String role;

  @override
  State<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends State<JobFormScreen> {
  /// Clave para validar el formulario.
  final _formKey = GlobalKey<FormState>();

  /// Controlador del campo de título.
  late TextEditingController _titleController;

  /// Controlador del campo de costo.  Si el valor no es numérico
  /// se interpretará como 0.0.
  late TextEditingController _costController;

  late TextEditingController _autoFinalizeHoursController;

  /// Descripción del trabajo.
  String _description = '';

  @override
  void initState() {
    super.initState();
    final j = widget.job;
    _titleController = TextEditingController(text: j?.titulo ?? '');
    _costController = TextEditingController(
      text: j?.costo != null ? j!.costo.toString() : '',
    );
    _autoFinalizeHoursController = TextEditingController(
      text: j?.autoFinalizarHoras?.toString() ?? '',
    );

    // Inicializar la descripción del trabajo.
    _description = j?.descripcion ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _costController.dispose();
    _autoFinalizeHoursController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Convertimos el costo ingresado a número.
    // Si el usuario dejó el campo vacío o ingresó texto no válido,
    // se usa 0.0 como valor predeterminado.
    double costo = 0.0;
    final costStr = _costController.text.trim();
    if (costStr.isNotEmpty) {
      final costParsed = double.tryParse(costStr);
      if (costParsed != null) {
        costo = costParsed;
      }
    }

    int? autoFinalizarHoras;
    if (widget.role != 'PERF_TEC') {
      final raw = _autoFinalizeHoursController.text.trim();
      if (raw.isNotEmpty) {
        autoFinalizarHoras =
            int.tryParse(raw) ?? double.tryParse(raw)?.round();
      }
    }

    // Determinamos si estamos editando un trabajo existente o creando uno nuevo.
    // En caso de edición mantenemos el mismo ID; en caso de creación enviamos
    // una cadena vacía para que el repositorio genere uno nuevo.
    final jobId = widget.job?.id ?? '';

    // Obtener el id de la empresa asociada al usuario actual.
    final empresaVM = context.read<EmpresaViewModel?>();
    String empresaIdActual = empresaVM?.empresa?.id ?? '';

    // Si no se pudo obtener de EmpresaViewModel, intentar desde UsuariosViewModel
    if (empresaIdActual.isEmpty) {
      final usuariosVM = context.read<UsuariosViewModel?>();
      final currentUser = usuariosVM?.usuarios.firstWhere(
        (u) => u.nombre == widget.role || u.perfilId == widget.role,
        orElse: () => usuariosVM.usuarios.isNotEmpty
            ? usuariosVM.usuarios.first
            : Usuario(
                id: '',
                authUid: '',
                nombre: '',
                email: '',
                idEmpresa: '',
                perfilId: '',
              ),
      );
      empresaIdActual = currentUser?.idEmpresa ?? '';
    }

    // Normalizar las fechas a la fecha actual ya que no se gestionan en este formulario
    final DateTime now = DateTime.now();
    final normalizedStart = DateTime(now.year, now.month, now.day, 12);
    final normalizedEnd = DateTime(now.year, now.month, now.day, 12);

    // Creamos la instancia de Trabajo con los valores del formulario.
    // Muchos campos se inicializan vacíos porque este formulario solo
    // define título, descripción y costo; el resto se gestiona en otros
    // flujos de la aplicación (por ejemplo, la asignación de cliente y fechas).
    final nuevoTrabajo = Trabajo(
      id: jobId,
      titulo: _titleController.text.trim(),
      cliente: '',
      clienteId: '',
      fechaInicio: normalizedStart,
      fechaFin: normalizedEnd,
      estado: '',
      descripcion: _description.trim(),
      costo: costo,
      autoFinalizarHoras: autoFinalizarHoras,
      empleadosAsignados: const [],
      clientesAsignados: const [],
      esCiclico: false, // Se gestiona en la asignación
      frecuenciaCiclico: null,
      proximaFecha: null,
      empresaId: empresaIdActual,
      fechaCreacion: widget.job?.fechaCreacion ?? DateTime.now(),
      fechaActualizacion: DateTime.now(),
      creadoPor: widget.job?.creadoPor.isNotEmpty == true
          ? widget.job!.creadoPor
          : (empresaVM?.empresa?.id != null
                ? (context.read<UserSessionProvider>().userId)
                : ''),
      actualizadoPor: context.read<UserSessionProvider>().userId,
      activo: widget.job?.activo ?? true,
    );
    final trabajosVM = context.read<TrabajosViewModel>();
    // Guardamos el trabajo usando el ViewModel.
    // Si el trabajo es nuevo se agrega; si ya existía se actualiza.
    if (widget.job == null) {
      await trabajosVM.agregar(nuevoTrabajo);
    } else {
      await trabajosVM.actualizar(nuevoTrabajo);
    }

    // Volver a la vista anterior
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.job != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? AppLocalizations.of(context)!.editJobFormTitle
              : AppLocalizations.of(context)!.newJobFormTitle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sección de información general
                Container(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.jobInformationSection,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      // Campo para ingresar el título del trabajo.
                      // Es obligatorio y mostrará error si queda vacío.
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.titleLabel,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? AppLocalizations.of(context)!.requiredError
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _description,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(
                            context,
                          )!.descriptionFieldLabel,
                        ),
                        maxLines: 3,
                        onChanged: (val) {
                          _description = val;
                        },
                      ),
                      const SizedBox(height: 12),
                      if (widget.role != 'PERF_TEC') ...[
                        TextFormField(
                          controller: _costController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.costFieldLabel,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (widget.role != 'PERF_TEC') ...[
                        TextFormField(
                          controller: _autoFinalizeHoursController,
                          decoration: const InputDecoration(
                            labelText: 'Tiempo del trabajo (horas)',
                            hintText: 'Ej: 2',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _save,
                  child: Text(AppLocalizations.of(context)!.saveButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
