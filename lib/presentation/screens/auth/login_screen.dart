import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/core/constants/app_constants.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool adminMode;
  const LoginScreen({super.key, this.adminMode = false});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _urlCtrl = TextEditingController(text: AppConstants.defaultBaseUrl);
  bool _obscure = true;
  bool _isAdminMode = false;
  bool _showServer = false;

  @override
  void initState() {
    super.initState();
    _isAdminMode = widget.adminMode;
    if (_isAdminMode) _emailCtrl.text = 'hivetech1010@gmail.com';
  }

  @override
  void dispose() { _emailCtrl.dispose(); _passwordCtrl.dispose(); _urlCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authStateProvider.notifier).login(_emailCtrl.text.trim(), _passwordCtrl.text, _urlCtrl.text.trim());
    if (!mounted) return;
    if (success) {
      final auth = ref.read(authStateProvider);
      context.go(auth.isAdmin ? '/admin' : '/notes');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: Colors.white,
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 6))]),
                child: ClipRRect(borderRadius: BorderRadius.circular(22),
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.contain)),
              )),
              const SizedBox(height: 16),
              const Center(child: Text('VK OS', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.text, fontFamily: 'Inter', letterSpacing: -0.8))),
              const SizedBox(height: 4),
              Center(child: Text(_isAdminMode ? 'Admin Panel Access' : 'Welcome back', style: const TextStyle(fontSize: 14, color: AppColors.textSub, fontFamily: 'Inter'))),
              if (_isAdminMode) ...[
                const SizedBox(height: 8),
                Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Admin Mode', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                )),
              ],
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.text, fontFamily: 'Inter'),
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20)),
                      validator: (v) => (v?.isEmpty ?? true) ? 'Email required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      style: const TextStyle(color: AppColors.text, fontFamily: 'Inter'),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20),
                        suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20), onPressed: () => setState(() => _obscure = !_obscure)),
                      ),
                      validator: (v) => (v?.isEmpty ?? true) ? 'Password required' : null,
                      onFieldSubmitted: (_) => _login(),
                    ),
                    if (auth.error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withOpacity(0.3))),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(auth.error!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontFamily: 'Inter'))),
                        ]),
                      ),
                    ],
                    TextButton(
                      onPressed: () => setState(() => _showServer = !_showServer),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        const Icon(Icons.dns_outlined, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        const Text('Server', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Inter')),
                      ]),
                    ),
                    if (_showServer) ...[
                      TextFormField(
                        controller: _urlCtrl,
                        style: const TextStyle(color: AppColors.text, fontFamily: 'Inter', fontSize: 13),
                        decoration: const InputDecoration(labelText: 'API URL', prefixIcon: Icon(Icons.link, color: AppColors.textMuted, size: 18)),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity,
                      child: auth.isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : ElevatedButton(onPressed: _login, child: Text(_isAdminMode ? 'Enter Admin Panel' : 'Sign In')),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go('/forgot-password'),
                      child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primary, fontFamily: 'Inter', fontSize: 14)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!_isAdminMode) Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?", style: TextStyle(color: AppColors.textSub, fontFamily: 'Inter', fontSize: 14)),
                  TextButton(onPressed: () => context.go('/register'), child: const Text('Register', style: TextStyle(color: AppColors.primary, fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14))),
                ],
              ),
              const SizedBox(height: 40),
              Center(child: _isAdminMode
                ? TextButton(onPressed: () => setState(() { _isAdminMode = false; _emailCtrl.clear(); }), child: const Text('← Back to User Login', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontFamily: 'Inter')))
                : TextButton(onPressed: () => setState(() { _isAdminMode = true; _emailCtrl.text = 'hivetech1010@gmail.com'; }), child: const Text('Admin', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Inter'))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
