// lib/widgets/cliente_mini_map_section.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'mini_map.dart';

class ClienteMiniMapSection extends StatelessWidget {
  const ClienteMiniMapSection({
    super.key,
    required this.clienteId,
    this.title = 'Ubicación del cliente',
    this.useCard = true,
  });

  final String clienteId;
  final String title;
  final bool useCard;

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance
        .collection('clientes')
        .doc(clienteId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          final content = const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
          return useCard
              ? Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: content,
                )
              : content;
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          final content = const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No se encontró el cliente.',
              style: TextStyle(color: Colors.red),
            ),
          );
          return useCard
              ? Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: content,
                )
              : content;
        }

        final data = snapshot.data!.data() ?? {};

        // Usamos los campos "latitud" y "longitud" de tu base de datos
        final latRaw = data['latitud'];
        final lngRaw = data['longitud'];

        if (latRaw == null || lngRaw == null) {
          final content = Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: const [
                Icon(Icons.location_off),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Este cliente no tiene latitud / longitud configuradas.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
          return useCard
              ? Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: content,
                )
              : content;
        }

        final lat = (latRaw as num).toDouble();
        final lng = (lngRaw as num).toDouble();

        final content = Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              MiniMap(lat: lat, lng: lng, height: 200),
            ],
          ),
        );

        if (!useCard) {
          return content;
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          clipBehavior: Clip.antiAlias,
          child: content,
        );
      },
    );
  }
}
