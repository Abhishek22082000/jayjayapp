// App-wide compile-time configuration.
//
// Pass these at build/run time via --dart-define:
//
//   flutter run \
//     --dart-define=API_BASE_URL=https://your-app.vercel.app \
//     --dart-define=API_TOKEN=optional-shared-secret
//
// API_BASE_URL is required. API_TOKEN must match the same env var set on
// Vercel; leave both unset on the backend AND in the app to run without
// auth (single-user prototype only).
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const String apiToken =
      String.fromEnvironment('API_TOKEN', defaultValue: '');

  static bool get hasBaseUrl => apiBaseUrl.isNotEmpty;
}
