import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/models/tipo_gasto.dart';
import 'package:workia/presentation/viewmodels/gastos_viewmodel.dart';

class ExpenseTypesView extends StatelessWidget {
  const ExpenseTypesView({super.key, required this.empresaId});

  final String empresaId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final viewModel = context.watch<GastosViewModel>();
    final tipos = viewModel.tipos;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.manageExpenseTypes),
      ),
      body: ListView.builder(
        itemCount: tipos.length,
        itemBuilder: (context, index) {
          final tipo = tipos[index];
          return ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.category),
            ),
            title: Text(tipo.nombre),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showAddEditTypeDialog(context, tipo),
            ),
            onLongPress: () => _confirmDelete(context, tipo),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditTypeDialog(context),
        child: const Icon(Icons.add),
        tooltip: t.addExpenseType,
      ),
    );
  }

  void _showAddEditTypeDialog(BuildContext context, [TipoGasto? existing]) {
    final nameController = TextEditingController(text: existing?.nombre ?? '');
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? t.addExpenseType : t.editExpenseType),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: t.nameLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancelButton),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              
              final novo = TipoGasto(
                id: existing?.id ?? '',
                empresaId: empresaId,
                codigo: existing?.codigo ?? nameController.text.toUpperCase().replaceAll(' ', '_'),
                nombre: nameController.text,
                descripcion: '',
              );

              final vm = context.read<GastosViewModel>();
              try {
                if (existing == null) {
                  await vm.agregarTipo(novo);
                } else {
                  await vm.actualizarTipo(novo);
                }

                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(t.dataSavedMessage)),
                  );
                  Navigator.pop(ctx);
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(t.unexpectedError(e.toString())),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(t.saveButton),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, TipoGasto tipo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar este tipo de gasto'),
        content: Text('¿Estás seguro de eliminar el tipo de gasto ${tipo.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<GastosViewModel>().eliminarTipo(tipo.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Sí'),
          ),
        ],
      ),
    );
  }
}
