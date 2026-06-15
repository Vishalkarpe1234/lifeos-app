import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginState();
}

class _LoginState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  bool _adminMode = false;

  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  void _setAdmin() {
    setState(() { _adminMode = true; _email.text = 'hivetech1010@gmail.com'; _pass.clear(); });
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).login(_email.text.trim(), _pass.text);
    if (!mounted) return;
    if (ok) {
      final auth = ref.read(authProvider);
      context.go(auth.isAdmin ? '/admin' : '/notes');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 80, height: 80,
            decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: C.primary.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 6))]),
            child: ClipRRect(borderRadius: BorderRadius.circular(20),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain)))),
          const SizedBox(height: 20),
          Text(_adminMode ? 'Admin Panel' : 'Welcome Back',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: C.text, fontFamily: 'Inter')),
          const SizedBox(height: 4),
          Text(_adminMode ? 'Sign in as administrator' : 'Sign in to VK OS',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: C.textSub, fontFamily: 'Inter')),
          const SizedBox(height: 36),
          Form(key: _form, child: Column(children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.email_outlined, size: 20)),
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pass,
              obscureText: _hide,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _login(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: () => setState(() => _hide = !_hide)),
              ),
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: C.error.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: C.error.withOpacity(0.25))),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: C.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(auth.error!, style: const TextStyle(color: C.error, fontSize: 13, fontFamily: 'Inter'))),
                ])),
            ],
            const SizedBox(height: 22),
            SizedBox(width: double.infinity,
              child: auth.loading
                ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                : ElevatedButton(onPressed: _login, child: Text(_adminMode ? 'Sign In as Admin' : 'Sign In'))),
          ])),
          const SizedBox(height: 16),
          if (!_adminMode) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text("Don't have an account?", style: TextStyle(color: C.textSub, fontSize: 14, fontFamily: 'Inter')),
            TextButton(onPressed: () => context.go('/register'),
              child: const Text('Register', style: TextStyle(color: C.primary, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Inter'))),
          ]),
          if (_adminMode) TextButton(
            onPressed: () => setState(() { _adminMode = false; _email.clear(); _pass.clear(); }),
            child: const Text('← Back to user login', style: TextStyle(color: C.textSub, fontSize: 12, fontFamily: 'Inter'))),
          const SizedBox(height: 40),
          if (!_adminMode) Center(child: GestureDetector(
            onTap: _setAdmin,
            child: const Text('admin', style: TextStyle(fontSize: 10, color: C.textMuted, fontFamily: 'Inter', decoration: TextDecoration.underline)),
          )),
        ]),
      )),
    );
  }
}
