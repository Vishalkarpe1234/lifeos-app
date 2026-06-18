import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lifeos/services/background_service.dart';

class LocationService {
  static const _storage = FlutterSecureStorage();
  static const _permKey = 'loc_permission_granted';
  static Timer? _timer;
  static bool _serviceStarting = false;

  static Future<bool> isPermissionGrantedLocally() async {
    return await _storage.read(key: _permKey) == 'true';
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

      try {
        await dio.patch('/api/v1/location/permission', data: {'granted': true});
      } catch (_) {}

      // Send location once immediately (non-blocking)
      sendLocation(dio);

      // Start background service ONCE
      await _startServiceSafe();

      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _startServiceSafe() async {
    if (_serviceStarting) return;
    _serviceStarting = true;
    try {
      await initializeBackgroundService();
    } catch (_) {
      // Background service failed to start — app still works without it
    } finally {
      _serviceStarting = false;
    }
  }

  static Future<void> sendLocation(Dio dio) async {
    try {
      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (_) {
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) return;
        pos = last;
      }
      await dio.post('/api/v1/location', data: {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'accuracy': pos.accuracy,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  // Called when already have permission — resume tracking on app open
  static Future<void> resumeIfGranted(Dio dio) async {
    final granted = await isPermissionGrantedLocally();
    if (!granted) return;
    sendLocation(dio); // non-blocking
    await _startServiceSafe();
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> clearPermission() async {
    await _storage.delete(key: _permKey);
    stop();
    await stopBackgroundService();
  }
}
