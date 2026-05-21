import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workia/presentation/viewmodels/empresa_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';
import 'package:workia/models/empresa.dart';
import 'package:workia/models/usuario.dart';
import 'package:workia/l10n/app_localizations.dart';

class RegisterCompanyPage extends StatefulWidget {
  final Usuario usuario;
  final String? password;
  final String? prefillCompanyName;
  final String? prefillCommercialName;

  const RegisterCompanyPage({
    super.key,
    required this.usuario,
    this.password,
    this.prefillCompanyName,
    this.prefillCommercialName,
  });

  @override
  State<RegisterCompanyPage> createState() => _RegisterCompanyPageState();
}

class _RegisterCompanyPageState extends State<RegisterCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _nombreComercialController = TextEditingController();
  final _razonSocialController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _emailController = TextEditingController();
  final _searchController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  LatLng? _selectedLatLng;
  LatLng? _currentLocation;
  bool _didComplete = false;
  bool _isRollingBack = false;

  @override
  void initState() {
    super.initState();
    // No prefilling company name from account name.
    _nombreController.text = '';
    _nombreComercialController.text = widget.prefillCommercialName?.trim() ?? '';
    _determineCurrentPosition();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _nombreComercialController.dispose();
    _razonSocialController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Genera un ID legible para la empresa basado en el nombre
  /// Formato: EMP_NOMBRE_EMPRESA (en mayúsculas, sin espacios ni caracteres especiales)
  String _generateCompanyId(String nombre) {
    if (nombre.isEmpty) return 'EMP_NUEVA_EMPRESA';

    // Convertir a mayúsculas y reemplazar espacios por guiones bajos
    String id = nombre.toUpperCase();

    // Remover acentos y caracteres especiales
    id = id
        .replaceAll(RegExp(r'[ÁÀÄÂ]'), 'A')
        .replaceAll(RegExp(r'[ÉÈËÊ]'), 'E')
        .replaceAll(RegExp(r'[ÍÌÏÎ]'), 'I')
        .replaceAll(RegExp(r'[ÓÒÖÔ]'), 'O')
        .replaceAll(RegExp(r'[ÚÙÜÛ]'), 'U')
        .replaceAll(RegExp(r'[Ñ]'), 'N');

    // Mantener solo letras, números y espacios
    id = id.replaceAll(RegExp(r'[^A-Z0-9\s]'), '');

    // Reemplazar espacios múltiples por uno solo
    id = id.replaceAll(RegExp(r'\s+'), ' ');

    // Reemplazar espacios por guiones bajos
    id = id.replaceAll(' ', '_');

    // Agregar prefijo y timestamp para unicidad
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'EMP_${id}_$timestamp';
  }

  Future<void> _determineCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
      });
    } catch (e) {}
  }

  Future<void> _openMapModal() async {
    await _determineCurrentPosition();
    if (!mounted) return;
    LatLng? modalSelected = _selectedLatLng;
    GoogleMapController? mapController;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            List<geocoding.Location> suggestions = [];

            Future<void> searchAddress() async {
              final query = _searchController.text.trim();
              if (query.isEmpty) {
                setStateModal(() => suggestions = []);
                return;
              }
              try {
                final result = await geocoding.locationFromAddress(query);
                setStateModal(() => suggestions = result);
              } catch (_) {
                setStateModal(() => suggestions = []);
              }
            }

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.selectLocationTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(
                                  context,
                                )!.searchAddressHint,
                                prefixIcon: const Icon(Icons.search),
                              ),
                              onSubmitted: (_) => searchAddress(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.search),
                            tooltip: AppLocalizations.of(
                              context,
                            )!.searchTooltip,
                            onPressed: searchAddress,
                          ),
                        ],
                      ),
                    ),
                    if (suggestions.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          itemCount: suggestions.length,
                          itemBuilder: (context, index) {
                            final loc = suggestions[index];
                            return ListTile(
                              leading: const Icon(Icons.location_on),
                              title: Text(
                                'Lat: ${loc.latitude.toStringAsFixed(5)}, Lng: ${loc.longitude.toStringAsFixed(5)}',
                              ),
                              onTap: () {
                                final pos = LatLng(loc.latitude, loc.longitude);
                                setStateModal(() {
                                  modalSelected = pos;
                                  suggestions = [];
                                  _searchController.clear();
                                });
                                mapController?.animateCamera(
                                  CameraUpdate.newLatLng(pos),
                                );
                              },
                            );
                          },
                        ),
                      )
                    else
                      Expanded(
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target:
                                modalSelected ??
                                _currentLocation ??
                                const LatLng(14.0, -90.0),
                            zoom: 15,
                          ),
                          onMapCreated: (ctrl) => mapController = ctrl,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: true,
                          markers: modalSelected != null
                              ? {
                                  Marker(
                                    markerId: const MarkerId(
                                      'selected_location',
                                    ),
                                    position: modalSelected!,
                                  ),
                                }
                              : {},
                          onTap: (pos) {
                            setStateModal(() => modalSelected = pos);
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setStateModal(() => modalSelected = null);
                              },
                              child: Text(
                                AppLocalizations.of(context)!.clearButton,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() => _selectedLatLng = modalSelected);
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                AppLocalizations.of(context)!.saveButton,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final empresaVM = context.read<EmpresaViewModel>();
    final usuariosVM = context.read<UsuariosViewModel>();

    try {
      // Generar ID legible para la empresa
      final empresaId = _generateCompanyId(_nombreController.text.trim());

      // Crear empresa con ID personalizado
      final currentUidForAudit = FirebaseAuth.instance.currentUser?.uid ?? '';
      final auditUserId =
          currentUidForAudit.isNotEmpty ? currentUidForAudit : widget.usuario.id;

      final nuevaEmpresa = Empresa(
        id: empresaId,
        nombre: _nombreController.text.trim(),
        nombreComercial: _nombreComercialController.text.trim(),
        razonSocial: _razonSocialController.text.trim(),
        telefono: _telefonoController.text.trim(),
        direccion: _direccionController.text.trim(),
        email: _emailController.text.trim(),
        latitud: _selectedLatLng?.latitude,
        longitud: _selectedLatLng?.longitude,
        creadoPor: auditUserId,
        actualizadoPor: auditUserId,
        activo: true,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
      );

      await empresaVM.agregar(nuevaEmpresa);

      // Actualizar usuario con empresaId
      final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final usuarioFinal = widget.usuario.copyWith(
        idEmpresa: empresaId,
        authUid: currentUid.isNotEmpty ? currentUid : widget.usuario.authUid,
      );

      // Crear usuario solo si aÃºn no fue creado en Auth (flujo legacy).
      if (widget.password != null && widget.password!.isNotEmpty) {
        await usuariosVM.agregar(usuarioFinal, widget.password!);
      } else {
        // Si el usuario ya existe, solo actualizamos su empresaId.
        await usuariosVM.actualizar(usuarioFinal);
      }

      if (!mounted) return;

      _didComplete = true;
      context.go('/login');
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.accountCreatedSuccessMessage,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'email-already-in-use') {
          _error = AppLocalizations.of(context)!.emailAlreadyRegisteredError;
        } else {
          _error = e.message ?? e.code;
        }
        _isLoading = false;
      });
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.message == 'email-already-in-use') {
          _error = AppLocalizations.of(context)!.emailAlreadyRegisteredError;
        } else {
          _error = e.message ?? 'Error';
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _rollbackAuthUserIfNeeded() async {
    // Solo aplica al flujo donde el usuario se creÃ³ en el paso anterior (password == null).
    if (_didComplete) return;
    if (widget.password != null && widget.password!.isNotEmpty) return;
    if (_isRollingBack) return;
    _isRollingBack = true;
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user != null) {
        await user.delete();
      }
      await auth.signOut();
    } catch (_) {
      // Si falla (por re-auth), al menos cerramos sesiÃ³n para no dejar al usuario logueado.
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    } finally {
      _isRollingBack = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _rollbackAuthUserIfNeeded();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.registerCompanyTitle),
        ),
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
                      AppLocalizations.of(context)!.companyDataTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.nameLabel,
                      ),
                      validator: (v) => v?.isEmpty == true
                          ? AppLocalizations.of(context)!.requiredError
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nombreComercialController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        )!.commercialNameLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _razonSocialController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        )!.socialReasonLabel,
                      ),
                      minLines: 2,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _telefonoController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.phoneLabel,
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _direccionController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.addressLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        )!.companyEmailLabel,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _openMapModal,
                      icon: const Icon(Icons.location_on),
                      label: Text(
                        _selectedLatLng == null
                            ? AppLocalizations.of(context)!.selectLocationTitle
                            : '${AppLocalizations.of(context)!.locationPrefix}${_selectedLatLng!.latitude.toStringAsFixed(5)}, ${_selectedLatLng!.longitude.toStringAsFixed(5)}',
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text(
                              AppLocalizations.of(
                                context,
                              )!.registerAndFinishButton,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
