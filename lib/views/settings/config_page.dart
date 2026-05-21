import 'package:flutter/material.dart';

import 'package:workia/views/settings/user_settings_page.dart';
import 'package:workia/models/empresa.dart';
import 'package:provider/provider.dart';
import 'package:workia/presentation/viewmodels/empresa_viewmodel.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/widgets/currency_text.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';

/// Settings page allowing an administrator to configure company
/// information.  Fields are static in this example and not bound to
/// persistent storage.
class ConfigPage extends StatefulWidget {
  const ConfigPage({
    super.key,
    required this.userName,
    required this.role,
    required this.userId,
    required this.empresaId,
  });
  final String userName;
  final String role;
  final String userId;
  final String empresaId;

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  late TextEditingController _companyNameController;
  late TextEditingController _legalNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _exchangeRateController;

  /// Compute the initials of the current user's name.
  String _initials() {
    final parts = widget.userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _legalNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Obtener la empresa actual desde el view model.  Esto se realiza
    // después del primer frame para acceder al contexto.  Primero
    // inicializamos los controladores y luego cargamos la empresa
    // actual del view model.
    _companyNameController = TextEditingController();
    _legalNameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _emailController = TextEditingController();
    _exchangeRateController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // cargar la empresa desde el repositorio a través del view model
      final empresaViewModel = context.read<EmpresaViewModel>();
      final session = context.read<UserSessionProvider>();
      final targetEmpresaId =
          widget.empresaId.isNotEmpty ? widget.empresaId : session.empresaId;
      // Si el view model ya tenía una empresa cargada de una sesión anterior,
      // forzar la carga cuando no coincide con el `empresaId` actual.
      if (empresaViewModel.empresa == null ||
          empresaViewModel.empresa?.id != targetEmpresaId) {
        if (targetEmpresaId.isNotEmpty) {
          await empresaViewModel.cargarEmpresa(targetEmpresaId);
        }
      }
      final empresa = empresaViewModel.empresa;
      _companyNameController.text = empresa?.nombreComercial ?? '';
      _legalNameController.text = empresa?.razonSocial ?? '';
      _phoneController.text = empresa?.telefono ?? '';
      _addressController.text = empresa?.direccion ?? '';
      _emailController.text = empresa?.email ?? '';
      _exchangeRateController.text =
          empresa?.tasaCambio?.toStringAsFixed(2) ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        // Display a more descriptive title for company details
        title: Text(t.companyDataTitle),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserSettingsPage(
                    userName: widget.userName,
                    role: widget.role,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  _initials(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.companyDataTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _companyNameController,
                  label: t.commercialNameLabel,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _legalNameController,
                  label: t.legalNameLabel,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _phoneController,
                  label: t.phoneLabel,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _addressController,
                  label: t.addressLabel,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _emailController,
                  label: t.emailLabel,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _exchangeRateController,
                  label: t.exchangeRateLabel,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Capturar Navigator/ScaffoldMessenger y ViewModel al inicio para no usar context después de await
                      final empresaVM = context.read<EmpresaViewModel>();
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      double? tasaCambio;
                      if (_exchangeRateController.text.isNotEmpty) {
                        tasaCambio = double.tryParse(
                          _exchangeRateController.text.replaceAll(',', '.'),
                        );
                      }


                      // Recopilar valores y actualizar la empresa a través del view model.
                      final Empresa nuevaEmpresa = Empresa(
                        id: empresaVM.empresa?.id ?? '',
                        nombreComercial: _companyNameController.text.trim(),
                        razonSocial: _legalNameController.text.trim(),
                        telefono: _phoneController.text.trim(),
                        direccion: _addressController.text.trim(),
                        email: _emailController.text.trim(),
                        tasaCambio: tasaCambio,
                      );
                      // Guardar usando el view model y esperar a que finalice
                      await empresaVM.guardar(nuevaEmpresa);
                      if (!mounted) return;
                      // Actualizar estado local y mostrar mensaje

                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text(t.dataSavedMessage)),
                      );
                    },
                    child: Text(t.saveChangesButton),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    );
  }
}
