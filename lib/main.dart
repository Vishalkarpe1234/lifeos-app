import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/router/app_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/call_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark));
  runApp(const ProviderScope(child: VKOSApp()));
}

class VKOSApp extends ConsumerWidget {
  const VKOSApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(callControllerProvider, (prev, next) {
      final router = ref.read(routerProvider);
      final wasRinging = prev?.status == CallStatus.ringing;
      if (next.status == CallStatus.ringing && !wasRinging) {
        router.push('/connect/incoming-call');
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
