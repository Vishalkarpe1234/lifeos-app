import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lifeos/core/constants/app_constants.dart';

/// Entry point called by the Android ForegroundService.
/// Must be a top-level function annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
void locationTaskCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  static const _storage = FlutterSecureStorage();

  StreamSubscription<Position>? _posStream;
  DateTime? _lastSentAt;
  double? _lastSentLat;
  double? _lastSentLng;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // If no auth token (user logged out), stop service immediately.
    final token = await _storage.read(key: AppConstants.keyToken);
    if (token == null) {
      await FlutterForegroundTask.stopService();
      return;
    }
    _startStream();
  }

  /// Called every 10 minutes as a heartbeat — sends location even if stationary.
  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    final token = await _storage.read(key: AppConstants.keyToken);
    if (token == null) {
      await FlutterForegroundTask.stopService();
      return;
    }
    await _forcePost(token);
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _posStream?.cancel();
  }

  // ── Position stream ──────────────────────────────────────────────────────────

  void _startStream() {
    _posStream?.cancel();
    _posStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // fire on ≥50 m movement
      ),
    ).listen(
      (pos) async {
        final token = await _storage.read(key: AppConstants.keyToken);
        if (token == null) return;

        final movedM = _lastSentLat != null
            ? Geolocator.distanceBetween(
                _lastSentLat!, _lastSentLng!, pos.latitude, pos.longitude)
            : 9999.0;
        final minSince = _lastSentAt != null
            ? DateTime.now().difference(_lastSentAt!).inMinutes
            : 99;

        // Send if moved ≥50 m OR 5+ minutes elapsed since last send
        if (movedM >= 50 || minSince >= 5) {
          await _send(token, pos.latitude, pos.longitude, pos.accuracy);
        }
      },
      onError: (_) {
        // Stream error — restart after 15 s
        Future.delayed(const Duration(seconds: 15), _startStream);
      },
      cancelOnError: true,
    );
  }

  // ── Heartbeat: force a fresh position even when device is stationary ─────────

  Future<void> _forcePost(String token) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
      await _send(token, pos.latitude, pos.longitude, pos.accuracy);
    } catch (_) {
      // GPS timed out — try last-known
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          await _send(token, last.latitude, last.longitude, last.accuracy);
        }
      } catch (_) {}
    }
  }

  // ── HTTP post ────────────────────────────────────────────────────────────────

  Future<void> _send(
      String token, double lat, double lng, double acc) async {
    try {
      final resp = await Dio().post(
        '${AppConstants.baseUrl}/api/v1/location',
        data: {
          'latitude': lat,
          'longitude': lng,
          'accuracy': acc,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (s) => s != null,
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      );

      if (resp.statusCode == 401) {
        // Token expired — try refresh then retry
        final newToken = await _refreshToken();
        if (newToken != null) await _send(newToken, lat, lng, acc);
        return;
      }

      if ((resp.statusCode ?? 0) < 300) {
        _lastSentAt = DateTime.now();
        _lastSentLat = lat;
        _lastSentLng = lng;
      }
    } catch (_) {}
  }

  Future<String?> _refreshToken() async {
    try {
      final refresh = await _storage.read(key: AppConstants.keyRefresh);
      if (refresh == null) return null;

      final r = await Dio().post(
        '${AppConstants.baseUrl}/api/v1/auth/refresh',
        data: {'refresh_token': refresh},
        options: Options(receiveTimeout: const Duration(seconds: 20)),
      );

      if ((r.statusCode ?? 0) == 200) {
        final newToken = r.data['access_token'] as String;
        await _storage.write(key: AppConstants.keyToken, value: newToken);
        return newToken;
      }
    } catch (_) {}
    return null;
  }
}
