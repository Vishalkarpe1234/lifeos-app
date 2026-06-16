import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/router/app_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/call_provider.dart';

@pragma('vm:entry-point')
void _onBgNotificationResponse(NotificationResponse _) {}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  FlutterLocalNotificationsPlugin().initialize(
    const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    onDidReceiveBackgroundNotificationResponse: _onBgNotificationResponse,
  );
  runApp(const ProviderScope(child: VKOSApp()));
}

class VKOSApp extends ConsumerStatefulWidget {
  const VKOSApp({super.key});
  @override
  ConsumerState<VKOSApp> createState() => _VKOSAppState();
}

class _VKOSAppState extends ConsumerState<VKOSApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Called every time the app comes back to the foreground (e.g. user tapped
  // the incoming-call notification while the app was backgrounded/killed).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    // Re-check secure-storage for a call invite written by the background
    // service while the app was closed/backgrounded.
    final controller = ref.read(callControllerProvider.notifier);
    controller.checkPendingInvite().then((_) {
      final callState = ref.read(callControllerProvider);
      if (callState.status == CallStatus.ringing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.read(routerProvider).push('/connect/incoming-call');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(callControllerProvider, (prev, next) {
      final wasRinging = prev?.status == CallStatus.ringing;
      if (next.status == CallStatus.ringing && !wasRinging) {
        ref.read(routerProvider).push('/connect/incoming-call');
      }
    });
    return MaterialApp.router(
      title: 'VK OS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
