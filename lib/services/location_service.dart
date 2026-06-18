import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocationService {
  static const _storage = FlutterSecureStorage();
  static const _permKey = 'loc_permission_granted';
  static const _askedKey = 'loc_ever_asked';

  static StreamSubscription<Position>? _posStream;
  static DateTime? _lastSentAt;
  static double? _lastSentLat;
  static double? _lastSentLng;

  static Future<bool> isPermissionGrantedLocally() async {
    return await _storage.read(key: _permKey) == 'true';
  }

  static Future<bool> wasEverAsked() async {
    return await _storage.read(key: _askedKey) != null;
  }

  static Future<void> markAsked() async {
    await _storage.write(key: _askedKey, value: 'yes');
  }

  static Future<bool> requestAndGrant(Dio dio) async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        await Geolocator.openLocationSettings();
        await Future.delayed(const Duration(seconds: 1));
        enabled = await Geolocator.isLocationServiceEnabled();
        if (!enabled) return false;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        return false;
      }

      await _storage.write(key: _permKey, value: 'true');
      await markAsked();

      try {
        await dio.patch('/api/v1/location/permission',
            data: {'granted': true});
      } catch (_) {}

      await startTracking(dio);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Starts the GPS position stream. Sends to server whenever:
  ///   - first fix ever
  ///   - device moved ≥50 m from last sent position
  ///   - 5 minutes have elapsed since last send
  static Future<void> startTracking(Dio dio) async {
    _posStream?.cancel();

    // Immediately post last-known so admin sees something right away
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        await _post(dio, last);
        _lastSentAt = DateTime.now();
        _lastSentLat = last.latitude;
        _lastSentLng = last.longitude;
      }
    } catch (_) {}

    // Stream continuous GPS updates (high accuracy, fires on ≥30 m movement)
    _posStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 30,
      ),
    ).listen(
      (pos) async {
        final now = DateTime.now();
        final movedM = (_lastSentLat != null)
            ? Geolocator.distanceBetween(
                _lastSentLat!, _lastSentLng!, pos.latitude, pos.longitude)
            : 9999.0;
        final minutesSince = _lastSentAt != null
            ? now.difference(_lastSentAt!).inMinutes
            : 99;

        if (minutesSince >= 5 || movedM >= 50) {
          await _post(dio, pos);
          _lastSentAt = now;
          _lastSentLat = pos.latitude;
          _lastSentLng = pos.longitude;
        }
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  static Future<void> _post(Dio dio, Position pos) async {
    try {
      await dio.post('/api/v1/location', data: {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'accuracy': pos.accuracy,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  static Future<void> resumeIfGranted(Dio dio) async {
    if (!await isPermissionGrantedLocally()) return;
    await startTracking(dio);
  }

  static void stop() {
    _posStream?.cancel();
    _posStream = null;
    _lastSentAt = null;
    _lastSentLat = null;
    _lastSentLng = null;
  }

  static Future<void> clearPermission() async {
    await _storage.delete(key: _permKey);
    stop();
  }
}
