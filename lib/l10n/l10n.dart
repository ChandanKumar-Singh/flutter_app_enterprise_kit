import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

export 'package:flutter_localizations/flutter_localizations.dart';

/// Stub localization class — replace with gen-l10n output once ARB files exist.
/// Run: flutter gen-l10n
class AppLocalizations {
  static final List<LocalizationsDelegate> localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
    Locale('fr'),
  ];
}
