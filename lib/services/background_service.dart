import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:lifeos/core/constants/app_constants.dart';

const bgChannelId = 'vkos_background';
const chatChannelId = 'vkos_chat';
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
  await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
    chatChannelId, 'VK OS Chat',
    description: 'New message notifications',
    importance: Importance.high,
    playSound: true,
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
  final notifications = FlutterLocalNotificationsPlugin();
  await notifications.initialize(const InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  ));

  if (service is AndroidServiceInstance) {
    service.on('stopService').listen((event) => service.stopSelf());
  }

  WebSocketChannel? channel;
  Timer? reconnectTimer;

  Future<void> sendLocation() async {
    try {
      if (await storage.read(key: locPermissionKey) != 'true') return;
      final token = await storage.read(key: AppConstants.keyToken);
      if (token == null) return;

      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 25)),
        );
      } catch (_) {
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) return;
        pos = last;
      }

      final dio = Dio(BaseOptions(
          baseUrl: AppConstants.baseUrl,
          headers: {'Authorization': 'Bearer $token'}));
      await dio.post('/api/v1/location', data: {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'accuracy': pos.accuracy,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> connectWs() async {
    final token = await storage.read(key: AppConstants.keyToken);
    if (token == null) return;
    final base = AppConstants.baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final uri = Uri.parse('$base/api/v1/connect/ws?token=$token');
    try {
      channel = WebSocketChannel.connect(uri);
      channel!.stream.listen((event) async {
        try {
          final data = jsonDecode(event as String) as Map<String, dynamic>;
          if (data['type'] == 'message') {
            final msg = data['message'] as Map<String, dynamic>?;
            if (msg == null) return;
            final content = msg['content']?.toString();
            final fileUrl = msg['file_url']?.toString();
            final fromUsername = msg['from_username']?.toString();
            final title = fromUsername != null ? 'Message from @$fromUsername' : 'New message';
            final body = content?.isNotEmpty == true
                ? content!
                : (fileUrl != null ? '📷 Image' : 'New message');
            await notifications.show(
              (msg['id'] as int? ?? 0) % 10000,
              title,
              body,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  chatChannelId, 'VK OS Chat',
                  importance: Importance.high,
                  priority: Priority.high,
                  playSound: true,
                  enableVibration: true,
                ),
              ),
            );
          }
        } catch (_) {}
      }, onDone: () {
        channel = null;
        reconnectTimer?.cancel();
        reconnectTimer = Timer(const Duration(seconds: 10), connectWs);
      }, onError: (_) {
        channel = null;
        reconnectTimer?.cancel();
        reconnectTimer = Timer(const Duration(seconds: 10), connectWs);
      });
    } catch (_) {
      reconnectTimer?.cancel();
      reconnectTimer = Timer(const Duration(seconds: 10), connectWs);
    }
  }

  await connectWs();
  await sendLocation();

  Timer.periodic(const Duration(seconds: 25), (_) {
    try {
      channel?.sink.add(jsonEncode({'type': 'ping'}));
    } catch (_) {}
  });

  Timer.periodic(const Duration(minutes: 2), (_) => sendLocation());

  service.on('stopService').listen((event) {
    reconnectTimer?.cancel();
    channel?.sink.close();
  });
}
