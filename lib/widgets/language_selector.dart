import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import 'package:workia/l10n/app_localizations.dart';
import 'package:workia/presentation/providers/user_session_provider.dart';
import 'package:workia/presentation/viewmodels/usuarios_viewmodel.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);

    // Mapa de códigos de idioma a sus nombres traducidos.  Utiliza
    // AppLocalizations para obtener las traducciones de los nombres
    // de los idiomas.  Las claves corresponden al código ISO de
    // idioma que se utiliza en Locale(languageCode).
    final Map<String, String> languages = {
      'es': AppLocalizations.of(context)!.spanishLanguage,
      'en': AppLocalizations.of(context)!.englishLanguage,
    };

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withOpacity(0.9),
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: provider.locale.languageCode,
            icon: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(
                Icons.language,
                color: Theme.of(context).primaryColor,
              ),
            ),
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            dropdownColor: Colors.white,
            onChanged: (String? newValue) {
              if (newValue != null &&
                  newValue != provider.locale.languageCode) {
                provider.setLocale(Locale(newValue));

                // Persistir el cambio si hay un usuario autenticado
                final userSession = Provider.of<UserSessionProvider>(
                  context,
                  listen: false,
                );
                if (userSession.userId.isNotEmpty) {
                  Provider.of<UsuariosViewModel>(
                    context,
                    listen: false,
                  ).actualizarIdioma(userSession.userId, newValue);
                }
              }
            },
            items: languages.entries
                .map(
                  (entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Text(entry.value)],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
