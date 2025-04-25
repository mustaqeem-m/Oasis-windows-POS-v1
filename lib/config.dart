import 'dart:ui';
//import 'package:google_maps_flutter/google_maps_flutter.dart';

class Config {

  static String baseUrl = 'https://app.oasissoft.in/';
  static int? userId;
       String clientId = '3',
        clientSecret = '	qKIx4kp8Xkd97PsVPT6prVmCmBwJlSzKeLtLor2s',
        copyright = '\u00a9',
        appName = 'Oasis POS',
        version = 'V 6.7',
      splashScreen = '${Config.baseUrl}uploads/mobile/welcome.jpg',
      loginScreen = '${Config.baseUrl}uploads/mobile/login.jpg',
      noDataImage = '${Config.baseUrl}uploads/mobile/no_data.jpg',
      defaultBusinessImage = '${Config.baseUrl}uploads/business_default.jpg';
  final bool syncCallLog = false, showRegister = false, showFieldForce = false;

  //quantity precision       //currency precision   //call_log sync duration
  static int quantityPrecision = 2,
      currencyPrecision = 2,
      callLogSyncDuration = 10;

  //List of locale language code
  List locale = ['en', 'ar', 'de', 'fr', 'es','tr','id','my', 'ku'];
  String defaultLanguage = 'en';

  //List of locales included
  List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('ar', ''),
    Locale('de', ''),
    Locale('fr', ''),
    Locale('es', ''),
    Locale('tr', ''),
    Locale('id', ''),
    Locale('my', ''),
    Locale('ku', '')
  ];

  //dropdown items for changing language
  List<Map<String, dynamic>> lang = [
    {'languageCode': 'en', 'countryCode': 'US', 'name': 'English'},
    {'languageCode': 'ar', 'countryCode': '', 'name': 'العربي'},
    {'languageCode': 'de', 'countryCode': '', 'name': 'Deutsche'},
    {'languageCode': 'fr', 'countryCode': '', 'name': 'Français'},
    {'languageCode': 'es', 'countryCode': '', 'name': 'Español'},
    {'languageCode': 'tr', 'countryCode': '', 'name': 'Türkçe'},
    {'languageCode': 'id', 'countryCode': '', 'name': 'Indonesian'},
    {'languageCode': 'my', 'countryCode': '', 'name': 'မြန်မာ'},
    {'languageCode': 'ku', 'countryCode': '', 'name': 'کوردی'}
  ];

  //final initialPosition = LatLng(20.46752985010792, 82.92005813910752);
  // final String googleAPIKey = 'AIzaSyDW5xTAzWCNsaBvLjA2BIVkeYhmBjXILQM';
}
