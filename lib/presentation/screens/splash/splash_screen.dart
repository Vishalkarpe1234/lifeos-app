import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashState();
}

class _SplashState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), _go);
  }

  void _go() {
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.loggedIn) { context.go(auth.isAdmin ? '/admin' : '/notes'); }
    else { context.go('/login'); }
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
        const SizedBox(width: 40, child: LinearProgressIndicator(color: Colors.white, backgroundColor: Color(0x33FFFFFF), minHeight: 2)),
      ])),
    );
  }
}
