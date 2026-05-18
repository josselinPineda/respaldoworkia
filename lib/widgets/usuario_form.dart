import 'package:flutter/material.dart';
import 'package:workia/l10n/app_localizations.dart';
import '../models/usuario.dart';
import 'package:provider/provider.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';

/// Formulario reutilizable para editar usuarios existentes.
///
/// Presenta campos para nombre, correo, teléfono y selección de
/// perfil.  Al pulsar "Guardar" se llama a [onSave] con la
/// instancia de [Usuario] modificada.  Este formulario no
/// permite modificar la contraseña ni el estado de activación.
class UsuarioForm extends StatefulWidget {
  const UsuarioForm({super.key, required this.initial, required this.onSave});

  final Usuario initial;
  final void Function(Usuario) onSave;

  @override
  State<UsuarioForm> createState() => _UsuarioFormState();
}

class _UsuarioFormState extends State<UsuarioForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late String _role;
  late String _idioma;

  @override
  void initState() {
    super.initState();
    final u = widget.initial;
    _nameController = TextEditingController(text: u.nombre);
    _emailController = TextEditingController(text: u.email);
    _phoneController = TextEditingController(text: u.telefono);
    _role = u.perfilId;
    _idioma = u.idioma;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final currentUserId = context.read<UserSessionProvider>().userId;

    final updated = widget.initial.copyWith(
      nombre: _nameController.text.trim(),
      email: _emailController.text.trim(),
      telefono: _phoneController.text.trim(),
      perfilId: _role,
      idioma: _idioma,
      actualizadoPor: currentUserId,
      fechaActualizacion: DateTime.now(),
    );
    widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: t.nameLabel),
            validator: (value) =>
                value == null || value.trim().isEmpty ? t.requiredError : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: t.emailLabel),
            keyboardType: TextInputType.emailAddress,
            validator: (value) => value != null && value.contains('@')
                ? null
                : t.invalidEmailError,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(labelText: t.phoneLabel),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: InputDecoration(labelText: t.profileLabel),
            items: [
              DropdownMenuItem(value: 'PERF_ADMIN', child: Text(t.roleAdmin)),
              DropdownMenuItem(value: 'PERF_FIN', child: Text(t.roleFinance)),
              DropdownMenuItem(value: 'PERF_TEC', child: Text(t.roleTech)),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _role = val);
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _idioma,
            decoration: InputDecoration(labelText: t.languageLabel),
            items: [
              DropdownMenuItem(value: 'es', child: Text(t.spanishLanguage)),
              DropdownMenuItem(value: 'en', child: Text(t.englishLanguage)),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _idioma = val);
              }
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _handleSave, child: Text(t.saveButton)),
        ],
      ),
    );
  }
}
