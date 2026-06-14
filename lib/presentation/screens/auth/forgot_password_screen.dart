import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _resetToken;
  int _step = 0; // 0=email, 1=otp, 2=new password

  @override
  void dispose() { _emailCtrl.dispose(); _otpCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _sendOtp() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/v1/auth/forgot-password', data: {'email': _emailCtrl.text.trim().toLowerCase()});
      setState(() { _step = 1; });
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['detail'] ?? 'Failed to send OTP';
      setState(() => _error = msg.toString());
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _verifyOtp() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post('/api/v1/auth/verify-reset-otp', data: {'email': _emailCtrl.text.trim(), 'otp': _otpCtrl.text.trim()});
      _resetToken = res.data['reset_token'];
      setState(() { _step = 2; });
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['detail'] ?? 'Invalid OTP';
      setState(() => _error = msg.toString());
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _resetPassword() async {
    if ((_passCtrl.text.length) < 6) { setState(() => _error = 'Min 6 characters'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/v1/auth/reset-password', data: {'reset_token': _resetToken, 'new_password': _passCtrl.text});
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset! Please login.'), backgroundColor: AppColors.success)); context.go('/login'); }
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['detail'] ?? 'Reset failed';
      setState(() => _error = msg.toString());
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              IconButton(alignment: Alignment.centerLeft, icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.text, size: 20), onPressed: () => context.go('/login')),
              const SizedBox(height: 24),
              Container(width: 64, height: 64,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 32)),
              const SizedBox(height: 20),
              const Text('Reset Password', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.text, fontFamily: 'Inter')),
              const SizedBox(height: 8),
              Text(
                _step == 0 ? 'Enter your email to receive an OTP' : _step == 1 ? 'Enter the OTP sent to your email' : 'Enter your new password',
                style: const TextStyle(fontSize: 14, color: AppColors.textSub, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 36),
              if (_step == 0) TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: AppColors.text, fontFamily: 'Inter'),
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20))),
              if (_step == 1) TextFormField(controller: _otpCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: AppColors.text, fontFamily: 'Inter'),
                decoration: const InputDecoration(labelText: '6-digit OTP', prefixIcon: Icon(Icons.pin_outlined, color: AppColors.textMuted, size: 20))),
              if (_step == 2) TextFormField(controller: _passCtrl, obscureText: true, style: const TextStyle(color: AppColors.text, fontFamily: 'Inter'),
                decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20))),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.error, fontFamily: 'Inter', fontSize: 13)),
              ],
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: _loading ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) : ElevatedButton(
                onPressed: _step == 0 ? _sendOtp : _step == 1 ? _verifyOtp : _resetPassword,
                child: Text(_step == 0 ? 'Send OTP' : _step == 1 ? 'Verify OTP' : 'Reset Password'),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
