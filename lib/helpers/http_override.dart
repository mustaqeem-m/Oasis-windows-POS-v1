import 'dart:io';

// WARNING: This is a security risk and should not be used in production.
// This override is intended for development purposes only, to bypass certificate
// validation for servers with self-signed certificates.
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
