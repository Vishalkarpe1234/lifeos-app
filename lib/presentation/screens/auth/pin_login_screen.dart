import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';
import 'package:lifeos/core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PINLoginScreen extends ConsumerStatefulWidget {
  const PINLoginScreen({super.key});

  @override
  ConsumerState<PINLoginScreen> createState() => _PINLoginScreenState();
}

class _PINLoginScreenState extends ConsumerState<PINLoginScreen> {
  String _pin = '';
  bool _hasError = false;
  final _storage = const FlutterSecureStorage();
  String? _email;
  String? _baseUrl;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    _email = await _storage.read(key: AppConstants.keyUserEmail);
    _baseUrl = await _storage.read(key: AppConstants.keyBaseUrl) ?? AppConstants.defaultBaseUrl;
    setState(() {});
  }

  void _addDigit(String digit) {
    if (_pin.length >= 6) return;
    setState(() {
      _pin += digit;
      _hasError = false;
    });
    if (_pin.length == 6) _submit();
  }

  void _removeDigit() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (_email == null) {
      setState(() => _hasError = true);
      return;
    }
    final success = await ref.read(authStateProvider.notifier).loginWithPIN(_email!, _pin, _baseUrl!);
    if (success && mounted) {
      context.go('/dashboard');
    } else {
      setState(() { _pin = ''; _hasError = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            _buildHeader(),
            const SizedBox(height: 48),
            _buildPinDots(),
            if (_hasError) ...[
              const SizedBox(height: 16),
              Text('Incorrect PIN', style: TextStyle(color: AppColors.error, fontSize: 14, fontFamily: 'Inter')),
            ],
            const Spacer(),
            _buildKeypad(auth.isLoading),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => context.go('/login'),
              child: Text('Use Password Instead', style: TextStyle(color: AppColors.primary, fontFamily: 'Inter')),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20)],
          ),
          child: const Icon(Icons.pin_outlined, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        const Text('Enter PIN', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
        const SizedBox(height: 8),
        Text(_email ?? 'Enter your PIN to unlock', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontFamily: 'Inter')),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1);
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 16, height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: i < _pin.length ? (_hasError ? AppColors.error : AppColors.primary) : AppColors.darkBorder,
          boxShadow: i < _pin.length ? [BoxShadow(color: (_hasError ? AppColors.error : AppColors.primary).withOpacity(0.4), blurRadius: 8)] : null,
        ),
      ).animate(target: i < _pin.length ? 1 : 0).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0))),
    );
  }

  Widget _buildKeypad(bool isLoading) {
    final keys = ['1','2','3','4','5','6','7','8','9','','0','⌫'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
        ),
        itemCount: 12,
        itemBuilder: (_, i) {
          final k = keys[i];
          if (k.isEmpty) return const SizedBox();
          return _buildKey(k, isLoading);
        },
      ),
    );
  }

  Widget _buildKey(String key, bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : () {
        if (key == '⌫') { _removeDigit(); } else { _addDigit(key); }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder, width: 0.5),
        ),
        child: Center(
          child: Text(
            key,
            style: TextStyle(
              fontSize: key == '⌫' ? 22 : 24,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}
