import 'package:flutter/material.dart';
import 'package:workia/utils/ui_utils.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/models/cliente.dart';
import 'package:provider/provider.dart';
import 'package:workia/views/clients/client_edit_page.dart';
import 'package:workia/widgets/currency_text.dart';
import 'package:workia/presentation/viewmodels/trabajos_viewmodel.dart';
import 'package:workia/presentation/viewmodels/trabajos_asignados_viewmodel.dart';
import 'package:workia/models/job.dart';
import 'package:workia/models/trabajo_asignado.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';

/// Detail page for a single client.  Displays all available
/// information about the [client] and provides actions to edit or
/// delete the record.  Deletion is confirmed via a dialog to
/// prevent accidental removals.  Any modifications are
/// propagated through the provided [controller].
class ClientDetailPage extends StatelessWidget {
  const ClientDetailPage({super.key, required this.client});
  final Cliente client;
  // Ya no se recibe el controlador; se utilizará Provider para
  // acceder al ViewModel

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(client.nombre)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${t.clientNamePrefix}${client.nombre}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('${t.legalNamePrefix}${client.razonSocial}'),
            const SizedBox(height: 8),
            Text('${t.contactPersonPrefix}${client.personaContacto}'),
            const SizedBox(height: 8),
            Text('${t.emailPrefix}${client.correo}'),
            const SizedBox(height: 8),
            Text('${t.phonePrefix}${client.telefono}'),
            const SizedBox(height: 8),
            Text('${t.addressPrefix}${client.direccion}'),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    // Capturar el ViewModel antes de navegar
                    final clientesVM = context.read<ClientesViewModel>();
                    // Navegar a la página de edición.  Al regresar recargar los datos del cliente.
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClientEditPage(client: client),
                      ),
                    );
                    await clientesVM.cargarClientes(client.empresaId);
                    // Cerrar la vista solo si el context sigue montado
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: Text(t.editButton),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    // Capturar el ViewModel y el Navigator al inicio
                    final clientesVM = context.read<ClientesViewModel>();
                    final navigator = Navigator.of(context);
                    final confirm = await showWorkiaBottomSheet<bool>(
                      context: context,
                      builder: (dialogContext) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                t.deleteClientTitle,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Text(t.deleteClientConfirmation),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(t.cancelButton),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(t.deleteButton),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                    if (!context.mounted) return;
                    if (confirm ?? false) {
                      final userId = context.read<UserSessionProvider>().userId;
                      await clientesVM.eliminar(
                        client.id,
                        client.empresaId,
                        userId,
                      );
                      navigator.pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text(t.deleteButton),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Botón para asignar trabajos existentes a este cliente.
            // Al pulsar se abre un diálogo con lista de trabajos para
            // seleccionar.  Cuando se confirma se actualiza cada
            // trabajo añadiendo el nombre del cliente a su lista de
            // clientes asignados.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _assignJobsToClient(context),
                icon: const Icon(Icons.assignment_add),
                label: Text(t.assignJobsButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Abre un diálogo permitiendo seleccionar trabajos existentes
  /// para asignarlos al cliente actual.  Los trabajos se cargan
  /// desde el [TrabajosViewModel].  Al confirmar la selección se
  /// actualiza la lista de clientes asignados de cada trabajo y se
  /// guarda mediante el ViewModel.
  void _assignJobsToClient(BuildContext context) async {
    final trabajosVM = context.read<TrabajosViewModel>();
    final trabajos = List<Trabajo>.from(trabajosVM.trabajos);
    final asignadosVM = context.read<TrabajosAsignadosViewModel>();
    final tempSelected = <String>{};
    await showWorkiaBottomSheet<void>(
      context: context,
      builder: (context) {
        final t = AppLocalizations.of(context)!;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t.assignJobsToClientTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: trabajos.length,
                        itemBuilder: (context, index) {
                          final job = trabajos[index];
                          return CheckboxListTile(
                            title: Text(job.titulo),
                            subtitle: CurrencyText(
                              job.costo,
                              prefix: t.jobCostPrefix,
                            ),
                            value: tempSelected.contains(job.id),
                            onChanged: (checked) {
                              setStateDialog(() {
                                if (checked == true) {
                                  tempSelected.add(job.id);
                                } else {
                                  tempSelected.remove(job.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
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
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              final scaffoldMessenger = ScaffoldMessenger.of(
                                context,
                              );
                              // Crear un trabajo asignado para cada selección
                              for (final id in tempSelected) {
                                final jobIndex = trabajos.indexWhere(
                                  (j) => j.id == id,
                                );
                                if (jobIndex == -1) continue;
                                final trabajo = trabajos[jobIndex];
                                // Construir instancia de TrabajoAsignado con campos básicos
                                final nuevoAsignado = TrabajoAsignado(
                                  id: '',
                                  clienteId: client.id,
                                  trabajoId: trabajo.id,
                                  tituloTrabajo: trabajo.titulo,
                                  precioBase: trabajo.costo,
                                  precioFinal: trabajo.costo,
                                  estado: 'Pendiente',
                                  fechaInicio: DateTime.now(),
                                  fechaFin: DateTime.now(),
                                  proximaFecha: trabajo.esCiclico
                                      ? DateTime.now().add(
                                          const Duration(days: 365),
                                        )
                                      : null,
                                  esCiclico: trabajo.esCiclico,
                                  frecuenciaCiclico: trabajo.frecuenciaCiclico,
                                  tecnicosAsignados: const [],
                                  empresaId: trabajo.empresaId,
                                  activo: true,
                                  fechaCreacion: DateTime.now(),
                                  fechaActualizacion: DateTime.now(),
                                  creadoPor: '',
                                  actualizadoPor: '',
                                );
                                await asignadosVM.agregar(nuevoAsignado);
                              }
                              // Recargar trabajos asignados y cerrar diálogo
                              await asignadosVM.cargarTrabajosAsignados(
                                client.empresaId,
                              );
                              navigator.pop();
                              scaffoldMessenger.showSnackBar(
                                SnackBar(content: Text(t.jobsAssignedMessage)),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(t.assignButton),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
