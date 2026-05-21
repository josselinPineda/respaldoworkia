import 'package:flutter/material.dart';
import '../models/cliente.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/utils/validators.dart';

/// Formulario reutilizable para crear o editar clientes.
///
/// Este widget encapsula los campos de entrada y la validación para
/// un cliente.  Se puede utilizar tanto en una página completa
/// como dentro de un diálogo.  Si se proporciona [initial], los
/// campos se inicializan con sus valores; de lo contrario se
/// muestran vacíos para crear un nuevo registro.  Al pulsar
/// "Guardar", se ejecuta [onSave] con la nueva instancia de
/// [Cliente].
class ClienteForm extends StatefulWidget {
  const ClienteForm({super.key, this.initial, required this.onSave});

  final Cliente? initial;
  final void Function(Cliente) onSave;

  @override
  State<ClienteForm> createState() => _ClienteFormState();
}

class _ClienteFormState extends State<ClienteForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _razonController;
  late TextEditingController _contactController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  String _selectedLanguage = 'es';
  bool _isActive = true;
  // Coordenada seleccionada para la ubicación del cliente.  Se actualiza
  // cuando el usuario selecciona una ubicación en el mapa modal.
  LatLng? _selectedLatLng;

  /// Ubicación actual del dispositivo.  Se obtiene al inicializar el
  /// formulario si se conceden permisos de localización.  Esta ubicación
  /// se utiliza como punto de partida en el modal del mapa si el usuario
  /// aún no ha seleccionado manualmente una posición.
  LatLng? _currentLocation;

  /// Controlador para el texto de búsqueda de direcciones dentro del
  /// modal de mapa.  Permite mostrar sugerencias de geocodificación al
  /// usuario para centrar el mapa en una dirección específica.
  final TextEditingController _searchController = TextEditingController();

  /// Determina la ubicación actual solicitando los permisos de
  /// geolocalización al usuario si aún no han sido concedidos.  Si
  /// se obtiene una posición válida se actualiza [_currentLocation].
  Future<void> _determineCurrentPosition() async {
    try {
      // Verificar si el servicio de ubicación está habilitado.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        // Los permisos están denegados permanentemente.

        return;
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        // Fallback si el GPS tarda o falla (usa última ubicación conocida)
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) return;
      final nonNullPos = pos;
      // Imprimir la ubicación actual en la terminal para depuración.

      setState(() {
        _currentLocation = LatLng(nonNullPos.latitude, nonNullPos.longitude);
      });
    } catch (e) {}
  }

  /// Abre un modal de mapa para seleccionar la ubicación del cliente.
  ///
  /// Este método solicita primero la ubicación actual del dispositivo
  /// antes de mostrar el mapa.  Al solicitar la ubicación se
  /// gestionan los permisos mediante [_determineCurrentPosition].  Si
  /// se concede el permiso, [_currentLocation] se actualiza con las
  /// coordenadas actuales y se utiliza como centro inicial del mapa.
  ///
  /// El modal incluye un buscador de direcciones, un mapa para
  /// seleccionar la ubicación con un toque, un botón para limpiar la
  /// selección y otro para guardar.  También se muestra un icono de
  /// cierre en la esquina superior derecha para descartar los cambios.
  Future<void> _openMapModal() async {
    // Asegurarse de tener la ubicación actual antes de abrir el modal.
    await _determineCurrentPosition();
    if (!mounted) return;

    // Resolver país actual (para sesgar búsquedas de direcciones).
    String? currentCountryName;
    String? currentIsoCountryCode;
    if (_currentLocation != null) {
      try {
        final placemarks = await geocoding.placemarkFromCoordinates(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
        );
        if (placemarks.isNotEmpty) {
          currentCountryName = placemarks.first.country;
          currentIsoCountryCode = placemarks.first.isoCountryCode;
        }
      } catch (_) {}
    }

    // Variables locales para la selección dentro del modal.
    LatLng? modalSelected = _selectedLatLng;
    GoogleMapController? mapController;
    // Mostrar el bottom sheet con scroll y sin permitir cerrar arrastrando.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        // StatefulBuilder permite actualizar el estado local del modal.
        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            // Construye la lista de sugerencias según el texto de búsqueda.
            List<geocoding.Location> suggestions = [];
            Future<void> _searchAddress() async {
              final query = _searchController.text.trim();
              if (query.isEmpty) {
                setStateModal(() {
                  suggestions = [];
                });
                return;
              }
              try {
                // Si no se incluyó país en el texto, sesgar a país actual.
                final qLower = query.toLowerCase();
                final hasCountry =
                    currentCountryName != null &&
                    currentCountryName!.trim().isNotEmpty &&
                    qLower.contains(currentCountryName!.toLowerCase());
                final effectiveQuery = (!hasCountry && currentCountryName != null)
                    ? '$query, $currentCountryName'
                    : query;

                // Locale para mejorar resultados (ej. es_HN).
                final locale = Localizations.localeOf(context);
                final localeIdentifier =
                    currentIsoCountryCode != null &&
                            currentIsoCountryCode!.trim().isNotEmpty
                        ? '${locale.languageCode}_${currentIsoCountryCode!}'
                        : (locale.countryCode != null
                            ? '${locale.languageCode}_${locale.countryCode}'
                            : locale.languageCode);

                final result = await geocoding.locationFromAddress(
                  effectiveQuery,
                  localeIdentifier: localeIdentifier,
                );
                setStateModal(() {
                  suggestions = result.take(6).toList();
                });
              } catch (_) {
                setStateModal(() {
                  suggestions = [];
                });
              }
            }

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    // Barra superior con título y botón cerrar.
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
                    // Campo de búsqueda de direcciones y botón buscar.
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
                              onSubmitted: (_) => _searchAddress(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.search),
                            tooltip: AppLocalizations.of(
                              context,
                            )!.searchTooltip,
                            onPressed: _searchAddress,
                          ),
                        ],
                      ),
                    ),
                    // Lista de sugerencias de geocodificación.
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
                                // Al seleccionar una sugerencia, centrar el mapa.
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
                      // Mostrar el mapa cuando no hay sugerencias.
                      Expanded(
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target:
                                modalSelected ??
                                _currentLocation ??
                                const LatLng(14.5, -87.2),
                            zoom: 15,
                          ),
                          onMapCreated: (ctrl) {
                            mapController = ctrl;
                          },
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: true,
                          markers: modalSelected != null
                              ? {
                                  Marker(
                                    markerId: const MarkerId(
                                      'modal_selected_location',
                                    ),
                                    position: modalSelected!,
                                  ),
                                }
                              : {},
                          onTap: (pos) {
                            setStateModal(() {
                              modalSelected = pos;
                            });
                          },
                        ),
                      ),
                    // Botones de acción: guardar posición seleccionada o limpiar.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Limpiar selección
                                setStateModal(() {
                                  modalSelected = null;
                                });
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
                                // Guardar selección y actualizar formulario.
                                setState(() {
                                  _selectedLatLng = modalSelected;
                                  if (_selectedLatLng != null) {
                                    _latController.text = _selectedLatLng!
                                        .latitude
                                        .toString();
                                    _lngController.text = _selectedLatLng!
                                        .longitude
                                        .toString();
                                  } else {
                                    _latController.text = '';
                                    _lngController.text = '';
                                  }
                                });
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

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _nameController = TextEditingController(text: c?.nombre ?? '');
    _razonController = TextEditingController(text: c?.razonSocial ?? '');
    _contactController = TextEditingController(text: c?.personaContacto ?? '');
    _phoneController = TextEditingController(text: c?.telefono ?? '');
    _emailController = TextEditingController(text: c?.correo ?? '');
    _addressController = TextEditingController(text: c?.direccion ?? '');
    _selectedLanguage = c?.idioma ?? 'es';
    _isActive = c?.activo ?? true;
    _latController = TextEditingController(
      text: c?.lat != null ? c!.lat.toString() : '',
    );
    _lngController = TextEditingController(
      text: c?.lng != null ? c!.lng.toString() : '',
    );
    // Inicializar la posición seleccionada a partir de las coordenadas
    // iniciales del cliente, si existen.
    if (c?.lat != null && c?.lng != null) {
      _selectedLatLng = LatLng(c!.lat!, c.lng!);
    }
    // Obtener la ubicación actual del dispositivo de forma asincrónica.
    _determineCurrentPosition();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _razonController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Cliente newClient;
    if (widget.initial != null) {
      newClient = widget.initial!.copyWith(
        nombre: _nameController.text.trim(),
        razonSocial: _razonController.text.trim(),
        personaContacto: _contactController.text.trim(),
        telefono: _phoneController.text.trim(),
        correo: _emailController.text.trim(),
        direccion: _addressController.text.trim(),
        idioma: _selectedLanguage,
        lat:
            _selectedLatLng?.latitude ??
            (_latController.text.trim().isNotEmpty
                ? double.tryParse(_latController.text.trim())
                : null),
        lng:
            _selectedLatLng?.longitude ??
            (_lngController.text.trim().isNotEmpty
                ? double.tryParse(_lngController.text.trim())
                : null),
      );
    } else {
      newClient = Cliente(
        id: '',
        nombre: _nameController.text.trim(),
        razonSocial: _razonController.text.trim(),
        personaContacto: _contactController.text.trim(),
        telefono: _phoneController.text.trim(),
        correo: _emailController.text.trim(),
        direccion: _addressController.text.trim(),
        idioma: _selectedLanguage,
        activo: _isActive,
        lat:
            _selectedLatLng?.latitude ??
            (_latController.text.trim().isNotEmpty
                ? double.tryParse(_latController.text.trim())
                : null),
        lng:
            _selectedLatLng?.longitude ??
            (_lngController.text.trim().isNotEmpty
                ? double.tryParse(_lngController.text.trim())
                : null),
      );
    }
    widget.onSave(newClient);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.nameLabel,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? AppLocalizations.of(context)!.requiredError
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _razonController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.socialReasonLabel,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.contactPersonLabel,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.phoneLabel,
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                final t = AppLocalizations.of(context)!;
                final v = value?.trim() ?? '';
                if (v.isEmpty) return t.requiredError;
                return Validators.isValidPhone(v) ? null : t.invalidPhoneError;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.emailLabel,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final t = AppLocalizations.of(context)!;
                final v = value?.trim() ?? '';
                if (v.isEmpty) return t.requiredError;
                return Validators.isValidEmail(v) ? null : t.invalidEmailError;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.addressLabel,
              ),
            ),
            const SizedBox(height: 12),

            // Botón para abrir el selector de ubicación.  Muestra la
            // coordenada seleccionada si existe.  Al pulsarlo se abre
            // un modal con el mapa y el buscador.
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
            ElevatedButton(
              onPressed: _handleSave,
              child: Text(AppLocalizations.of(context)!.saveButton),
            ),
          ],
        ),
      ),
    );
  }
}
