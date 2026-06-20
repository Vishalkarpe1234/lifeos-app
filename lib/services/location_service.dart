import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lifeos/services/location_task_handler.dart';

/// Call once from main() before runApp to configure the notification channel.
void initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'vkos_location',
      channelName: 'VK OS Location',
      channelDescription: 'Background location tracking for VK OS admin monitoring.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(600000), // 10-min heartbeat
      autoRunOnBoot: true,  // restarts service after phone reboot
      allowWakeLock: true,  // keeps CPU awake between GPS polls
    ),
  );
}

class LocationService {
  static const _storage = FlutterSecureStorage();
  static const _permKey = 'loc_permission_granted';
  static const _askedKey = 'loc_ever_asked';

  static Future<bool> isPermissionGrantedLocally() async =>
      await _storage.read(key: _permKey) == 'true';

  static Future<bool> wasEverAsked() async =>
      await _storage.read(key: _askedKey) != null;

  static Future<void> markAsked() async =>
      await _storage.write(key: _askedKey, value: 'yes');

  // ── Main entry point ─────────────────────────────────────────────────────────

  /// Requests location permission. Returns immediately — service startup and
  /// battery-optimization prompt happen in background to avoid UI freeze.
  static Future<bool> requestAndGrant(Dio dio, {BuildContext? context}) async {
    try {
      // 1. GPS must be enabled
      bool gpsOn = await Geolocator.isLocationServiceEnabled();
      if (!gpsOn) {
        await Geolocator.openLocationSettings();
        await Future.delayed(const Duration(seconds: 2));
        gpsOn = await Geolocator.isLocationServiceEnabled();
        if (!gpsOn) return false;
      }

      // 2. Request foreground location (shows ONE system dialog)
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return false;
      }
      if (perm == LocationPermission.denied) return false;

      // 3. Persist and notify backend — non-blocking HTTP call
      await _storage.write(key: _permKey, value: 'true');
      await markAsked();
      dio.patch('/api/v1/location/permission', data: {'granted': true})
          .catchError((_) {});

      // 4. Launch service + battery-optimization in background (fire-and-forget)
      _launchServiceInBackground(context: context);

      // 5. Show "Allow all the time" nudge asynchronously if only whileInUse granted
      if (perm == LocationPermission.whileInUse && context != null && context.mounted) {
        Future.microtask(() {
          if (context.mounted) _promptBackgroundUpgrade(context);
        });
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // Runs completely detached — never awaited. Does NOT block the UI.
  static void _launchServiceInBackground({BuildContext? context}) {
    Future(() async {
      try {
        // Android 13+ notification permission
        await FlutterForegroundTask.requestNotificationPermission();
        // Start foreground service
        await _startService();
        // Request battery optimization exemption — critical for service survival
        // when device enters Doze mode or app is swiped away
        try {
          final ignored = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
          if (!ignored) {
            await FlutterForegroundTask.requestIgnoreBatteryOptimization();
          }
        } catch (_) {}
      } catch (_) {}
    });
  }

  static Future<void> _promptBackgroundUpgrade(BuildContext context) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Allow Background Location',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16)),
        content: const Text(
          'To track your location when the app is closed or the phone restarts, '
          'set Location to "Allow all the time".\n\n'
          '1. Tap "Open Settings"\n'
          '2. Tap Location\n'
          '3. Select "Allow all the time"',
          style: TextStyle(fontFamily: 'Inter', color: Color(0xFF444444), fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Skip',
                  style: TextStyle(color: Color(0xFF777777), fontFamily: 'Inter'))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Open Settings',
                  style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (go == true) await Geolocator.openAppSettings();
  }

  // ── Service lifecycle ─────────────────────────────────────────────────────────

  static Future<void> _startService() async {
    try {
      final running = await FlutterForegroundTask.isRunningService;
      if (running) return;
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'VK OS',
        notificationText: 'Location tracking is active',
        callback: locationTaskCallback,
      );
    } catch (_) {}
  }

  /// Restart on app launch/login without UI. Fire-and-forget.
  static void resumeIfGranted() {
    Future(() async {
      try {
        final perm = await Geolocator.checkPermission();
        final ok = perm == LocationPermission.always ||
            perm == LocationPermission.whileInUse;
        if (!ok) return;
        await _startService();
        // Re-request battery exemption if it was cleared by OS
        try {
          final ignored = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
          if (!ignored) {
            await FlutterForegroundTask.requestIgnoreBatteryOptimization();
          }
        } catch (_) {}
      } catch (_) {}
    });
  }

  /// Stop tracking (call on logout).
  static Future<void> stop() async {
    try { await FlutterForegroundTask.stopService(); } catch (_) {}
  }

  /// Full reset — clears stored flag and stops service.
  static Future<void> clearPermission() async {
    await _storage.delete(key: _permKey);
    await stop();
  }
}
