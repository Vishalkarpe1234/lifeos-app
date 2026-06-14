import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int _step = 0; // 0=email, 1=otp, 2=new password
  final _emailCtrl = TextEditingController();
  final List<TextEditingController> _otpCtrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  String? _resetToken;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFocus) f.dispose();
    super.dispose();
  }

  String get _otp => _otpCtrls.map((c) => c.text).join();

  Future<void> _sendOtp() async {
    if (_emailCtrl.text.trim().isEmpty) { setState(() => _error = 'Enter your email'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/v1/auth/forgot-password', data: {'email': _emailCtrl.text.trim().toLowerCase()});
      setState(() => _step = 1);
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['detail'] ?? 'Email not found';
      setState(() => _error = msg.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != 6) { setState(() => _error = 'Enter 6-digit OTP'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post('/api/v1/auth/verify-reset-otp', data: {
        'email': _emailCtrl.text.trim().toLowerCase(),
        'otp': _otp,
      });
      _resetToken = res.data['reset_token'];
      setState(() => _step = 2);
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['detail'] ?? 'Invalid OTP';
      setState(() => _error = msg.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_passCtrl.text.length < 8) { setState(() => _error = 'Password too short'); return; }
    if (_passCtrl.text != _confirmCtrl.text) { setState(() => _error = 'Passwords do not match'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/v1/auth/reset-password', data: {
        'reset_token': _resetToken,
        'new_password': _passCtrl.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successfully!'), backgroundColor: AppColors.success));
        context.go('/login');
      }
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['detail'] ?? 'Reset failed';
      setState(() => _error = msg.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_rounded, color: AppStyle.text(context)),
                onPressed: () => _step > 0 ? setState(() { _step--; _error = null; }) : context.go('/login'),
              ),
              const SizedBox(height: 32),

              // Step indicator
              Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    height: 4, margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: i <= _step ? AppColors.primary : AppStyle.border(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 32),

              if (_step == 0) _buildEmailStep(context),
              if (_step == 1) _buildOtpStep(context),
              if (_step == 2) _buildPasswordStep(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.lock_reset_rounded, color: AppColors.warning, size: 28),
        ),
        const SizedBox(height: 20),
        Text('Forgot Password?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppStyle.text(context), fontFamily: 'Inter')),
        const SizedBox(height: 8),
        Text("Enter your email and we'll send you a reset code.", style: TextStyle(color: AppStyle.textSub(context), fontFamily: 'Inter', fontSize: 14, height: 1.5)),
        const SizedBox(height: 36),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: AppStyle.text(context), fontFamily: 'Inter'),
          decoration: InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined, color: AppStyle.textMuted(context), size: 20),
            filled: true, fillColor: AppStyle.card(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppStyle.border(context))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppStyle.border(context))),
            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.primary, width: 2)),
            labelStyle: TextStyle(color: AppStyle.textSub(context), fontFamily: 'Inter'),
          ),
        ),
        if (_error != null) ...[const SizedBox(height: 12), _buildError()],
        const SizedBox(height: 28),
        _buildButton('Send Reset Code', _sendOtp),
      ],
    );
  }

  Widget _buildOtpStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.sms_rounded, color: AppColors.primary, size: 28),
        ),
        const SizedBox(height: 20),
        Text('Enter OTP', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppStyle.text(context), fontFamily: 'Inter')),
        const SizedBox(height: 8),
        Text("A 6-digit code was sent to ${_emailCtrl.text}", style: TextStyle(color: AppStyle.textSub(context), fontFamily: 'Inter', fontSize: 14, height: 1.5)),
        const SizedBox(height: 36),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => SizedBox(
            width: 46, height: 56,
            child: TextField(
              controller: _otpCtrls[i],
              focusNode: _otpFocus[i],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppStyle.text(context), fontFamily: 'Inter'),
              decoration: InputDecoration(
                counterText: '', filled: true, fillColor: AppStyle.card(context),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppStyle.border(context))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppStyle.border(context))),
                focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.primary, width: 2)),
              ),
              onChanged: (v) {
                if (v.isNotEmpty && i < 5) _otpFocus[i + 1].requestFocus();
                if (v.isEmpty && i > 0) _otpFocus[i - 1].requestFocus();
                setState(() {});
              },
            ),
          )),
        ),
        if (_error != null) ...[const SizedBox(height: 12), _buildError()],
        const SizedBox(height: 28),
        _buildButton('Verify OTP', _verifyOtp),
      ],
    );
  }

  Widget _buildPasswordStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.lock_rounded, color: AppColors.success, size: 28),
        ),
        const SizedBox(height: 20),
        Text('New Password', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppStyle.text(context), fontFamily: 'Inter')),
        const SizedBox(height: 8),
        Text('Create a strong new password.', style: TextStyle(color: AppStyle.textSub(context), fontFamily: 'Inter', fontSize: 14)),
        const SizedBox(height: 36),
        TextField(
          controller: _passCtrl,
          obscureText: _obscure,
          style: TextStyle(color: AppStyle.text(context), fontFamily: 'Inter'),
          decoration: InputDecoration(
            labelText: 'New Password',
            prefixIcon: Icon(Icons.lock_outline, color: AppStyle.textMuted(context), size: 20),
            suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppStyle.textMuted(context), size: 20), onPressed: () => setState(() => _obscure = !_obscure)),
            filled: true, fillColor: AppStyle.card(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppStyle.border(context))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppStyle.border(context))),
            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.primary, width: 2)),
            labelStyle: TextStyle(color: AppStyle.textSub(context), fontFamily: 'Inter'),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmCtrl,
          obscureText: _obscure,
          style: TextStyle(color: AppStyle.text(context), fontFamily: 'Inter'),
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: Icon(Icons.lock_outline, color: AppStyle.textMuted(context), size: 20),
            filled: true, fillColor: AppStyle.card(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppStyle.border(context))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppStyle.border(context))),
            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.primary, width: 2)),
            labelStyle: TextStyle(color: AppStyle.textSub(context), fontFamily: 'Inter'),
          ),
        ),
        if (_error != null) ...[const SizedBox(height: 12), _buildError()],
        const SizedBox(height: 28),
        _buildButton('Reset Password', _resetPassword),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.error.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontFamily: 'Inter'))),
        ],
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
      ),
    );
  }
}
