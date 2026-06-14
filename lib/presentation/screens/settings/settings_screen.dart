import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';
import 'package:lifeos/services/api/api_client.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppStyle.bg(context),
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppStyle.text(context))),
        backgroundColor: AppStyle.surface(context),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: AppStyle.border(context), height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section('Account', [
            _Tile(context, Icons.lock_outline, 'Change Password', 'Update your password', AppColors.primary, () => _showChangePassword(context, ref)),
            _Tile(context, Icons.pin_outlined, 'Set PIN', 'Quick access 4-digit PIN', AppColors.accent, () => _showSetPin(context, ref)),
            _Tile(context, Icons.fingerprint, 'Biometric Login', 'Enable fingerprint / Face ID', AppColors.success, () => _showBiometric(context)),
          ]),
          const SizedBox(height: 16),
          _Section('About', [
            _Tile(context, Icons.code_outlined, 'GitHub', 'github.com/vishalkarpe1234', AppColors.lightText, () => _openGithub()),
            _Tile(context, Icons.info_outline, 'App Version', 'VK LifeOS v1.0.0', AppColors.lightTextSub, () {}),
            _Tile(context, Icons.shield_outlined, 'Privacy Policy', '', AppColors.lightTextSub, () {}),
          ]),
          const SizedBox(height: 16),
          _Section('Session', [
            _Tile(context, Icons.logout_rounded, 'Sign Out', 'Sign out of your account', AppColors.error, () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppStyle.card(context),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text('Sign Out?', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppStyle.text(context))),
                  content: Text('You will be returned to the login screen.', style: TextStyle(fontFamily: 'Inter', color: AppStyle.textSub(context))),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: AppStyle.textMuted(context), fontFamily: 'Inter'))),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              }
            }),
          ]),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _Section(String title, List<Widget> tiles) {
    return Builder(builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppStyle.textMuted(ctx), fontFamily: 'Inter', letterSpacing: 0.8)),
        ),
        Container(
          decoration: AppStyle.cardDecor(ctx, radius: BorderRadius.circular(16)),
          child: Column(
            children: tiles.asMap().entries.map((e) => Column(
              children: [
                e.value,
                if (e.key < tiles.length - 1) Divider(color: AppStyle.divider(ctx), height: 1, indent: 52),
              ],
            )).expand((w) => w.children).toList(),
          ),
        ),
      ],
    ));
  }

  Widget _Tile(BuildContext context, IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title, style: TextStyle(color: color == AppColors.error ? AppColors.error : AppStyle.text(context), fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
      subtitle: sub.isNotEmpty ? Text(sub, style: TextStyle(color: AppStyle.textMuted(context), fontSize: 11, fontFamily: 'Inter')) : null,
      trailing: color != AppColors.error ? Icon(Icons.chevron_right, color: AppStyle.textMuted(context), size: 18) : null,
      onTap: onTap,
    );
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppStyle.card(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Change Password', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppStyle.text(ctx))),
          content: SizedBox(
            width: 320,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(ctx, currentCtrl, 'Current Password', obscure: true),
                  const SizedBox(height: 12),
                  _dialogField(ctx, newCtrl, 'New Password', obscure: true, validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null),
                  const SizedBox(height: 12),
                  _dialogField(ctx, confirmCtrl, 'Confirm Password', obscure: true, validator: (v) => v != newCtrl.text ? 'Passwords do not match' : null),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppStyle.textMuted(ctx), fontFamily: 'Inter'))),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('/api/v1/auth/change-password', data: {'current_password': currentCtrl.text, 'new_password': newCtrl.text});
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password changed successfully!'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Update', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetPin(BuildContext context, WidgetRef ref) {
    final passwordCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppStyle.card(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Set PIN', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppStyle.text(ctx))),
        content: SizedBox(
          width: 320,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Enter your current password to set a PIN.', style: TextStyle(fontSize: 13, color: AppStyle.textSub(ctx), fontFamily: 'Inter')),
                const SizedBox(height: 12),
                _dialogField(ctx, passwordCtrl, 'Current Password', obscure: true),
                const SizedBox(height: 12),
                _dialogField(ctx, pinCtrl, '4-digit PIN', keyboardType: TextInputType.number, maxLength: 4, validator: (v) => (v?.length ?? 0) != 4 ? 'PIN must be 4 digits' : null),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppStyle.textMuted(ctx), fontFamily: 'Inter'))),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final dio = ref.read(dioProvider);
                await dio.post('/api/v1/auth/set-pin', data: {'password': passwordCtrl.text, 'pin': pinCtrl.text});
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN set successfully!'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Set PIN', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showBiometric(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biometric setup coming soon'), backgroundColor: AppColors.info),
    );
  }

  void _openGithub() async {
    final uri = Uri.parse('https://github.com/vishalkarpe1234');
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _dialogField(BuildContext ctx, TextEditingController ctrl, String label, {bool obscure = false, TextInputType? keyboardType, int? maxLength, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: TextStyle(color: AppStyle.text(ctx), fontFamily: 'Inter', fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        filled: true,
        fillColor: AppStyle.surface(ctx),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppStyle.border(ctx))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppStyle.border(ctx))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        labelStyle: TextStyle(color: AppStyle.textSub(ctx), fontFamily: 'Inter'),
      ),
      validator: validator,
    );
  }
}
