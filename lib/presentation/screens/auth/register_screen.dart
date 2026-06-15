import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterState();
}

class _RegisterState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _hide = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _name.dispose(); _email.dispose(); _pass.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/v1/auth/register', data: {
        'full_name': _name.text.trim(),
        'email': _email.text.trim().toLowerCase(),
        'password': _pass.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created! Please sign in.'), backgroundColor: C.success));
        context.go('/login');
      }
    } on DioException catch (e) {
      setState(() => _error = extractError(e));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          IconButton(alignment: Alignment.centerLeft, icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.go('/login')),
          const SizedBox(height: 12),
          const Text('Create Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: C.text, fontFamily: 'Inter')),
          const SizedBox(height: 4),
          const Text('Join VK OS today', style: TextStyle(fontSize: 14, color: C.textSub, fontFamily: 'Inter')),
          const SizedBox(height: 32),
          Form(key: _form, child: Column(children: [
            TextFormField(controller: _name, textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline, size: 20)),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
            const SizedBox(height: 14),
            TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.email_outlined, size: 20)),
              validator: (v) { if (v?.isEmpty ?? true) return 'Required'; if (!v!.contains('@')) return 'Invalid email'; return null; }),
            const SizedBox(height: 14),
            TextFormField(controller: _pass, obscureText: _hide, textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: 'Password (min 8 chars)', prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: () => setState(() => _hide = !_hide))),
              validator: (v) => (v?.length ?? 0) < 8 ? 'Min 8 characters' : null),
            const SizedBox(height: 14),
            TextFormField(controller: _confirm, obscureText: _hide, textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _register(),
              decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline, size: 20)),
              validator: (v) => v != _pass.text ? 'Passwords do not match' : null),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: C.error.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: Text(_error!, style: const TextStyle(color: C.error, fontSize: 13, fontFamily: 'Inter'))),
            ],
            const SizedBox(height: 22),
            SizedBox(width: double.infinity,
              child: _loading
                ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                : ElevatedButton(onPressed: _register, child: const Text('Create Account'))),
          ])),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Already have an account?', style: TextStyle(color: C.textSub, fontSize: 14, fontFamily: 'Inter')),
            TextButton(onPressed: () => context.go('/login'),
              child: const Text('Sign In', style: TextStyle(color: C.primary, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Inter'))),
          ]),
        ]),
      )),
    );
  }
}
