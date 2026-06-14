import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';

class BiometricScreen extends ConsumerStatefulWidget {
  const BiometricScreen({super.key});

  @override
  ConsumerState<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends ConsumerState<BiometricScreen> {
  final _auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), _authenticate);
  }

  Future<void> _authenticate() async {
    setState(() { _isAuthenticating = true; _error = null; });
    try {
      final canAuth = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!canAuth) {
        setState(() { _error = 'Biometric not available on this device'; _isAuthenticating = false; });
        return;
      }
      final didAuth = await _auth.authenticate(
        localizedReason: 'Authenticate to access LifeOS',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (didAuth && mounted) {
        context.go('/dashboard');
      } else {
        setState(() { _error = 'Authentication failed'; _isAuthenticating = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isAuthenticating = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBiometricIcon(),
                const SizedBox(height: 32),
                const Text('Biometric Login', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
                const SizedBox(height: 12),
                Text(
                  _isAuthenticating ? 'Place your finger on the sensor...' : (_error ?? 'Tap to authenticate'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary, fontFamily: 'Inter'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _authenticate,
                    child: const Text('Try Again', style: TextStyle(fontFamily: 'Inter')),
                  ),
                ],
                const SizedBox(height: 48),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text('Use Password Instead', style: TextStyle(color: AppColors.primary, fontFamily: 'Inter')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricIcon() {
    return Container(
      width: 120, height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _isAuthenticating
            ? AppColors.primaryGradient
            : LinearGradient(colors: [AppColors.darkCard, AppColors.darkCardElevated]),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(_isAuthenticating ? 0.4 : 0.1), blurRadius: 30, spreadRadius: 5)],
      ),
      child: Icon(Icons.fingerprint, size: 64, color: _isAuthenticating ? Colors.white : AppColors.textMuted),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: _isAuthenticating ? 1.05 : 1.0, duration: 800.ms)
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(0.8, 0.8));
  }
}
