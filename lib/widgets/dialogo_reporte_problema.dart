import 'package:flutter/material.dart';

import '../models/problem.dart';
import '../models/job.dart';
import '../models/gasto.dart';
import '../models/trabajo_asignado.dart';
// Importar provider y ViewModel para obtener asignaciones cuando no se
// proporcionan explícitamente desde la llamada.  Esto permite que el
// diálogo muestre trabajos asignados disponibles sin depender de la
// pantalla que lo invoque.
import 'package:provider/provider.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import '../presentation/providers/user_session_provider.dart';
import '../presentation/viewmodels/usuarios_viewmodel.dart';
import '../presentation/viewmodels/clientes_viewmodel.dart';

/// Diálogo reutilizable para reportar un nuevo problema.
class DialogoReporteProblema extends StatefulWidget {
  const DialogoReporteProblema({
    super.key,
    required this.userName,
    required this.role,
    required this.onSave,
    this.onCancel,
    this.jobs = const [],
    this.gastos = const [],
    this.allowedTipos,
    this.trabajosAsignados = const [],
    this.problema,
  });

  final String userName;
  final String role;
  final List<Job> jobs;
  final List<Gasto> gastos;
  final List<TrabajoAsignado> trabajosAsignados;
  final List<String>? allowedTipos;
  final Problema? problema;
  final Future<void> Function(Problema) onSave; // Cambio a Future<void>
  final VoidCallback? onCancel;

  @override
  State<DialogoReporteProblema> createState() => _DialogoReporteProblemaState();
}

class _DialogoReporteProblemaState extends State<DialogoReporteProblema> {
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late String _selectedTipo;
  String? _selectedRefId;

  // Campos para edición avanzada (Admin)
  String? _selectedReporterId;
  String? _selectedResolverId;

  @override
  void initState() {
    super.initState();
    _selectedTipo = _getDefaultTipo();

    if (widget.problema != null) {
      _titleController.text = widget.problema!.titulo;
      _detailsController.text = widget.problema!.descripcion;
      _selectedTipo = widget.problema!.referenciaTipo;
      _selectedRefId = widget.problema!.referenciaId;
      _selectedReporterId = widget.problema!.reportadoPorId;
      _selectedResolverId = widget.problema!.resueltoPorId;
    } else {
      final userId = context.read<UserSessionProvider>().userId;
      _selectedReporterId = userId;
    }

    if (widget.role == 'PERF_ADMIN') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final empresaId = context.read<UserSessionProvider>().empresaId;
        context.read<TrabajosAsignadosViewModel>().cargarTrabajosAsignados(
          empresaId,
        );
        context.read<UsuariosViewModel>().cargarUsuarios(empresaId);
        context.read<ClientesViewModel>().cargarClientes(empresaId);
      });
    }
  }

  String _getDefaultTipo() {
    if (widget.allowedTipos != null && widget.allowedTipos!.isNotEmpty) {
      return widget.allowedTipos!.first;
    }
    if (widget.role == 'PERF_TEC' || widget.role == 'PERF_ADMIN') {
      return 'Trabajo';
    } else if (widget.role == 'PERF_FIN') {
      return 'Gasto';
    }
    return 'Otro';
  }

  String _formatRole(String role) {
    switch (role) {
      case 'PERF_ADMIN':
        return AppLocalizations.of(context)!.adminRole;
      case 'PERF_TEC':
        return AppLocalizations.of(context)!.technicianRole;
      case 'PERF_FIN':
        return AppLocalizations.of(context)!.financeRole;
      default:
        return role;
    }
  }

  List<DropdownMenuItem<String>> _buildRefItems(BuildContext context) {
    if (_selectedTipo == 'Trabajo') {
      List<TrabajoAsignado> asignaciones = widget.trabajosAsignados;
      if (widget.role == 'PERF_ADMIN' || asignaciones.isEmpty) {
        try {
          final vm = context.watch<TrabajosAsignadosViewModel>();
          asignaciones = vm.trabajos;
        } catch (_) {}
      }

      if (widget.role == 'PERF_TEC') {
        final userId = context.read<UserSessionProvider>().userId;
        if (userId.isNotEmpty) {
          asignaciones = asignaciones
              .where((a) => a.tecnicosAsignados.contains(userId))
              .toList();
        } else {
          asignaciones = [];
        }
      }

      if (asignaciones.isNotEmpty) {
        return asignaciones.map((a) {
          String titulo = a.tituloTrabajo;
          if (titulo.isEmpty) {
            try {
              final job = widget.jobs.firstWhere((j) => j.id == a.trabajoId);
              titulo = job.titulo;
            } catch (_) {
              titulo = a.trabajoId;
            }
          }
          String clientName = 'Cliente desconocido';
          try {
            final clientesVM = context.read<ClientesViewModel>();
            final cliente = clientesVM.clientes.firstWhere(
              (c) => c.id == a.clienteId,
            );
            clientName = cliente.nombre;
          } catch (_) {}

          return DropdownMenuItem(
            value: a.id,
            child: Text(
              '$titulo - $clientName',
              overflow: TextOverflow.visible,
              softWrap: true,
            ),
          );
        }).toList();
      }

      if (widget.role == 'PERF_TEC') {
        return [
          const DropdownMenuItem(
            value: '__NONE__',
            enabled: false,
            child: Text('No hay trabajos asignados'),
          ),
        ];
      }

      List<Job> genericJobs = widget.jobs;
      if (genericJobs.isEmpty) {
        try {
          final vm = context.read<TrabajosViewModel>();
          genericJobs = vm.trabajos;
        } catch (_) {}
      }

      return genericJobs
          .map(
            (t) => DropdownMenuItem(
              value: t.id,
              child: Text(
                t.titulo,
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            ),
          )
          .toList();
    } else if (_selectedTipo == 'Gasto') {
      return widget.gastos
          .map(
            (g) => DropdownMenuItem(
              value: g.id,
              child: Text('Gasto \$${g.monto.toStringAsFixed(2)}'),
            ),
          )
          .toList();
    }
    return [];
  }

  Future<void> _onGuardar() async {
    print('>>> CLICK DETECTADO EN EL BOTÓN GUARDAR <<<');
    final title = _titleController.text.trim();
    final details = _detailsController.text.trim();

    if (title.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, escribe un título')));
       return;
    }
    if (details.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, escribe la descripción')));
       return;
    }
    if (!_formKey.currentState!.validate()) return;

    try {
      String trabajoAsignadoId = '';
      String trabajoId = '';
      String clienteId = '';
      if (_selectedTipo == 'Trabajo' && _selectedRefId != null) {
        try {
          final asigList = context.read<TrabajosAsignadosViewModel>().trabajos;
          final asig = asigList.firstWhere((a) => a.id == _selectedRefId);
          trabajoAsignadoId = asig.id;
          trabajoId = asig.trabajoId;
          clienteId = asig.clienteId;
        } catch (_) {}
      } else if (_selectedTipo == 'Gasto' && _selectedRefId != null) {
        try {
          final gasto = widget.gastos.firstWhere((g) => g.id == _selectedRefId);
          trabajoAsignadoId = gasto.trabajoAsignadoId;
          trabajoId = gasto.trabajoId;
          clienteId = gasto.clienteId;
        } catch (_) {}
      }

      final session = context.read<UserSessionProvider>();
      final userId = session.userId;
      if (session.empresaId.isEmpty) throw 'No se encontró el ID de la empresa en la sesión';

      final reportadoPor = _selectedReporterId ?? userId;
      final resueltoPor = _selectedResolverId ?? '';
      final estado = resueltoPor.isNotEmpty ? 'resuelto' : 'pendiente';

      final problema = widget.problema != null
          ? widget.problema!.copyWith(
              titulo: title,
              descripcion: details,
              referenciaTipo: _selectedTipo,
              referenciaId: _selectedTipo == 'Otro' ? null : _selectedRefId,
              trabajoAsignadoId: trabajoAsignadoId,
              trabajoId: trabajoId,
              clienteId: clienteId,
              actualizadoPorId: userId,
              reportadoPorId: reportadoPor,
              resueltoPorId: resueltoPor,
              estado: widget.problema!.resuelto ? 'resuelto' : estado,
            )
          : Problema(
              titulo: title,
              descripcion: details,
              reportadoPorId: reportadoPor,
              rolReportante: widget.role,
              nombreReportante: widget.userName,
              referenciaTipo: _selectedTipo,
              referenciaId: _selectedTipo == 'Otro' ? null : _selectedRefId,
              trabajoAsignadoId: trabajoAsignadoId,
              trabajoId: trabajoId,
              clienteId: clienteId,
              creadoPorId: userId,
              actualizadoPorId: userId,
              estado: estado,
              resueltoPorId: resueltoPor,
              empresaId: session.empresaId,
            );

      // ESPERAMOS a que termine el guardado real en Firebase
      await widget.onSave(problema);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.problema != null
                          ? AppLocalizations.of(context)!.editProblemTitle
                          : AppLocalizations.of(context)!.reportNewProblemTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.titleLabel,
                          ),
                          validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _detailsController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.problemDetailsLabel,
                          ),
                          maxLines: 3,
                          validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                        ),
                        const SizedBox(height: 8),
                        if ((widget.allowedTipos ?? [_selectedTipo]).length > 1)
                          DropdownButtonFormField<String>(
                            value: _selectedTipo,
                            menuMaxHeight: 300,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              )!.referenceTypeLabel,
                            ),
                            items: (widget.allowedTipos ?? ['Trabajo', 'Gasto', 'Otro'])
                                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() {
                                _selectedTipo = val;
                                _selectedRefId = null;
                              });
                            },
                          )
                        else
                          Text(
                            '${AppLocalizations.of(context)!.referenceTypePrefix}$_selectedTipo',
                          ),
                        const SizedBox(height: 8),
                        if (_selectedTipo != 'Otro')
                          DropdownButtonFormField<String>(
                            value: _selectedRefId,
                            isExpanded: true,
                            itemHeight: null,
                            menuMaxHeight: 300,
                            decoration: InputDecoration(
                              labelText: _selectedTipo == 'Trabajo'
                                  ? (widget.trabajosAsignados.isNotEmpty
                                        ? AppLocalizations.of(
                                            context,
                                          )!.selectAssignmentLabel
                                        : AppLocalizations.of(context)!.selectJobLabel)
                                  : AppLocalizations.of(context)!.selectExpenseLabel,
                            ),
                            items: _buildRefItems(context),
                            selectedItemBuilder: (BuildContext context) {
                              final items = _buildRefItems(context);
                              return items.map<Widget>((item) {
                                return Text(
                                  (item.child as Text).data ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  maxLines: 2,
                                );
                              }).toList();
                            },
                            onChanged: (val) {
                              setState(() {
                                _selectedRefId = val;
                              });
                            },
                            validator: (value) {
                              if (_selectedTipo == 'Trabajo' &&
                                  (value == null || value.isEmpty)) {
                                return AppLocalizations.of(context)!.mustSelectJobError;
                              }
                              return null;
                            },
                          ),
                        if (widget.role == 'PERF_ADMIN') ...[
                          const SizedBox(height: 12),
                          ExpansionTile(
                            title: Text(
                              AppLocalizations.of(context)!.responsibleManagementTitle,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Consumer<UsuariosViewModel>(
                                      builder: (context, usuariosVM, child) {
                                        return DropdownButtonFormField<String>(
                                          value: _selectedReporterId,
                                          menuMaxHeight: 300,
                                          decoration: InputDecoration(
                                            labelText: AppLocalizations.of(
                                              context,
                                            )!.reportedByLabel,
                                          ),
                                          items: usuariosVM.usuarios.map((u) {
                                            return DropdownMenuItem(
                                              value: u.id,
                                              child: Text(
                                                '${u.nombre} (${_formatRole(u.perfilId)})',
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedReporterId = val;
                                            });
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Consumer<UsuariosViewModel>(
                                      builder: (context, usuariosVM, child) {
                                        return DropdownButtonFormField<String>(
                                          value: _selectedResolverId,
                                          menuMaxHeight: 300,
                                          decoration: InputDecoration(
                                            labelText: AppLocalizations.of(
                                              context,
                                            )!.resolvedByLabel,
                                          ),
                                          items: [
                                            DropdownMenuItem(
                                              value: null,
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.notResolvedStatus,
                                              ),
                                            ),
                                            ...usuariosVM.usuarios.map((u) {
                                              return DropdownMenuItem(
                                                value: u.id,
                                                child: Text(
                                                  '${u.nombre} (${_formatRole(u.perfilId)})',
                                                ),
                                              );
                                            }),
                                          ],
                                          onChanged: (val) => setState(() => _selectedResolverId = val),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              child: Text(AppLocalizations.of(context)!.cancelButton),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _onGuardar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: Text(AppLocalizations.of(context)!.saveButton),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }
}
