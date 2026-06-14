import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lifeos/core/constants/app_constants.dart';

final _storage = FlutterSecureStorage();

final baseUrlProvider = FutureProvider<String>((ref) async {
  final stored = await _storage.read(key: AppConstants.keyBaseUrl);
  return stored ?? AppConstants.defaultBaseUrl;
});

final dioProvider = Provider<Dio>((ref) {
  // Read stored base URL synchronously from cache; fallback to default
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.defaultBaseUrl,
    connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
    receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(AuthInterceptor(dio));
  return dio;
});

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();

  AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Set base URL from storage on each request
    final storedUrl = await _storage.read(key: AppConstants.keyBaseUrl);
    if (storedUrl != null && storedUrl.isNotEmpty) {
      options.baseUrl = storedUrl;
    }

    final token = await _storage.read(key: AppConstants.keyAccessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.read(key: AppConstants.keyRefreshToken);
      final baseUrl = await _storage.read(key: AppConstants.keyBaseUrl) ?? AppConstants.defaultBaseUrl;
      if (refreshToken != null) {
        try {
          final response = await Dio(BaseOptions(baseUrl: baseUrl))
              .post('/api/v1/auth/refresh', data: {'refresh_token': refreshToken});
          final newToken = response.data['access_token'];
          await _storage.write(key: AppConstants.keyAccessToken, value: newToken);
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retry = await _dio.fetch(err.requestOptions);
          handler.resolve(retry);
          return;
        } catch (_) {
          await _storage.deleteAll();
        }
      }
    }
    handler.next(err);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
