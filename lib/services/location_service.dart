import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocationService {
  static const _storage = FlutterSecureStorage();
  static const _permKey = 'loc_permission_granted';
  static Timer? _timer;

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

      sendLocation(dio);
      _startForegroundTimer(dio);

      return true;
    } catch (_) {
      return false;
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

  static void _startForegroundTimer(Dio dio) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 3), (_) => sendLocation(dio));
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
