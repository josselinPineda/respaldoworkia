import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/repositories/usuario_repository.dart';
import '../../models/usuario.dart';

/// Implementación de [UsuarioRepository] que utiliza Firebase Firestore
/// para almacenar usuarios y sus contraseñas.  Cada documento en la
/// colección `usuarios` contiene los datos del usuario y un campo
/// adicional `password` para la contraseña sin cifrar.  En un
/// entorno de producción se debería usar un algoritmo de hashing.
class UsuarioRepositoryFirestore implements UsuarioRepository {
  final CollectionReference<Map<String, dynamic>> _coleccion;
  final FirebaseAuth _auth;

  UsuarioRepositoryFirestore({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _coleccion = (firestore ?? FirebaseFirestore.instance).collection(
        'usuarios',
      ),
      _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<List<Usuario>> obtenerUsuarios(String empresaId) async {
    final snapshot = await _coleccion
        .where('empresaId', isEqualTo: empresaId)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Usuario.fromJson({...data, 'id': doc.id});
    }).toList();
  }

  @override
  Future<void> agregarUsuario(Usuario usuario, String password) async {
    // Crear la cuenta en Firebase Auth primero.  Esto registrará al usuario
    // utilizando el correo electrónico y la contraseña proporcionados.  Si
    // existe un error de autenticación (p.ej. correo ya registrado) se
    // propagará como excepción.  Tras crear la cuenta obtenemos el uid
    // generado por Firebase y lo almacenamos en el documento del usuario.
    final UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: usuario.email.trim(),
      password: password,
    );
    final uid = cred.user?.uid ?? '';
    // Preparar el mapa de datos para Firestore.  Tomamos el mapa del
    // modelo y agregamos timestamps y el uid de autenticación.  No se
    // almacena la contraseña en Firestore.
    // Generar un código legible (similar al ID histórico `USR_NOMBRE_timestamp`).
    final data = usuario.copyWith(authUid: uid).toJson();
    // Generar un identificador personalizado para el usuario basado en su
    // nombre.  Si ya se proporcionó un id se utiliza ese valor.  Esto
    // permite conservar la convención "USR_NOMBRE" para los IDs
    // lógicos mientras se mantiene la referencia al uid de Firebase.
    // Crear un identificador lógico basado en el nombre.  Eliminamos
    // espacios y los reemplazamos con guiones bajos para generar un
    // ID legible.  Si ya se proporcionó un ID se utiliza tal cual.
    final String nameForId = usuario.nombre.replaceAll(RegExp(r'\\s+'), '_');
    final String id = usuario.id.isNotEmpty
        ? usuario.id
        : 'USR_${nameForId.toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}';
    // Establecer fechas de creación y actualización
    final fechaCreacion = usuario.fechaCreacion ?? DateTime.now();
    data['fechaCreacion'] = Timestamp.fromDate(fechaCreacion);
    data['fechaActualizacion'] = Timestamp.fromDate(
      usuario.fechaActualizacion ?? fechaCreacion,
    );
    await _coleccion.doc(id).set(data);
  }

  @override
  Future<void> actualizarUsuario(Usuario usuario) async {

    final data = usuario.toJson();
    if (usuario.fechaCreacion != null) {
      data['fechaCreacion'] = Timestamp.fromDate(usuario.fechaCreacion!);
    }
    data['fechaActualizacion'] = Timestamp.fromDate(
      usuario.fechaActualizacion ?? DateTime.now(),
    );
    // No actualizamos la contraseña aquí
    // Intento principal: actualizar por ID de documento.
    if (usuario.id.isNotEmpty) {
      try {
        await _coleccion.doc(usuario.id).set(data, SetOptions(merge: true));
        return;
      } catch (_) {
        // Si no existe el doc con ese ID, hacemos fallback.
      }
    }

    // Fallback 1: buscar por authUid.
    if (usuario.authUid.isNotEmpty) {
      final snap = await _coleccion
          .where('authUid', isEqualTo: usuario.authUid)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        await _coleccion
            .doc(snap.docs.first.id)
            .set(data, SetOptions(merge: true));
        return;
      }
    }

    // Fallback 2: buscar por email.
    final email = usuario.email.trim();
    if (email.isNotEmpty) {
      final snap =
          await _coleccion.where('email', isEqualTo: email).limit(1).get();
      if (snap.docs.isNotEmpty) {
        await _coleccion
            .doc(snap.docs.first.id)
            .set(data, SetOptions(merge: true));
        return;
      }
    }

    throw StateError('usuario-not-found');
  }

  @override
  Future<void> inactivarUsuario(String id, String actualizadoPor) async {
    if (id.isEmpty) return;
    await _coleccion.doc(id).update({
      'activo': false,
      'actualizadoPor': actualizadoPor,
      'fechaActualizacion': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<Usuario?> login(String email, String password) async {
    try {
      // Autenticar mediante Firebase Auth.  Si la contraseña es
      // incorrecta se lanzará una excepción.
      final UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid == null) return null;
      // Buscar el documento de usuario asociado al uid de autenticación.
      // Primero intentamos usar el campo "authUid" que se asigna a
      // partir del uid de Firebase.  Esto cubre usuarios creados con
      // las versiones nuevas del sistema.  Si no se encuentra ningún
      // documento, hacemos un segundo intento filtrando por el correo
      // electrónico (campo "email").  Este fallback mantiene
      // compatibilidad con documentos anteriores que no tenían el campo
      // authUid y que se identifican únicamente por el correo.
      final snapshot = await _coleccion
          .where('authUid', isEqualTo: uid)
          .limit(1)
          .get();
      DocumentSnapshot<Map<String, dynamic>>? doc;
      if (snapshot.docs.isNotEmpty) {
        doc = snapshot.docs.first;
      } else {
        // Intentar buscar por email en caso de que authUid no exista
        final snapshotEmail = await _coleccion
            .where('email', isEqualTo: email.trim())
            .limit(1)
            .get();
        if (snapshotEmail.docs.isNotEmpty) {
          doc = snapshotEmail.docs.first;
        }
      }
      if (doc == null) {
        return null;
      }
      final data = doc.data();
      return Usuario.fromJson({...data!, 'id': doc.id});
    } on FirebaseAuthException {
      // Si hay un error de autenticación retornamos null para indicar
      // credenciales inválidas.
      return null;
    }
  }

  @override
  Future<bool> emailExistente(String email) async {
    // A partir de firebase_auth 6.0.0 ya no es posible
    // enumerar métodos de inicio de sesión asociados a un correo por
    // razones de seguridad【791852485324381†L90-L100】.  En su lugar, consultamos
    // directamente nuestra colección de usuarios en Firestore para
    // comprobar si hay algún documento con el mismo correo.  Esto
    // evita depender de un método eliminado y mantiene la verificación
    // dentro de nuestra propia base de datos.
    // Algunos documentos antiguos pueden almacenar el correo bajo la
    // clave "correo".  Por tanto, comprobamos ambas claves para
    // asegurarnos de que no existan duplicados.
    final snap1 = await _coleccion
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    if (snap1.docs.isNotEmpty) return true;
    final snap2 = await _coleccion
        .where('correo', isEqualTo: email.trim())
        .limit(1)
        .get();
    return snap2.docs.isNotEmpty;
  }
}
