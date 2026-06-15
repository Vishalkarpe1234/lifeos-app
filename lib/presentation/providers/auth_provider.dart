import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/core/constants/app_constants.dart';

class AuthState {
  final String? token;
  final String? email;
  final bool isAdmin;
  final bool loading;
  final String? error;
  const AuthState({this.token, this.email, this.isAdmin = false, this.loading = false, this.error});
  bool get loggedIn => token != null;
  AuthState copyWith({String? token, String? email, bool? isAdmin, bool? loading, String? error, bool clearToken = false, bool clearErr = false}) =>
    AuthState(token: clearToken ? null : (token ?? this.token), email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin, loading: loading ?? this.loading,
      error: clearErr ? null : (error ?? this.error));
}

class AuthNotifier extends StateNotifier<AuthState> {
  final _s = const FlutterSecureStorage();
  AuthNotifier() : super(const AuthState()) { _load(); }

  Future<void> _load() async {
    final t = await _s.read(key: AppConstants.keyToken);
    final e = await _s.read(key: AppConstants.keyEmail);
    final a = await _s.read(key: AppConstants.keyIsAdmin);
    if (t != null) state = AuthState(token: t, email: e, isAdmin: a == 'true');
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, clearErr: true);
    try {
      final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
      final r = await dio.post('/api/v1/auth/login', data: {'email': email.trim().toLowerCase(), 'password': password});
      final token = r.data['access_token'] as String;
      final refresh = r.data['refresh_token'] as String;
      final me = await dio.get('/api/v1/auth/me', options: Options(headers: {'Authorization': 'Bearer $token'}));
      final isAdmin = me.data['is_admin'] == true;
      await _s.write(key: AppConstants.keyToken, value: token);
      await _s.write(key: AppConstants.keyRefresh, value: refresh);
      await _s.write(key: AppConstants.keyEmail, value: email.trim().toLowerCase());
      await _s.write(key: AppConstants.keyIsAdmin, value: isAdmin.toString());
      state = AuthState(token: token, email: email.trim().toLowerCase(), isAdmin: isAdmin);
      return true;
    } on DioException catch (e) {
      String msg = 'Login failed';
      try { msg = (e.response?.data as Map)['detail']?.toString() ?? msg; } catch (_) {}
      state = state.copyWith(loading: false, error: msg);
      return false;
    }
  }

  Future<void> logout() async {
    await _s.deleteAll();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
