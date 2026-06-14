import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';
import 'package:lifeos/presentation/widgets/common/glass_card.dart';
import 'package:lifeos/presentation/widgets/common/loading_button.dart';
import 'package:lifeos/core/constants/app_constants.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _urlCtrl = TextEditingController(text: AppConstants.defaultBaseUrl);
  bool _obscurePassword = true;
  bool _showAdvanced = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authStateProvider.notifier).login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      _urlCtrl.text.trim(),
    );
    if (success && mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          _buildBackground(size),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  _buildHeader(),
                  const SizedBox(height: 48),
                  _buildLoginCard(auth),
                  const SizedBox(height: 24),
                  _buildAlternateLogins(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Size size) {
    return Stack(
      children: [
        Positioned(
          top: -150,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.primary.withOpacity(0.25), Colors.transparent]),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          right: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.accent.withOpacity(0.2), Colors.transparent]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: AppColors.primaryGradient,
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 24, spreadRadius: 2)],
          ),
          child: const Icon(Icons.all_inclusive_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        const Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5, fontFamily: 'Inter')),
        const SizedBox(height: 8),
        Text('Sign in to your LifeOS', style: TextStyle(fontSize: 15, color: AppColors.textSecondary, fontFamily: 'Inter')),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildLoginCard(AuthState auth) {
    return GlassCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Sign In', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'admin@lifeos.app',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Email required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Password required' : null,
              onFieldSubmitted: (_) => _login(),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(auth.error!, style: TextStyle(color: AppColors.error, fontSize: 13, fontFamily: 'Inter'))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Server Settings', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'Inter')),
                  Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more, color: AppColors.textMuted, size: 16),
                ],
              ),
            ),
            if (_showAdvanced) ...[
              TextFormField(
                controller: _urlCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Inter'),
                decoration: const InputDecoration(labelText: 'API Server URL', prefixIcon: Icon(Icons.dns_outlined, size: 20)),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            LoadingButton(
              isLoading: auth.isLoading,
              onPressed: _login,
              child: const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
            ),
          ],
        ),
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildAlternateLogins() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildAltLoginButton(
          icon: Icons.pin_outlined,
          label: 'PIN Login',
          onTap: () => context.go('/pin-login'),
        ),
        const SizedBox(width: 16),
        _buildAltLoginButton(
          icon: Icons.fingerprint,
          label: 'Biometric',
          onTap: () => context.go('/biometric'),
        ),
      ],
    ).animate(delay: 400.ms).fadeIn();
  }

  Widget _buildAltLoginButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorder, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
