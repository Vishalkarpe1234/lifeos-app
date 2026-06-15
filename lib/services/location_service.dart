import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lifeos/core/constants/app_constants.dart';

class LocationService {
  static const _storage = FlutterSecureStorage();
  static const _permKey = 'loc_permission_granted';
  static Timer? _timer;

  static Future<bool> isPermissionGrantedLocally() async {
    return await _storage.read(key: _permKey) == 'true';
  }

  static Future<bool> requestAndGrant(Dio dio) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      return false;
    }

    // Mark as granted locally
    await _storage.write(key: _permKey, value: 'true');

    // Tell backend
    try {
      await dio.patch('/api/v1/location/permission', data: {'granted': true});
    } catch (_) {}

    // Send location immediately
    await sendLocation(dio);
    return true;
  }

  static Future<void> sendLocation(Dio dio) async {
    try {
      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 25)),
        );
      } catch (_) {
        // Fallback to last known fix if a fresh high-accuracy fix times out
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

  static void startPeriodicTracking(Dio dio) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 15), (_) => sendLocation(dio));
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
