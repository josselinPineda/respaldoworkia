import 'package:workia/models/job.dart';
import 'package:workia/models/usuario.dart';
import 'package:workia/presentation/viewmodels/empresa_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Form page for creating a new job or editing an existing one.
/// When [job] is null a new job is added; otherwise the existing
/// job is updated.  The form collects title, client, start and
/// end dates and status.
class JobFormPage extends StatefulWidget {
  const JobFormPage({super.key, this.job, required this.role});
  final Job? job;

  /// Rol del usuario que edita o crea el trabajo.  Esto se utiliza
  /// para determinar si puede ver o editar campos como el costo y
  /// para ajustar la interfaz.
  final String role;

  @override
  State<JobFormPage> createState() => _JobFormPageState();
}

class _JobFormPageState extends State<JobFormPage> {
  /// Clave para validar el formulario.
  final _formKey = GlobalKey<FormState>();

  /// Controlador del campo de título.
  late TextEditingController _titleController;

  /// Controlador del campo de costo.  Si el valor no es numérico
  /// se interpretará como 0.0.
  late TextEditingController _costController;


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

    // Inicializar la descripción del trabajo.
    _description = j?.descripcion ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Parse cost from the cost controller.  If parsing fails set to zero.
    double costo = 0.0;
    final costStr = _costController.text.trim();
    if (costStr.isNotEmpty) {
      final costParsed = double.tryParse(costStr);
      if (costParsed != null) {
        costo = costParsed;
      }
    }


    // Generar el identificador del trabajo.  Si se está editando un
    // trabajo existente se conserva su id.  Si es nuevo, enviamos
    // una cadena vacía y el repositorio se encargará de generar un ID
    // único (TRB_TITULO_TIMESTAMP).
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
    // Guardar el trabajo en el catálogo
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
