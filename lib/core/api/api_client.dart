import 'dart:io';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final CookieJar cookieJar = CookieJar();
  String? _authToken;
  String? get authToken => _authToken;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(CookieManager(cookieJar));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Dynamic baseUrl update in case user changed it in settings
          options.baseUrl = AppConfig.baseUrl;

          // Attach Bearer token and Cookie header if present
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
            options.headers['Cookie'] = 'gx_admin=$_authToken';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          extractAndSaveCookieFromHeaders(response.headers);
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          String message = 'An unexpected error occurred.';
          if (e.response != null && e.response?.data != null) {
            if (e.response?.data is Map && e.response?.data['error'] != null) {
              message = e.response?.data['error'].toString() ?? message;
            } else if (e.response?.data is String) {
              message = e.response?.data;
            }
          } else if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            message = 'Connection timed out. Please check your network.';
          } else if (e.error is SocketException) {
            message = 'Cannot reach the Groutix server. Please verify your connection.';
          }
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: ApiException(message, statusCode: e.response?.statusCode),
            ),
          );
        },
      ),
    );
  }

  Future<void> init() async {
    await loadTokenFromStorage();
  }

  void extractAndSaveCookieFromHeaders(Headers headers) {
    final setCookies = headers['set-cookie'];
    if (setCookies != null) {
      for (final rawCookie in setCookies) {
        final match = RegExp(r'gx_admin=([^;]+)').firstMatch(rawCookie);
        if (match != null) {
          final token = match.group(1);
          if (token != null && token.isNotEmpty) {
            setAuthToken(token);
            saveTokenToStorage(token);
            break;
          }
        }
      }
    }
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Future<void> saveTokenToStorage(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gx_auth_token', token);
  }

  Future<void> loadTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('gx_auth_token');
  }

  Future<void> clearAuth() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gx_auth_token');
    await prefs.remove('gx_user_role');
    await prefs.remove('gx_username');
    await cookieJar.deleteAll();
  }

  // Generic request helpers
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      throw ApiException(e.message ?? 'Request failed', statusCode: e.response?.statusCode);
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await dio.post(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      throw ApiException(e.message ?? 'Request failed', statusCode: e.response?.statusCode);
    }
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await dio.patch(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      throw ApiException(e.message ?? 'Request failed', statusCode: e.response?.statusCode);
    }
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await dio.delete(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error!;
      throw ApiException(e.message ?? 'Request failed', statusCode: e.response?.statusCode);
    }
  }
}
