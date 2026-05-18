import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workia/models/cliente.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/widgets/cliente_form.dart';
import 'package:workia/l10n/app_localizations.dart';

/// Form page for creating a new client or editing an existing one.
/// If [client] is null a new client will be created; otherwise
/// the existing record will be updated.  Upon save the page
/// pops back to the previous screen.
class ClientEditPage extends StatefulWidget {
  const ClientEditPage({
    super.key,
    this.client,
    this.userId = '',
    this.empresaId = '',
  });

  /// Cliente a editar.  Si es `null` se creará un nuevo registro.
  final Cliente? client;

  /// Identificador del usuario autenticado.  Se utiliza para
  /// establecer los campos `creadoPor` y `actualizadoPor` del cliente.
  final String userId;

  /// Identificador de la empresa asociada al usuario.  Se utiliza
  /// para asignar la empresa al cliente al guardar.
  final String empresaId;

  @override
  State<ClientEditPage> createState() => _ClientEditPageState();
}

class _ClientEditPageState extends State<ClientEditPage> {
  // Los controladores y el formKey se han movido al widget ClienteForm.

  @override
  void initState() {
    super.initState();
    // No inicializar controladores aquí; son gestionados por ClienteForm.
  }

  @override
  void dispose() {
    // No se eliminan controladores aquí; son gestionados por ClienteForm.
    super.dispose();
  }

  // Eliminado el método _save, ya que ClienteForm gestiona la operación de guardado.

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.client != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? AppLocalizations.of(context)!.editClientTitle
              : AppLocalizations.of(context)!.newClientTitle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClienteForm(
                initial: widget.client,
                onSave: (cliente) {
                  final clientesVM = context.read<ClientesViewModel>();
                  final now = DateTime.now();
                  // Enriquecer el cliente con empresaId y campos de auditoría
                  final enriched = cliente.copyWith(
                    empresaId: widget.empresaId.isNotEmpty
                        ? widget.empresaId
                        : cliente.empresaId,
                    fechaCreacion: cliente.fechaCreacion ?? now,
                    fechaActualizacion: now,
                    creadoPor: cliente.creadoPor.isNotEmpty
                        ? cliente.creadoPor
                        : widget.userId,
                    actualizadoPor: widget.userId,
                  );
                  if (widget.client == null) {
                    clientesVM.agregar(enriched);
                  } else {
                    clientesVM.actualizar(enriched);
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
