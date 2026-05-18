import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workia/features/settings/presentation/views/user_settings_screen.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/models/empresa.dart';
import 'package:workia/presentation/viewmodels/empresa_viewmodel.dart';

/// Settings page allowing an administrator to configure company
/// information.
class ConfigScreen extends StatefulWidget {
  const ConfigScreen({
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
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  late TextEditingController _companyNameController;
  late TextEditingController _legalNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _logoUrlController;
  late TextEditingController _exchangeRateController;

  // Temporarily holds the last saved company information for display.
  Empresa? _savedCompany;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _legalNameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _emailController = TextEditingController();
    _logoUrlController = TextEditingController();
    _exchangeRateController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final empresaViewModel = context.read<EmpresaViewModel>();
      if (empresaViewModel.empresa == null) {
        await empresaViewModel.cargarEmpresa(widget.empresaId);
      }
      final empresa = empresaViewModel.empresa;
      _companyNameController.text = empresa?.nombreComercial ?? '';
      _legalNameController.text = empresa?.razonSocial ?? '';
      _phoneController.text = empresa?.telefono ?? '';
      _addressController.text = empresa?.direccion ?? '';
      _emailController.text = empresa?.email ?? '';
      _logoUrlController.text = empresa?.logoUrl ?? '';
      _exchangeRateController.text =
          empresa?.tasaCambio?.toStringAsFixed(2) ?? '';
    });
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _legalNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _logoUrlController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }

  String _initials() {
    final parts = widget.userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.companyDataTitle),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserSettingsScreen(
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
                  controller: _logoUrlController,
                  label: t.logoUrlLabel,
                  keyboardType: TextInputType.url,
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
                      final empresaVM = context.read<EmpresaViewModel>();
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      double? tasaCambio;
                      if (_exchangeRateController.text.isNotEmpty) {
                        tasaCambio = double.tryParse(
                          _exchangeRateController.text.replaceAll(',', '.'),
                        );
                      }

                      final Empresa nuevaEmpresa = Empresa(
                        id: empresaVM.empresa?.id ?? '',
                        nombreComercial: _companyNameController.text.trim(),
                        razonSocial: _legalNameController.text.trim(),
                        telefono: _phoneController.text.trim(),
                        direccion: _addressController.text.trim(),
                        email: _emailController.text.trim(),
                        logoUrl: _logoUrlController.text.trim(),
                        tasaCambio: tasaCambio,
                      );

                      await empresaVM.guardar(nuevaEmpresa);

                      if (!mounted) return;

                      setState(() {
                        _savedCompany = nuevaEmpresa;
                      });

                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text(t.dataSavedMessage)),
                      );
                    },
                    child: Text(t.saveChangesButton),
                  ),
                ),
                if (_savedCompany != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    t.savedDataTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${t.commercialNamePrefix}${_savedCompany!.nombreComercial}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${t.legalNamePrefix}${_savedCompany!.razonSocial}',
                          ),
                          const SizedBox(height: 4),
                          Text('${t.phonePrefix}${_savedCompany!.telefono}'),
                          const SizedBox(height: 4),
                          Text('${t.addressPrefix}${_savedCompany!.direccion}'),
                          const SizedBox(height: 4),
                          Text('${t.emailPrefix}${_savedCompany!.email}'),
                          if (_savedCompany!.logoUrl.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('${t.logoUrlPrefix}${_savedCompany!.logoUrl}'),
                          ],
                          if (_savedCompany!.tasaCambio != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Tasa de Cambio: ${_savedCompany!.tasaCambio}',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
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
