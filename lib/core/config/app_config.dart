import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String keyBaseUrl = 'groutix_base_url';
  
  // Default to live production server, or easily switchable to local dev
  static const String defaultProductionUrl = 'https://groutix.com';
  static const String defaultLocalUrl = 'http://10.0.2.2:3000'; // Android emulator to host
  static const String defaultLocalDesktopUrl = 'http://localhost:3000';

  static String _baseUrl = defaultProductionUrl;

  static String get baseUrl => _baseUrl;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(keyBaseUrl);
    // Migrate old www.groutix.com cache if present
    if (saved == null || saved.contains('www.groutix.com')) {
      _baseUrl = defaultProductionUrl;
      await prefs.setString(keyBaseUrl, defaultProductionUrl);
    } else {
      _baseUrl = saved;
    }
  }

  static Future<void> setBaseUrl(String url) async {
    String cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    _baseUrl = cleanUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyBaseUrl, cleanUrl);
  }

  static bool get isProduction => _baseUrl.contains('groutix.com');
}
