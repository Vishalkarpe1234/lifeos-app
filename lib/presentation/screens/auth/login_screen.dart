import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/core/constants/app_constants.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';
import 'package:lifeos/presentation/widgets/common/loading_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'karpevishal2712001@gmail.com');
  final _passwordCtrl = TextEditingController();
  final _urlCtrl = TextEditingController(text: AppConstants.defaultBaseUrl);
  bool _obscure = true;
  bool _showServerSettings = false;
  bool _isAdminMode = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _switchToAdmin() {
    setState(() {
      _isAdminMode = true;
      _emailCtrl.text = 'admin@lifeos.app';
      _passwordCtrl.text = '';
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authStateProvider.notifier).login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      _urlCtrl.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      final auth = ref.read(authStateProvider);
      if (_isAdminMode || (auth.isAdmin)) {
        context.go('/admin');
      } else {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 36),
                  _buildCard(auth),
                  const SizedBox(height: 20),
                  _buildAltButtons(),
                  const SizedBox(height: 32),
                  _buildAdminButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.primary.withOpacity(0.12), Colors.transparent]),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.accent.withOpacity(0.10), Colors.transparent]),
            ),
          ),
        ),
        Positioned(
          top: 200,
          left: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.primary.withOpacity(0.07), Colors.transparent]),
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
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 28, spreadRadius: 2, offset: const Offset(0, 8)),
              BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: const Icon(Icons.all_inclusive_rounded, color: Colors.white, size: 38),
        ),
        const SizedBox(height: 18),
        const Text(
          'VK LifeOS',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.lightText, letterSpacing: -0.8, fontFamily: 'Inter'),
        ),
        const SizedBox(height: 6),
        Text(
          'Vishal Karpe Professional Suite',
          style: TextStyle(fontSize: 14, color: AppColors.lightTextSub, fontFamily: 'Inter', fontWeight: FontWeight.w400),
        ),
        if (_isAdminMode) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings, color: Color(0xFF8B5CF6), size: 14),
                const SizedBox(width: 6),
                const Text('Admin Mode', style: TextStyle(fontSize: 12, color: Color(0xFF8B5CF6), fontWeight: FontWeight.w600, fontFamily: 'Inter')),
              ],
            ),
          ),
        ],
      ],
    ).animate().fadeIn(duration: 700.ms).slideY(begin: -0.08, end: 0);
  }

  Widget _buildCard(AuthState auth) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0x0C1E1E3F), blurRadius: 32, offset: const Offset(0, 10)),
          BoxShadow(color: const Color(0x061E1E3F), blurRadius: 8, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.7)),
      ),
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isAdminMode ? 'Admin Sign In' : 'Welcome Back',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.lightText, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 6),
            Text(
              _isAdminMode ? 'Access the Admin Panel' : 'Sign in to your personal suite',
              style: const TextStyle(fontSize: 13, color: AppColors.lightTextSub, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 24),
            _buildField(
              controller: _emailCtrl,
              label: 'Email',
              hint: 'your@email.com',
              icon: Icons.email_outlined,
              keyboard: TextInputType.emailAddress,
              validator: (v) => v == null || v.isEmpty ? 'Email required' : null,
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _passwordCtrl,
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscure: _obscure,
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.lightTextMuted),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Password required' : null,
              onSubmit: (_) => _login(),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(auth.error!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontFamily: 'Inter'))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _showServerSettings = !_showServerSettings),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.dns_outlined, size: 14, color: AppColors.lightTextMuted),
                    const SizedBox(width: 4),
                    Text('Server Settings', style: TextStyle(fontSize: 12, color: AppColors.lightTextMuted, fontFamily: 'Inter')),
                    Icon(_showServerSettings ? Icons.expand_less : Icons.expand_more, color: AppColors.lightTextMuted, size: 14),
                  ],
                ),
              ),
            ),
            if (_showServerSettings) ...[
              const SizedBox(height: 8),
              _buildField(
                controller: _urlCtrl,
                label: 'API Server URL',
                hint: 'http://10.0.0.1:8000',
                icon: Icons.link_outlined,
              ),
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 20),
            Container(
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
                  BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: LoadingButton(
                isLoading: auth.isLoading,
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _isAdminMode ? 'Enter Admin Panel' : 'Sign In',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter'),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 150.ms).fadeIn(duration: 600.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboard,
    String? Function(String?)? validator,
    void Function(String)? onSubmit,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      onFieldSubmitted: onSubmit,
      style: const TextStyle(color: AppColors.lightText, fontSize: 14, fontFamily: 'Inter'),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppColors.lightTextMuted),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lightBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lightBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error)),
        labelStyle: const TextStyle(color: AppColors.lightTextSub, fontFamily: 'Inter', fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.lightTextMuted, fontFamily: 'Inter', fontSize: 13),
      ),
      validator: validator,
    );
  }

  Widget _buildAltButtons() {
    return Row(
      children: [
        Expanded(
          child: _AltBtn(
            icon: Icons.pin_outlined,
            label: 'PIN Login',
            onTap: () => context.go('/pin-login'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AltBtn(
            icon: Icons.fingerprint,
            label: 'Biometric',
            onTap: () => context.go('/biometric'),
          ),
        ),
      ],
    ).animate(delay: 300.ms).fadeIn();
  }

  Widget _buildAdminButton() {
    if (_isAdminMode) {
      return TextButton.icon(
        onPressed: () => setState(() {
          _isAdminMode = false;
          _emailCtrl.text = 'karpevishal2712001@gmail.com';
          _passwordCtrl.text = '';
        }),
        icon: const Icon(Icons.arrow_back, size: 16),
        label: const Text('Back to User Login', style: TextStyle(fontSize: 13, fontFamily: 'Inter')),
        style: TextButton.styleFrom(foregroundColor: AppColors.lightTextSub),
      );
    }
    return GestureDetector(
      onTap: _switchToAdmin,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
          color: const Color(0xFF8B5CF6).withOpacity(0.06),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF8B5CF6), size: 20),
            const SizedBox(width: 10),
            const Text(
              'Admin Panel',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF8B5CF6), fontFamily: 'Inter'),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: const Color(0xFF8B5CF6).withOpacity(0.7), size: 14),
          ],
        ),
      ),
    ).animate(delay: 400.ms).fadeIn();
  }
}

class _AltBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AltBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightBorder),
          boxShadow: [BoxShadow(color: const Color(0x08000000), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.lightText, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
