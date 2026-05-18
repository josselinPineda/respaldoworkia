import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Mantener para LatLng, aceptable en VM si se usa como DTO
import 'package:workia/models/empresa.dart';
import 'package:workia/models/usuario.dart';
import 'package:workia/presentation/viewmodels/empresa_viewmodel.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';

/// ViewModel para el registro de empresas.
class RegisterCompanyViewModel extends ChangeNotifier {
  final EmpresaViewModel empresaVM;
  final UsuariosViewModel usuariosVM;

  RegisterCompanyViewModel({required this.empresaVM, required this.usuariosVM});

  // ========== ESTADO ==========
  bool _isLoading = false;
  String? _error;
  LatLng? _currentLocation;

  bool get isLoading => _isLoading;
  String? get error => _error;
  LatLng? get currentLocation => _currentLocation;

  // ========== ACCIONES ==========

  /// Genera un ID de empresa basado en el nombre.
  String generateCompanyId(String nombre) {
    if (nombre.isEmpty) return 'EMP_NUEVA_EMPRESA';

    String id = nombre.toUpperCase();
    id = id
        .replaceAll(RegExp(r'[ÁÀÄÂ]'), 'A')
        .replaceAll(RegExp(r'[ÉÈËÊ]'), 'E')
        .replaceAll(RegExp(r'[ÍÌÏÎ]'), 'I')
        .replaceAll(RegExp(r'[ÓÒÖÔ]'), 'O')
        .replaceAll(RegExp(r'[ÚÙÜÛ]'), 'U')
        .replaceAll(RegExp(r'[Ñ]'), 'N');
    id = id.replaceAll(RegExp(r'[^A-Z0-9\s]'), '');
    id = id.replaceAll(RegExp(r'\s+'), ' ');
    id = id.replaceAll(' ', '_');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'EMP_${id}_$timestamp';
  }

  /// Obtiene la ubicación actual.
  Future<void> determineCurrentPosition() async {
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
      _currentLocation = LatLng(pos.latitude, pos.longitude);
      notifyListeners();
    } catch (e) {
      // Ignorar errores de GPS silenciosamente o guardar en log
    }
  }

  /// Registra la empresa y el usuario administrador.
  Future<bool> registerCompanyAndUser({
    required Usuario usuario,
    required String password,
    required String nombre,
    required String nombreComercial,
    required String razonSocial,
    required String telefono,
    required String direccion,
    required String emailEmpresa,
    required LatLng? ubicacion,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Generar ID
      final empresaId = generateCompanyId(nombre);

      // 2. Crear modelo Empresa
      final nuevaEmpresa = Empresa(
        id: empresaId,
        nombre: nombre,
        nombreComercial: nombreComercial,
        razonSocial: razonSocial,
        telefono: telefono,
        direccion: direccion,
        email: emailEmpresa,
        latitud: ubicacion?.latitude,
        longitud: ubicacion?.longitude,
        creadoPor: 'USR_ADMIN', // Placeholder inicial
        actualizadoPor: 'USR_ADMIN',
        activo: true,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
      );

      // 3. Actualizar usuario con el ID de la empresa creada
      final usuarioFinal = usuario.copyWith(idEmpresa: empresaId);

      // 4. Registrar usuario (crea la cuenta en Firebase Auth y autentica la sesión)
      await usuariosVM.agregar(usuarioFinal, password);

      // 5. Guardar empresa (ya con sesión autenticada para cumplir reglas de Firestore)
      await empresaVM.agregar(nuevaEmpresa);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
