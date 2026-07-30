import 'package:flutter/material.dart';
import 'app_ar.dart';
import 'app_en.dart';

class AppLocalization {
  final Locale locale;
  late Map<String, String> _strings;

  AppLocalization(this.locale) {
    _strings = locale.languageCode == 'ar' ? arStrings : enStrings;
  }

  String translate(String key) => _strings[key] ?? key;

  static AppLocalization of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization)!;
  }

  static const LocalizationDelegate delegate = LocalizationDelegate();
}

class LocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  const LocalizationDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalization> load(Locale locale) async {
    return AppLocalization(locale);
  }

  @override
  bool shouldReload(LocalizationDelegate old) => false;
}
