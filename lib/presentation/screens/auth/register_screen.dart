import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/v1/auth/register', data: {
        'full_name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim().toLowerCase(),
        'password': _passCtrl.text,
      });
      if (mounted) {
        context.go('/verify-otp', extra: _emailCtrl.text.trim().toLowerCase());
      }
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['detail'] ?? 'Registration failed';
      setState(() => _error = msg.toString());
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
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
                onPressed: () => context.go('/'),
              ),
              const SizedBox(height: 24),

              // Header
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppStyle.accentShadow(context, AppColors.primary),
                ),
                child: const Center(child: Text('V∞', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Inter'))),
              ),
              const SizedBox(height: 20),
              Text('Create Account', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppStyle.text(context), fontFamily: 'Inter', letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text('Join VishalOS and start your journey', style: TextStyle(fontSize: 14, color: AppStyle.textSub(context), fontFamily: 'Inter')),
              const SizedBox(height: 36),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildField(context, _nameCtrl, 'Full Name', Icons.person_outline, validator: (v) => (v?.trim().isEmpty ?? true) ? 'Enter your name' : null),
                    const SizedBox(height: 16),
                    _buildField(context, _emailCtrl, 'Email Address', Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v?.trim().isEmpty ?? true) return 'Enter your email';
                        if (!v!.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildField(context, _passCtrl, 'Password', Icons.lock_outline,
                      obscure: _obscurePass,
                      suffix: IconButton(
                        icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppStyle.textMuted(context), size: 20),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                      validator: (v) {
                        if ((v?.length ?? 0) < 8) return 'Min 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildField(context, _confirmCtrl, 'Confirm Password', Icons.lock_outline,
                      obscure: _obscureConfirm,
                      suffix: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppStyle.textMuted(context), size: 20),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.10), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withOpacity(0.3))),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontFamily: 'Inter'))),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppStyle.accentShadow(context, AppColors.primary),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: _loading
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?', style: TextStyle(color: AppStyle.textSub(context), fontFamily: 'Inter', fontSize: 14)),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Sign In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontFamily: 'Inter', fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(BuildContext context, TextEditingController ctrl, String label, IconData icon, {
    bool obscure = false, TextInputType? keyboardType, Widget? suffix, String? Function(String?)? validator
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(color: AppStyle.text(context), fontFamily: 'Inter', fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppStyle.textMuted(context), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppStyle.card(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppStyle.border(context))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppStyle.border(context))),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.primary, width: 2)),
        labelStyle: TextStyle(color: AppStyle.textSub(context), fontFamily: 'Inter'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      validator: validator,
    );
  }
}
