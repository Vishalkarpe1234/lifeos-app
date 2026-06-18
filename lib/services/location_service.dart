import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocationService {
  static const _storage = FlutterSecureStorage();
  static const _permKey = 'loc_permission_granted';
  static const _askedKey = 'loc_ever_asked';
  static Timer? _timer;

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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        await Future.delayed(const Duration(seconds: 1));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return false;
      }

      await _storage.write(key: _permKey, value: 'true');
      await markAsked();

      try {
        await dio.patch('/api/v1/location/permission', data: {'granted': true});
      } catch (_) {}

      // Non-blocking: send immediately, start 5-min timer
      sendLocation(dio);
      _startForegroundTimer(dio);

      return true;
    } catch (_) {
      return false;
    }
  }

  // Two-stage send: use last-known immediately (fast), then precise GPS (may take 30-60s)
  static Future<void> sendLocation(Dio dio) async {
    // Stage 1: send last-known position immediately if available
    Position? lastKnown;
    try {
      lastKnown = await Geolocator.getLastKnownPosition();
    } catch (_) {}

    if (lastKnown != null) {
      await _postLocation(dio, lastKnown);
    }

    // Stage 2: get a fresh GPS fix (medium accuracy = uses both GPS + network, faster fix)
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 30),
        ),
      );
      // Only post again if coordinates differ meaningfully from last-known
      if (lastKnown == null || _distanceMeter(lastKnown, pos) > 20) {
        await _postLocation(dio, pos);
      }
    } catch (_) {
      // GPS timed out or unavailable — last-known was already sent above
    }
  }

  static Future<void> _postLocation(Dio dio, Position pos) async {
    try {
      await dio.post('/api/v1/location', data: {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'accuracy': pos.accuracy,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  // Simple haversine approximation (metres)
  static double _distanceMeter(Position a, Position b) {
    const r = 6371000.0;
    final dLat = (b.latitude - a.latitude) * 0.017453;
    final dLng = (b.longitude - a.longitude) * 0.017453;
    final h = dLat * dLat + dLng * dLng;
    return r * h; // rough estimate, good enough
  }

  static void _startForegroundTimer(Dio dio) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => sendLocation(dio));
  }

  static Future<void> resumeIfGranted(Dio dio) async {
    final granted = await isPermissionGrantedLocally();
    if (!granted) return;
    sendLocation(dio);
    _startForegroundTimer(dio);
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> clearPermission() async {
    await _storage.delete(key: _permKey);
    stop();
  }
}
