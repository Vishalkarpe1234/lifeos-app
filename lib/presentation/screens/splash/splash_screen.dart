import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/core/constants/app_constants.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashState();
}

class _SplashState extends ConsumerState<SplashScreen> {
  String _status = 'Starting up...';
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _warmupAndGo();
  }

  Future<void> _warmupAndGo() async {
    // Ping backend to wake it up (Render free tier sleeps after 15 min)
    final timer = Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() { _slow = true; _status = 'Waking up server...'; });
    });
    try {
      final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl, connectTimeout: const Duration(seconds: 60), receiveTimeout: const Duration(seconds: 60)));
      await dio.get('/health');
      if (mounted) setState(() => _status = 'Ready!');
    } catch (_) {
      // Backend might be slow — still navigate
    }
    await timer;
    if (mounted) {
      final auth = ref.read(authProvider);
      context.go(auth.loggedIn ? (auth.isAdmin ? '/admin' : '/notes') : '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.primary,
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 100, height: 100,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 30, offset: const Offset(0, 8))]),
          child: ClipRRect(borderRadius: BorderRadius.circular(24),
            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain))),
        const SizedBox(height: 20),
        const Text('VK OS', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Inter', letterSpacing: -1)),
        const SizedBox(height: 6),
        Text('Your Life, Organized.', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7), fontFamily: 'Inter')),
        const SizedBox(height: 50),
        const SizedBox(width: 160, child: LinearProgressIndicator(color: Colors.white, backgroundColor: Color(0x33FFFFFF), minHeight: 2)),
        const SizedBox(height: 16),
        Text(_status, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(_slow ? 1.0 : 0.6), fontFamily: 'Inter')),
        if (_slow) ...[
          const SizedBox(height: 8),
          Text('Free server warming up (up to 50s on first load)', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5), fontFamily: 'Inter'), textAlign: TextAlign.center),
        ],
      ])),
    );
  }
}
