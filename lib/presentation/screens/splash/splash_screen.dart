import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final auth = ref.read(authStateProvider);
    if (auth.hasToken) {
      context.go(auth.isAdmin ? '/admin' : '/notes');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, spreadRadius: 4)]),
              child: ClipRRect(borderRadius: BorderRadius.circular(28),
                child: Image.asset('assets/images/logo.png', fit: BoxFit.contain)),
            ),
            const SizedBox(height: 24),
            const Text('VK OS', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Inter', letterSpacing: -1.5)),
            const SizedBox(height: 8),
            Text('Your Life, Organized, Intelligent.', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75), fontFamily: 'Inter')),
            const SizedBox(height: 60),
            SizedBox(width: 180, child: LinearProgressIndicator(backgroundColor: Colors.white.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), minHeight: 2)),
          ],
        ),
      ),
    );
  }
}
