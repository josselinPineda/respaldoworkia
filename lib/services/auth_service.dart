import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Servicio de autenticación que encapsula las operaciones comunes
/// de inicio de sesión y registro utilizando FirebaseAuth.  Este
/// servicio permite autenticar con correo y contraseña o con una
/// cuenta de Google, y proporciona un flujo de cambios de estado
/// para reaccionar a la autenticación.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Devuelve un flujo que emite el usuario actual cada vez que
  /// cambia el estado de autenticación.  Puede utilizarse para
  /// reaccionar a inicios de sesión y cierres de sesión en la UI.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Inicia sesión con correo electrónico y contraseña.  Devuelve
  /// el [User] autenticado en caso de éxito o lanza una
  /// [FirebaseAuthException] si las credenciales son inválidas.
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  /// Crea una cuenta nueva con correo electrónico y contraseña.  El
  /// correo y la contraseña se recortan antes de enviarlos a
  /// Firebase.  Devuelve el [User] creado en caso de éxito.
  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    return userCredential.user;
  }

  /// Cierra la sesión del usuario actual tanto de Firebase Auth
  /// como del proveedor de Google (si está conectado).  Ignora
  /// cualquier excepción de GoogleSignIn para asegurar que la
  /// sesión se termina correctamente.
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      await _googleSignIn.signOut();
    }
  }

  /// Inicia sesión con una cuenta de Google.  Obtiene los
  /// encabezados de autorización, crea un credential de Firebase y
  /// finalmente inicia sesión en Firebase Auth.  Lanza una
  /// [FirebaseAuthException] si ocurre un error durante el
  /// proceso.
  Future<User?> signInWithGoogle() async {
    try {
      // Comprobar si ya está inicializado GoogleSignIn; si no, se
      // inicializa automáticamente al crear la instancia.
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'CANCELLED',
          message: 'Inicio de sesión cancelado por el usuario.',
        );
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on GoogleSignInAccount catch (e) {
      throw FirebaseAuthException(
        code: 'GOOGLE_SIGN_IN_FAILED',
        message: e.toString(),
      );
    }
  }
}