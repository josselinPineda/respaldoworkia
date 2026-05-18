import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('es'); // Default to Spanish

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!['es', 'en'].contains(locale.languageCode)) return;
    _locale = locale;
    notifyListeners();
  }

  void clearLocale() {
    _locale = const Locale('es');
    notifyListeners();
  }
}
