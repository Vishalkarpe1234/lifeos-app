import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';

class VerifyOTPScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyOTPScreen({super.key, required this.email});
  @override
  ConsumerState<VerifyOTPScreen> createState() => _VerifyOTPScreenState();
}

class _VerifyOTPScreenState extends ConsumerState<VerifyOTPScreen> {
  final List<TextEditingController> _ctrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _error;
  int _resendSeconds = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendSeconds > 0) {
        setState(() => _resendSeconds--);
        _startTimer();
      }
    });
  }

  @override
  void dispose() { for (final c in _ctrls) c.dispose(); for (final n in _nodes) n.dispose(); super.dispose(); }

  String get _otp => _ctrls.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length < 6) { setState(() => _error = 'Enter the 6-digit code'); return; }
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
    if (_resendSeconds > 0) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/v1/auth/resend-otp', data: {'email': widget.email, 'purpose': 'verify_email'});
      setState(() => _resendSeconds = 60);
      _startTimer();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP resent!'), backgroundColor: AppColors.success));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final masked = widget.email.length > 4 ? '${widget.email.substring(0, 2)}***${widget.email.substring(widget.email.indexOf('@'))}' : widget.email;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              IconButton(alignment: Alignment.centerLeft, icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.text, size: 20), onPressed: () => context.go('/register')),
              const SizedBox(height: 24),
              Container(width: 64, height: 64,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 32)),
              const SizedBox(height: 24),
              const Text('Verify Email', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.text, fontFamily: 'Inter')),
              const SizedBox(height: 8),
              Text('We sent a 6-digit code to\n$masked', style: const TextStyle(fontSize: 14, color: AppColors.textSub, fontFamily: 'Inter')),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => SizedBox(
                  width: 48, height: 58,
                  child: TextFormField(
                    controller: _ctrls[i],
                    focusNode: _nodes[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text, fontFamily: 'Inter'),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty && i < 5) FocusScope.of(context).requestFocus(_nodes[i + 1]);
                      if (v.isEmpty && i > 0) FocusScope.of(context).requestFocus(_nodes[i - 1]);
                      if (i == 5 && v.isNotEmpty) _verify();
                    },
                  ),
                )),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: AppColors.error, fontFamily: 'Inter', fontSize: 13), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 28),
              SizedBox(width: double.infinity, child: _loading ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) : ElevatedButton(onPressed: _verify, child: const Text('Verify & Continue'))),
              const SizedBox(height: 20),
              Center(child: _resendSeconds > 0
                ? Text('Resend OTP in ${_resendSeconds}s', style: const TextStyle(color: AppColors.textMuted, fontFamily: 'Inter', fontSize: 13))
                : TextButton(onPressed: _resend, child: const Text('Resend OTP', style: TextStyle(color: AppColors.primary, fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
