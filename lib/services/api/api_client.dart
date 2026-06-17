import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lifeos/core/constants/app_constants.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 12),
    headers: {'Content-Type': 'application/json'},
  ));
  dio.interceptors.add(_AuthInterceptor(dio));
  return dio;
});

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  final _s = const FlutterSecureStorage();
  _AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _s.read(key: AppConstants.keyToken);
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refresh = await _s.read(key: AppConstants.keyRefresh);
      if (refresh != null) {
        try {
          final r = await Dio(BaseOptions(baseUrl: AppConstants.baseUrl, connectTimeout: const Duration(seconds: 12), receiveTimeout: const Duration(seconds: 15)))
              .post('/api/v1/auth/refresh', data: {'refresh_token': refresh});
          final t = r.data['access_token'] as String;
          await _s.write(key: AppConstants.keyToken, value: t);
          err.requestOptions.headers['Authorization'] = 'Bearer $t';
          handler.resolve(await _dio.fetch(err.requestOptions));
          return;
        } catch (_) {
          await _s.deleteAll();
        }
      }
    }
    handler.next(err);
  }
}

String extractError(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.sendTimeout) {
    return 'Server is warming up, please try again in a moment';
  }
  if (e.type == DioExceptionType.connectionError) {
    return 'Cannot connect — check your internet connection';
  }
  try {
    final data = e.response?.data;
    if (data is Map) return data['detail']?.toString() ?? 'Request failed';
    return 'Request failed (${e.response?.statusCode ?? 'no response'})';
  } catch (_) {
    return 'Something went wrong';
  }
}
