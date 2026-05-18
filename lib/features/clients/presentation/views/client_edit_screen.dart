import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workia/models/cliente.dart';
import 'package:workia/presentation/viewmodels/clientes_viewmodel.dart';
import 'package:workia/widgets/cliente_form.dart';
import 'package:workia/l10n/app_localizations.dart';

class ClientEditScreen extends StatelessWidget {
  const ClientEditScreen({
    super.key,
    this.client,
    required this.userId,
    required this.empresaId,
  });

  final Cliente? client;
  final String userId;
  final String empresaId;

  @override
  Widget build(BuildContext context) {
    final isEditing = client != null;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? t.editClientTitle : t.newClientTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClienteForm(
                initial: client,
                onSave: (cliente) {
                  final clientesVM = context.read<ClientesViewModel>();
                  final now = DateTime.now();

                  // Enriquecer el cliente con datos de auditorÃa y empresa
                  final enriched = cliente.copyWith(
                    empresaId: empresaId.isNotEmpty
                        ? empresaId
                        : cliente.empresaId,
                    fechaCreacion: cliente.fechaCreacion ?? now,
                    fechaActualizacion: now,
                    creadoPor: cliente.creadoPor.isNotEmpty
                        ? cliente.creadoPor
                        : userId,
                    actualizadoPor: userId,
                  );

                  if (isEditing) {
                    clientesVM.actualizar(enriched);
                  } else {
                    clientesVM.agregar(enriched);
                  }

                  // Retornar indicando la acciÃ³n realizada puede ser Ãºtil, pero el pop es suficiente
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
