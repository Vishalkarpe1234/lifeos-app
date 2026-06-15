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
const callChannelId = 'vkos_calls';
const pendingCallKey = 'pending_call_invite';
const locPermissionKey = 'loc_permission_granted';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  if (await service.isRunning()) return;

  final notifications = FlutterLocalNotificationsPlugin();
  final androidPlugin = notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
    bgChannelId, 'VK OS Background Service',
    description: 'Keeps live location sharing and call alerts active',
    importance: Importance.low,
  ));
  await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
    callChannelId, 'VK OS Calls',
    description: 'Incoming call and meeting alerts',
    importance: Importance.max,
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
      initialNotificationContent: 'Live location & call alerts active',
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
  DartPluginRegistrant.ensureInitialized();

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
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 25)),
        );
      } catch (_) {
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) return;
        pos = last;
      }

      final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl, headers: {'Authorization': 'Bearer $token'}));
      await dio.post('/api/v1/location', data: {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'accuracy': pos.accuracy,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> showCallNotification(Map<String, dynamic> data) async {
    final isMeeting = data['type'] == 'meeting_invite';
    final username = data['from_username'] ?? 'Someone';
    final callType = data['call_type'] ?? 'video';
    await notifications.show(
      2025,
      isMeeting ? 'Meeting invite' : 'Incoming ${callType == 'video' ? 'video' : 'audio'} call',
      isMeeting ? '@$username started a meeting' : '@$username is calling you',
      const NotificationDetails(android: AndroidNotificationDetails(
        callChannelId, 'VK OS Calls',
        priority: Priority.max,
        importance: Importance.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.call,
        playSound: true,
        visibility: NotificationVisibility.public,
      )),
    );
  }

  Future<void> connectWs() async {
    final token = await storage.read(key: AppConstants.keyToken);
    if (token == null) return;
    final base = AppConstants.baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
    final uri = Uri.parse('$base/api/v1/connect/ws?token=$token');
    try {
      channel = WebSocketChannel.connect(uri);
      channel!.stream.listen((event) async {
        try {
          final data = jsonDecode(event as String) as Map<String, dynamic>;
          if (data['type'] == 'call_invite' || data['type'] == 'meeting_invite') {
            await storage.write(key: pendingCallKey, value: jsonEncode({
              ...data,
              'received_at': DateTime.now().toUtc().toIso8601String(),
            }));
            await showCallNotification(data);
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

  // keep the signaling socket alive
  Timer.periodic(const Duration(seconds: 25), (_) {
    try {
      channel?.sink.add(jsonEncode({'type': 'ping'}));
    } catch (_) {}
  });

  // periodic live location update
  Timer.periodic(const Duration(minutes: 2), (_) => sendLocation());

  service.on('stopService').listen((event) {
    reconnectTimer?.cancel();
    channel?.sink.close();
  });
}
