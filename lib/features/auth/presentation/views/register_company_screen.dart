import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/models/usuario.dart';
import 'package:workia/presentation/viewmodels/empresa_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/features/auth/presentation/viewmodels/register_company_viewmodel.dart';
import 'package:workia/features/auth/presentation/widgets/company_location_picker.dart';

/// Pantalla de Registro de Empresa refactorizada con MVVM.
class RegisterCompanyScreen extends StatelessWidget {
  const RegisterCompanyScreen({
    super.key,
    required this.usuario,
    required this.password,
  });

  final Usuario usuario;
  final String password;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => RegisterCompanyViewModel(
        empresaVM: ctx.read<EmpresaViewModel>(),
        usuariosVM: ctx.read<UsuariosViewModel>(),
      )..determineCurrentPosition(),
      child: _RegisterCompanyContent(usuario: usuario, password: password),
    );
  }
}

class _RegisterCompanyContent extends StatefulWidget {
  const _RegisterCompanyContent({
    required this.usuario,
    required this.password,
  });

  final Usuario usuario;
  final String password;

  @override
  State<_RegisterCompanyContent> createState() =>
      _RegisterCompanyContentState();
}

class _RegisterCompanyContentState extends State<_RegisterCompanyContent> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _nombreComercialController = TextEditingController();
  final _razonSocialController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _emailController = TextEditingController();

  LatLng? _selectedLatLng;

  @override
  void dispose() {
    _nombreController.dispose();
    _nombreComercialController.dispose();
    _razonSocialController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _openMapModal(BuildContext context) {
    final vm = context.read<RegisterCompanyViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CompanyLocationPicker(
        initialLocation: _selectedLatLng,
        userLocation: vm.currentLocation,
        onLocationSelected: (loc) {
          setState(() => _selectedLatLng = loc);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<RegisterCompanyViewModel>();
    final t = AppLocalizations.of(context)!;

    final success = await vm.registerCompanyAndUser(
      usuario: widget.usuario,
      password: widget.password,
      nombre: _nombreController.text.trim(),
      nombreComercial: _nombreComercialController.text.trim(),
      razonSocial: _razonSocialController.text.trim(),
      telefono: _telefonoController.text.trim(),
      direccion: _direccionController.text.trim(),
      emailEmpresa: _emailController.text.trim(),
      ubicacion: _selectedLatLng,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.accountCreatedSuccessMessage)));
      context.go('/login');
    } else {
      String msg = vm.error ?? t.unexpectedError('Unknown');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterCompanyViewModel>();
    final t = AppLocalizations.of(context)!;

    // TODO: Refactoriza esto para usar UIUtils o InputDecorations centralizados
    return Scaffold(
      appBar: AppBar(title: Text(t.registerCompanyTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t.companyDataTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(labelText: t.nameLabel),
                      validator: (v) =>
                          v?.isNotEmpty == true ? null : t.requiredError,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _nombreComercialController,
                      decoration: InputDecoration(
                        labelText: t.commercialNameLabel,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _razonSocialController,
                      decoration: InputDecoration(
                        labelText: t.socialReasonLabel,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _telefonoController,
                      decoration: InputDecoration(labelText: t.phoneLabel),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _direccionController,
                      decoration: InputDecoration(labelText: t.addressLabel),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: t.companyEmailLabel,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: () => _openMapModal(context),
                      icon: const Icon(Icons.location_on),
                      label: Text(
                        _selectedLatLng == null
                            ? t.selectLocationTitle
                            : '${t.locationPrefix}${_selectedLatLng!.latitude.toStringAsFixed(5)}, ${_selectedLatLng!.longitude.toStringAsFixed(5)}',
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (vm.error != null) ...[
                      Text(
                        vm.error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],

                    ElevatedButton(
                      onPressed: vm.isLoading ? null : _submit,
                      child: vm.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(t.registerAndFinishButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
