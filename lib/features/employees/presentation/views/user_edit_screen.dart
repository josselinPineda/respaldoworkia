import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/models/usuario.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/widgets/usuario_form.dart';

/// Pantalla de Edición de Usuario refactorizada.
class UserEditScreen extends StatelessWidget {
  const UserEditScreen({super.key, required this.user});
  final Usuario user;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.editUserTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UsuarioForm(
                initial: user,
                onSave: (usuario) {
                  final usuariosVM = context.read<UsuariosViewModel>();
                  usuariosVM.actualizar(usuario);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
