import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _orb1Controller;
  late AnimationController _orb2Controller;
  late AnimationController _orb3Controller;

  @override
  void initState() {
    super.initState();
    _orb1Controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _orb2Controller = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _orb3Controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    final auth = ref.read(authStateProvider);
    if (auth.hasToken) {
      context.go('/dashboard');
    } else {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _orb1Controller.dispose();
    _orb2Controller.dispose();
    _orb3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 24),
                _buildAppName(),
                const SizedBox(height: 8),
                _buildTagline(),
                const SizedBox(height: 60),
                _buildLoader(),
              ],
            ),
          ),
          _buildVersionTag(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _orb1Controller,
          builder: (_, __) => Positioned(
            top: -100 + (_orb1Controller.value * 50),
            left: -80 + (_orb1Controller.value * 30),
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primary.withOpacity(0.3), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _orb2Controller,
          builder: (_, __) => Positioned(
            bottom: -100 + (_orb2Controller.value * 60),
            right: -80 + (_orb2Controller.value * 40),
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.accent.withOpacity(0.2), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _orb3Controller,
          builder: (_, __) => Positioned(
            top: MediaQuery.of(context).size.height * 0.4 + (_orb3Controller.value * 30),
            left: MediaQuery.of(context).size.width * 0.6,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primaryLight.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
      ),
    )
        .animate()
        .scale(begin: const Offset(0.5, 0.5), duration: 700.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 500.ms);
  }

  Widget _buildAppName() {
    return const Text(
      'VK OS',
      style: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -1.5,
        fontFamily: 'Inter',
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildTagline() {
    return Text(
      'Your Life, Organized, Intelligent.',
      style: TextStyle(
        fontSize: 13,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
        fontFamily: 'Inter',
      ),
    ).animate(delay: 500.ms).fadeIn(duration: 600.ms);
  }

  Widget _buildLoader() {
    return SizedBox(
      width: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          backgroundColor: AppColors.darkBorder,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 2,
        ),
      ),
    ).animate(delay: 600.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildVersionTag() {
    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: Text(
        'v1.0.0',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Inter'),
      ).animate(delay: 800.ms).fadeIn(),
    );
  }
}
