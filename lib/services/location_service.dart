import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lifeos/services/location_task_handler.dart';

/// Initialise FlutterForegroundTask once at app startup (call from main()).
void initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'vkos_location',
      channelName: 'VK OS Location',
      channelDescription: 'Tracks your location in the background for VK OS admin monitoring.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
    foregroundTaskOptions: ForegroundTaskOptions(
      // Heartbeat every 10 minutes — sends location even when stationary
      eventAction: ForegroundTaskEventAction.repeat(10 * 60 * 1000),
      autoRunOnBoot: true,   // restart service after phone reboot
      allowWakeLock: true,   // prevent CPU sleep between GPS polls
    ),
  );
}

class LocationService {
  static const _storage = FlutterSecureStorage();
  static const _permKey = 'loc_permission_granted';
  static const _askedKey = 'loc_ever_asked';

  // ── Permission helpers ──────────────────────────────────────────────────────

  static Future<bool> isPermissionGrantedLocally() async =>
      await _storage.read(key: _permKey) == 'true';

  static Future<bool> wasEverAsked() async =>
      await _storage.read(key: _askedKey) != null;

  static Future<void> markAsked() async =>
      await _storage.write(key: _askedKey, value: 'yes');

  // ── Full permission + service start ─────────────────────────────────────────

  /// Requests location permission, then starts the background foreground service.
  /// Returns true if at least foreground location was granted.
  static Future<bool> requestAndGrant(Dio dio, {BuildContext? context}) async {
    try {
      // 1. GPS hardware must be on
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        await Geolocator.openLocationSettings();
        await Future.delayed(const Duration(seconds: 2));
        enabled = await Geolocator.isLocationServiceEnabled();
        if (!enabled) return false;
      }

      // 2. Request foreground location permission
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return false;
      }
      if (perm == LocationPermission.denied) return false;

      // 3. On Android 11+, "Allow all the time" requires a Settings redirect.
      //    Show an explanation dialog and open app settings.
      if (perm == LocationPermission.whileInUse && context != null && context.mounted) {
        await _promptBackgroundUpgrade(context);
        // Re-check after user returns from Settings
        await Future.delayed(const Duration(milliseconds: 500));
        perm = await Geolocator.checkPermission();
      }

      // 4. Store permission flag and notify backend
      await _storage.write(key: _permKey, value: 'true');
      await markAsked();
      try { await dio.patch('/api/v1/location/permission', data: {'granted': true}); } catch (_) {}

      // 5. Request Android 13+ notification permission (needed for service notification)
      await FlutterForegroundTask.requestNotificationPermission();

      // 6. Start background location service
      await _startService();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Shows a dialog explaining why "Allow all the time" is needed,
  /// then redirects the user to app settings.
  static Future<void> _promptBackgroundUpgrade(BuildContext context) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Allow Background Location',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16)),
        content: const Text(
          'To track your location when the app is closed or the phone is restarted, '
          'please set Location to "Allow all the time".\n\n'
          '1. Tap "Open Settings"\n'
          '2. Tap Location\n'
          '3. Select "Allow all the time"',
          style: TextStyle(fontFamily: 'Inter', color: Color(0xFF444444), fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Skip', style: TextStyle(color: Color(0xFF777777), fontFamily: 'Inter'))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Open Settings', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (go == true) await Geolocator.openAppSettings();
  }

  // ── Service management ──────────────────────────────────────────────────────

  static Future<void> _startService() async {
    try {
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'VK OS',
        notificationText: 'Location tracking is active',
        callback: locationTaskCallback,
      );
    } catch (_) {}
  }

  /// Called on app launch / login — restarts the service if permission was already granted.
  static Future<void> resumeIfGranted() async {
    try {
      final perm = await Geolocator.checkPermission();
      final granted = perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
      if (!granted) return;
      await _startService();
    } catch (_) {}
  }

  /// Stop location tracking (call on logout).
  static Future<void> stop() async {
    try { await FlutterForegroundTask.stopService(); } catch (_) {}
  }

  /// Clear stored permission + stop service (for account deletion / full reset).
  static Future<void> clearPermission() async {
    await _storage.delete(key: _permKey);
    await stop();
  }
}
