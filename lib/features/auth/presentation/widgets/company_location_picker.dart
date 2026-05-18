import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:workia/l10n/app_localizations.dart';

/// Widget modal para seleccionar ubicación en el mapa.
class CompanyLocationPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final LatLng? userLocation;
  final Function(LatLng) onLocationSelected;

  const CompanyLocationPicker({
    super.key,
    this.initialLocation,
    this.userLocation,
    required this.onLocationSelected,
  });

  @override
  State<CompanyLocationPicker> createState() => _CompanyLocationPickerState();
}

class _CompanyLocationPickerState extends State<CompanyLocationPicker> {
  final TextEditingController _searchController = TextEditingController();
  LatLng? _markerLocation;
  List<geocoding.Location> _suggestions = [];
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _markerLocation = widget.initialLocation;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    try {
      final result = await geocoding.locationFromAddress(query);
      setState(() => _suggestions = result);
    } catch (_) {
      setState(() => _suggestions = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final initialTarget =
        _markerLocation ?? widget.userLocation ?? const LatLng(14.0, -90.0);

    return SafeArea(
      child: SizedBox(
        height:
            MediaQuery.of(context).size.height * 0.75, // Más alto para mejor UX
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.selectLocationTitle,
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

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: t.searchAddressHint,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      ),
                      onSubmitted: (_) => _searchAddress(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: t.searchTooltip,
                    onPressed: _searchAddress,
                  ),
                ],
              ),
            ),

            // Suggestions List or Map
            if (_suggestions.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final loc = _suggestions[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(
                        'Lat: ${loc.latitude.toStringAsFixed(5)}, Lng: ${loc.longitude.toStringAsFixed(5)}',
                      ),
                      onTap: () {
                        final pos = LatLng(loc.latitude, loc.longitude);
                        setState(() {
                          _markerLocation = pos;
                          _suggestions = []; // Close suggestions
                          _searchController.clear();
                        });
                        _mapController?.animateCamera(
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
                    target: initialTarget,
                    zoom: 15,
                  ),
                  onMapCreated: (ctrl) => _mapController = ctrl,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  markers: _markerLocation != null
                      ? {
                          Marker(
                            markerId: const MarkerId('selected'),
                            position: _markerLocation!,
                          ),
                        }
                      : {},
                  onTap: (pos) => setState(() => _markerLocation = pos),
                ),
              ),

            // Footer Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _markerLocation = null),
                      child: Text(t.clearButton),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _markerLocation != null
                          ? () => widget.onLocationSelected(_markerLocation!)
                          : null,
                      child: Text(t.saveButton),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
