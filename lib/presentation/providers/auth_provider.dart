import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/core/constants/app_constants.dart';

class AuthState {
  final String? accessToken;
  final String? userEmail;
  final bool isAdmin;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.accessToken,
    this.userEmail,
    this.isAdmin = false,
    this.isLoading = false,
    this.error,
  });

  bool get hasToken => accessToken != null && accessToken!.isNotEmpty;

  AuthState copyWith({
    String? accessToken,
    String? userEmail,
    bool? isAdmin,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearToken = false,
  }) {
    return AuthState(
      accessToken: clearToken ? null : (accessToken ?? this.accessToken),
      userEmail: userEmail ?? this.userEmail,
      isAdmin: isAdmin ?? this.isAdmin,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final _storage = const FlutterSecureStorage();

  AuthNotifier() : super(const AuthState()) {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await _storage.read(key: AppConstants.keyAccessToken);
    final email = await _storage.read(key: AppConstants.keyUserEmail);
    if (token != null) {
      state = state.copyWith(accessToken: token, userEmail: email);
    }
  }

  Future<bool> login(String email, String password, String baseUrl) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await dio.post('/api/v1/auth/login', data: {'email': email, 'password': password});
      final token = response.data['access_token'];
      final refresh = response.data['refresh_token'];
      await _storage.write(key: AppConstants.keyAccessToken, value: token);
      await _storage.write(key: AppConstants.keyRefreshToken, value: refresh);
      await _storage.write(key: AppConstants.keyUserEmail, value: email);
      await _storage.write(key: AppConstants.keyBaseUrl, value: baseUrl);

      final meResp = await dio.get('/api/v1/auth/me', options: Options(headers: {'Authorization': 'Bearer $token'}));
      state = state.copyWith(accessToken: token, userEmail: email, isAdmin: meResp.data['is_admin'] ?? false, isLoading: false);
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Login failed';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<bool> loginWithPIN(String email, String pin, String baseUrl) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await dio.post('/api/v1/auth/login/pin', data: {'email': email, 'pin': pin});
      final token = response.data['access_token'];
      await _storage.write(key: AppConstants.keyAccessToken, value: token);
      await _storage.write(key: AppConstants.keyRefreshToken, value: response.data['refresh_token']);
      state = state.copyWith(accessToken: token, userEmail: email, isLoading: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.response?.data?['detail'] ?? 'PIN login failed');
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.keyAccessToken);
    await _storage.delete(key: AppConstants.keyRefreshToken);
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
