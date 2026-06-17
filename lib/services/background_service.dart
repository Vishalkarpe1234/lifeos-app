import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lifeos/core/constants/app_constants.dart';

const bgChannelId = 'vkos_background';
const locPermissionKey = 'loc_permission_granted';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  if (await service.isRunning()) return;

  final notifications = FlutterLocalNotificationsPlugin();
  final androidPlugin =
      notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
    bgChannelId, 'VK OS Background Service',
    description: 'Keeps live location sharing active',
    importance: Importance.low,
  ));
  await androidPlugin?.requestNotificationsPermission();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: bgChannelId,
      initialNotificationTitle: 'VK OS',
      initialNotificationContent: 'Live location active',
      foregroundServiceNotificationId: 911,
    ),
    iosConfiguration: IosConfiguration(),
  );
  service.startService();
}

Future<void> stopBackgroundService() async {
  final service = FlutterBackgroundService();
  if (await service.isRunning()) {
    service.invoke('stopService');
  }
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  final storage = const FlutterSecureStorage();

  if (service is AndroidServiceInstance) {
    service.on('stopService').listen((event) => service.stopSelf());
  }

  Future<void> sendLocation() async {
    try {
      if (await storage.read(key: locPermissionKey) != 'true') return;
      final token = await storage.read(key: AppConstants.keyToken);
      if (token == null) return;

      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
        );
      } catch (_) {
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) return;
        pos = last;
      }

      final dio = Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Authorization': 'Bearer $token'},
      ));
      await dio.post('/api/v1/location', data: {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'accuracy': pos.accuracy,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  await sendLocation();

  Timer.periodic(const Duration(minutes: 3), (_) => sendLocation());

  service.on('stopService').listen((event) {});
}
