import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UserRole get currentRole => _currentUser?.role ?? UserRole.manager;

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('gx_auth_token');
    final roleStr = prefs.getString('gx_user_role');
    final username = prefs.getString('gx_username');
    final name = prefs.getString('gx_name');

    // Only auto-login if a valid token is present
    if (username != null && username.isNotEmpty && token != null && token.isNotEmpty) {
      _api.setAuthToken(token);
      _currentUser = UserModel(
        username: username,
        name: name,
        role: UserRole.fromString(roleStr),
        token: token,
      );
      notifyListeners();
      return true;
    }
    // Clean up partial session if token is missing
    await logout();
    return false;
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.post(
        ApiEndpoints.login,
        data: {
          'username': username.trim(),
          'password': password,
        },
      );

      // Extract gx_admin cookie from response headers
      _api.extractAndSaveCookieFromHeaders(response.headers);

      final data = response.data;
      if (data != null && (data['ok'] == true || data['role'] != null)) {
        final roleStr = data['role']?.toString() ?? 'manager';
        final token = data['token']?.toString() ?? _api.authToken;
        final userObj = data['user'];
        final name = userObj is Map ? userObj['name']?.toString() : null;

        _currentUser = UserModel(
          username: username.trim(),
          name: name,
          role: UserRole.fromString(roleStr),
          token: token,
        );

        if (token != null && token.isNotEmpty) {
          await _api.saveTokenToStorage(token);
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('gx_username', username.trim());
        await prefs.setString('gx_user_role', roleStr);
        if (name != null) await prefs.setString('gx_name', name);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid username or password.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiEndpoints.logout);
    } catch (_) {}
    await _api.clearAuth();
    _currentUser = null;
    notifyListeners();
  }

  // Developer & manager utility to preview different role experiences instantly
  void switchRoleForTesting(UserRole role) {
    if (_currentUser != null) {
      _currentUser = UserModel(
        username: _currentUser!.username,
        name: _currentUser!.name,
        role: role,
        token: _currentUser!.token,
      );
      notifyListeners();
    }
  }
}
