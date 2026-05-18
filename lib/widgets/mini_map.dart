// lib/widgets/mini_map.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MiniMap extends StatelessWidget {
  const MiniMap({
    super.key,
    required this.lat,
    required this.lng,
    this.zoom = 15,
    this.height = 200,
    this.width,
    this.borderRadius = 16,
    this.showMarker = true,
  });

  final double lat;
  final double lng;
  final double zoom;
  final double height;
  final double? width;
  final double borderRadius;
  final bool showMarker;

  @override
  Widget build(BuildContext context) {
    final position = LatLng(lat, lng);

    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: position, zoom: zoom),
          gestureRecognizers: {
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
          markers: showMarker
              ? {
                  Marker(
                    markerId: const MarkerId('mini_map_marker'),
                    position: position,
                  ),
                }
              : <Marker>{},
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          myLocationEnabled: false,
          compassEnabled: false,
          tiltGesturesEnabled: true,
          rotateGesturesEnabled: true,
          mapToolbarEnabled: false,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
        ),
      ),
    );
  }
}
