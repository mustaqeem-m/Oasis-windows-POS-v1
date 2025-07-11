// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// // import 'package:flutter_kurdish_localization/kurdish_cupertino_localization_delegate.dart';
// // import 'package:flutter_kurdish_localization/kurdish_material_localization_delegate.dart';
// // import 'package:flutter_kurdish_localization/kurdish_widget_localization_delegate.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:provider/provider.dart';

// import 'config.dart';
// import 'helpers/AppTheme.dart';
// import 'helpers/routes.dart';
// import 'locale/MyLocalizations.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   //orientation setting
//   SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//   AppLanguage appLanguage = AppLanguage();
//   await appLanguage.fetchLocale();
//   runApp(MyApp(
//     appLanguage: appLanguage,
//   ));
// }

// class MyApp extends StatelessWidget {
//   final AppLanguage? appLanguage;

//   MyApp({this.appLanguage});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider<AppLanguage>(
//       create: (_) => appLanguage!,
//       child: Consumer<AppLanguage>(builder: (context, model, child) {
//         return MaterialApp(
//           routes: Routes.generateRoute(),
//           initialRoute: '/splash',
//           debugShowCheckedModeBanner: false,
//           //Turns on a little "DEBUG" banner in checked mode to indicate that the app is in checked mode.
//           theme: AppTheme.getThemeFromThemeMode(1),
//           locale: model.appLocal,
//           supportedLocales: Config().supportedLocales,
//           localizationsDelegates: [
//             AppLocalizations.delegate,
//             // KurdishMaterialLocalizations.delegate,
//             // KurdishWidgetLocalizations.delegate,
//             // KurdishCupertinoLocalizations.delegate,
//             GlobalMaterialLocalizations.delegate,
//             GlobalCupertinoLocalizations.delegate,
//             GlobalWidgetsLocalizations.delegate,
//           ],
//         );
//       }),
//     );
//   }
// }

import 'dart:io'; // <-- required for Platform checks
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // <-- required for desktop

import 'config.dart';
import 'helpers/AppTheme.dart';
import 'helpers/routes.dart';
import 'locale/MyLocalizations.dart';
import 'providers/home_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ FFI Initialization for Windows/Linux/macOS
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // ✅ Lock portrait only on mobile
  if (Platform.isAndroid || Platform.isIOS) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  AppLanguage appLanguage = AppLanguage();
  await appLanguage.fetchLocale();

  runApp(MyApp(appLanguage: appLanguage));
}

class MyApp extends StatelessWidget {
  final AppLanguage? appLanguage;

  const MyApp({super.key, this.appLanguage});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppLanguage>(create: (_) => appLanguage!),
        ChangeNotifierProvider<HomeProvider>(create: (_) => HomeProvider()),
      ],
      child: Consumer<AppLanguage>(
        builder: (context, model, child) {
          int themeType = AppTheme.themeLight;
          return MaterialApp(
            routes: Routes.generateRoute(),
            initialRoute: '/splash',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getThemeFromThemeMode(themeType),
            locale: model.appLocal,
            supportedLocales: Config().supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              // KurdishMaterialLocalizations.delegate,
              // KurdishWidgetLocalizations.delegate,
              // KurdishCupertinoLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}
