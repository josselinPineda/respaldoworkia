import 'package:workia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:workia/models/usuario.dart';
import 'package:provider/provider.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/widgets/usuario_form.dart';

/// A form page for editing or deleting an existing user.  The
/// page receives a [Usuario] and a [UsersController] to apply
/// modifications.  Changing the password is not implemented
/// here but could be added similarly to other fields.
class UserEditPage extends StatefulWidget {
  const UserEditPage({super.key, required this.user});
  final Usuario user;

  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  // El formulario se extrae a UsuarioForm; los controladores se gestionan ahí.

  @override
  void initState() {
    super.initState();
    // No inicializar controladores aquí; serán gestionados por UsuarioForm.
  }

  @override
  void dispose() {
    // Controladores gestionados por UsuarioForm.
    super.dispose();
  }

  // Eliminado el método _save; UsuarioForm maneja la lógica de guardado.

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
              // El formulario se muestra directamente sin tarjeta
              UsuarioForm(
                initial: widget.user,
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
