import 'package:flutter/foundation.dart';

/// Provider to manage the current user session information.
/// This allows centralized access to `empresaId`, `userId`, and `userName`
/// throughout the application without passing them down the widget tree manually.
class UserSessionProvider extends ChangeNotifier {
  String _empresaId = '';
  String _userId = '';
  String _userName = '';
  String _userRole = '';

  String get empresaId => _empresaId;
  String get userId => _userId;
  String get userName => _userName;
  String get userRole => _userRole;

  void setSession({
    required String empresaId,
    required String userId,
    required String userName,
    required String userRole,
  }) {
    _empresaId = empresaId;
    _userId = userId;
    _userName = userName;
    _userRole = userRole;

    notifyListeners();
  }

  void clearSession() {
    _empresaId = '';
    _userId = '';
    _userName = '';
    _userRole = '';

    notifyListeners();
  }
}
