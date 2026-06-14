class AppConstants {
  static const String appName = 'VishalOS';
  static const String appTagline = 'Your AI Life Operating System';
  static const String appVersion = '1.0.0';

  // API
  static const String defaultBaseUrl = 'https://vishalos-backend.onrender.com';
  static const String apiVersion = '/api/v1';
  static const int connectTimeout = 60000;
  static const int receiveTimeout = 60000;

  // Hive Boxes
  static const String settingsBox = 'settings';

  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserEmail = 'user_email';
  static const String keyThemeMode = 'theme_mode';
  static const String keyColorScheme = 'color_scheme';
  static const String keyBaseUrl = 'base_url';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyPinEnabled = 'pin_enabled';

  // Pagination
  static const int defaultPageSize = 20;
  static const int taskPageSize = 50;

  // Durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 600);
  static const Duration snackDuration = Duration(seconds: 3);

  // Sizes
  static const double borderRadius = 16.0;
  static const double cardRadius = 20.0;
  static const double buttonRadius = 12.0;
  static const double spacing = 16.0;
  static const double spacingSmall = 8.0;
  static const double spacingLarge = 24.0;
  static const double spacingXL = 32.0;

  // Nav
  static const List<String> mainNavRoutes = [
    '/dashboard',
    '/tasks',
    '/notes',
    '/ai',
    '/profile',
  ];
}
