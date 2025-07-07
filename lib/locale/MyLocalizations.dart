import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations({required this.locale});

  // Helper method to keep the code in the widgets concise
  // Localizations are accessed using an InheritedWidget "of" syntax
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Static member to have a simple access to the delegate from the MaterialApp
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Map<String, String>? _localizedStrings;

  Future<bool> load() async {
    // Load the language JSON file from the "lang" folder
    String jsonString =
        await rootBundle.loadString('i18n/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  // This method will be called from every widget which needs a localized text
  String translate(String key) {
    return _localizedStrings![key]!;
  }
}

// LocalizationsDelegate is a factory for a set of localized resources
// In this case, the localized strings will be gotten in an AppLocalizations object
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  // This delegate instance will never change (it doesn't even have fields!)
  // It can provide a constant constructor.
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Include all of your supported language codes here
    return Config().locale.contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // AppLocalizations class is where the JSON loading actually runs
    AppLocalizations localizations = AppLocalizations(locale: locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

class AppLanguage extends ChangeNotifier {
  Locale _appLocale = Locale(Config().defaultLanguage, Config().defaultLanguage == 'en' ? 'US' : '');

  Locale get appLocal => _appLocale;

  fetchLocale() async {
    var prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('language_code');
    String? countryCode = prefs.getString('countryCode');

    if (languageCode == null) {
      // If no language is saved, use default and ensure English has 'US' country code
      languageCode = Config().defaultLanguage;
      countryCode = (languageCode == 'en') ? 'US' : '';
      _appLocale = Locale(languageCode, countryCode);
      await prefs.setString('language_code', languageCode);
      await prefs.setString('countryCode', countryCode);
    } else {
      // If language is saved, ensure English always gets 'US' country code
      if (languageCode == 'en') {
        countryCode = 'US';
        await prefs.setString('countryCode', 'US'); // Persist the fix
      } else if (countryCode == null) {
        countryCode = ''; // Default to empty string for other languages if null
      }
      _appLocale = Locale(languageCode, countryCode);
    }
  }

//call this to change language
  void changeLanguage(Locale type) async {
    var prefs = await SharedPreferences.getInstance();
    _appLocale = type;
    await prefs.setString('language_code', type.languageCode);
    await prefs.setString('countryCode', type.countryCode ?? '');
    notifyListeners();
  }
}
