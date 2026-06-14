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
  bool _obscure = true;
  bool _obscureC = true;
  String? _error;

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/v1/auth/register', data: {'full_name': _nameCtrl.text.trim(), 'email': _emailCtrl.text.trim().toLowerCase(), 'password': _passCtrl.text});
      if (mounted) context.go('/verify-otp', extra: _emailCtrl.text.trim().toLowerCase());
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['detail'] ?? 'Registration failed';
      setState(() => _error = msg.toString());
    } catch (_) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.text, size: 20), onPressed: () => context.go('/login')),
              ]),
              const SizedBox(height: 16),
              Center(child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white,
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 6))]),
                child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.asset('assets/images/logo.png', fit: BoxFit.contain)),
              )),
              const SizedBox(height: 16),
              const Center(child: Text('Create Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.text, fontFamily: 'Inter', letterSpacing: -0.5))),
              const SizedBox(height: 6),
              const Center(child: Text('Join VK OS', style: TextStyle(fontSize: 14, color: AppColors.textSub, fontFamily: 'Inter'))),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(children: [
                  TextFormField(controller: _nameCtrl, style: const TextStyle(color: AppColors.text, fontFamily: 'Inter'),
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted, size: 20)),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Name required' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: AppColors.text, fontFamily: 'Inter'),
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20)),
                    validator: (v) { if (v?.isEmpty ?? true) return 'Email required'; if (!v!.contains('@')) return 'Invalid email'; return null; }),
                  const SizedBox(height: 16),
                  TextFormField(controller: _passCtrl, obscureText: _obscure, style: const TextStyle(color: AppColors.text, fontFamily: 'Inter'),
                    decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20),
                      suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20), onPressed: () => setState(() => _obscure = !_obscure))),
                    validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _confirmCtrl, obscureText: _obscureC, style: const TextStyle(color: AppColors.text, fontFamily: 'Inter'),
                    decoration: InputDecoration(labelText: 'Confirm Password', prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20),
                      suffixIcon: IconButton(icon: Icon(_obscureC ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20), onPressed: () => setState(() => _obscureC = !_obscureC))),
                    validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withOpacity(0.3))),
                      child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontFamily: 'Inter'))),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(width: double.infinity, child: _loading ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) : ElevatedButton(onPressed: _register, child: const Text('Create Account'))),
                ]),
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Already have an account?', style: TextStyle(color: AppColors.textSub, fontFamily: 'Inter', fontSize: 14)),
                TextButton(onPressed: () => context.go('/login'), child: const Text('Sign In', style: TextStyle(color: AppColors.primary, fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14))),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
