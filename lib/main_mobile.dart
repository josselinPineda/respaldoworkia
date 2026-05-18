import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'firebase_options.dart';
import 'main.dart'; // Importamos STGFApp desde main.dart o donde esté definido el root de tu app.

/// Entry point específico para plataformas móviles (iOS y Android).
/// De acuerdo a la regla "Entry points over runtime conditionals", aquí se
/// deben registrar todas las dependencias y configuraciones que son exclusivas
/// para dispositivos móviles.
Future<void> main() async {
  // 1. Inicialización del framework
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicialización de Firebase (DefaultFirebaseOptions.currentPlatform resolverá iOS/Android correctamente)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Configuración de servicios (ej. Cloud Functions)
  FirebaseFunctions.instanceFor(region: 'us-central1');

  // 4. (Opcional) Inyección de dependencias exclusivas para móvil (iOS/Android)
  // Aquí puedes configurar tus repositorios locales que usen sqlite, secure_storage, etc.
  // setupMobileDependencies();

  // 5. Ejecución de la aplicación
  runApp(const STGFApp());
}
