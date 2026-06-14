import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyOtpScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final List<TextEditingController> _ctrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focuses = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  bool _resending = false;
  String? _error;
  int _countdown = 60;
  late final _timer = Stream.periodic(const Duration(seconds: 1)).listen((_) {
    if (_countdown > 0) setState(() => _countdown--);
  });

  @override
  void dispose() {
    _timer.cancel();
    for (final c in _ctrls) { c.dispose(); }
    for (final f in _focuses) { f.dispose(); }
    super.dispose();
  }

  String get _otp => _ctrls.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length != 6) { setState(() => _error = 'Enter 6-digit OTP'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/v1/auth/verify-email', data: {'email': widget.email, 'otp': _otp});
      if (mounted) context.go('/login');
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['detail'] ?? 'Invalid OTP';
      setState(() => _error = msg.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_countdown > 0) return;
    setState(() { _resending = true; _countdown = 60; });
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/v1/auth/resend-otp', data: {'email': widget.email, 'purpose': 'verify_email'});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP resent!'), backgroundColor: AppColors.success));
    } catch (_) {} finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maskedEmail = _maskEmail(widget.email);

    return Scaffold(
      backgroundColor: AppStyle.bg(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_rounded, color: AppStyle.text(context)),
                onPressed: () => context.go('/register'),
              ),
              const SizedBox(height: 32),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.mark_email_read_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 20),
              Text('Verify Email', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppStyle.text(context), fontFamily: 'Inter', letterSpacing: -0.5)),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: AppStyle.textSub(context), fontFamily: 'Inter', fontSize: 14, height: 1.5),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to\n'),
                    TextSpan(text: maskedEmail, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _OtpBox(
                  controller: _ctrls[i],
                  focusNode: _focuses[i],
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 5) _focuses[i + 1].requestFocus();
                    if (v.isEmpty && i > 0) _focuses[i - 1].requestFocus();
                    setState(() {});
                  },
                )),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.error.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontFamily: 'Inter')),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_loading || _otp.length != 6) ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Verify & Continue', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: _countdown > 0
                    ? Text('Resend OTP in ${_countdown}s', style: TextStyle(color: AppStyle.textMuted(context), fontFamily: 'Inter', fontSize: 13))
                    : TextButton(
                        onPressed: _resending ? null : _resend,
                        child: _resending
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Resend OTP', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    if (name.length <= 3) return '${name[0]}***@${parts[1]}';
    return '${name.substring(0, 2)}${'*' * (name.length - 3)}${name[name.length - 1]}@${parts[1]}';
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  const _OtpBox({required this.controller, required this.focusNode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppStyle.text(context), fontFamily: 'Inter'),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppStyle.card(context),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppStyle.border(context))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppStyle.border(context))),
          focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.primary, width: 2)),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
