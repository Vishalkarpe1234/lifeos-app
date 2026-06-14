import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';
import 'package:lifeos/services/api/api_client.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadProfile(); }

  Future<void> _loadProfile() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/api/v1/profile/');
      if (mounted) setState(() { _profile = res.data; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _changePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    await showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Change Password', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppColors.text)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: currentCtrl, obscureText: true, style: const TextStyle(color: AppColors.text, fontFamily: 'Inter'), decoration: const InputDecoration(labelText: 'Current Password')),
        const SizedBox(height: 12),
        TextField(controller: newCtrl, obscureText: true, style: const TextStyle(color: AppColors.text, fontFamily: 'Inter'), decoration: const InputDecoration(labelText: 'New Password (min 6 chars)')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textSub))),
        ElevatedButton(onPressed: () async {
          if (newCtrl.text.length < 6) return;
          try {
            final dio = ref.read(dioProvider);
            await dio.post('/api/v1/auth/change-password', data: {'current_password': currentCtrl.text, 'new_password': newCtrl.text});
            if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed!'), backgroundColor: AppColors.success)); }
          } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error)); }
        }, child: const Text('Change')),
      ],
    ));
  }

  Future<void> _changeEmail() async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    await showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Change Email', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppColors.text)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: AppColors.text, fontFamily: 'Inter'), decoration: const InputDecoration(labelText: 'New Email')),
        const SizedBox(height: 12),
        TextField(controller: passCtrl, obscureText: true, style: const TextStyle(color: AppColors.text, fontFamily: 'Inter'), decoration: const InputDecoration(labelText: 'Current Password')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textSub))),
        ElevatedButton(onPressed: () async {
          try {
            final dio = ref.read(dioProvider);
            await dio.post('/api/v1/auth/change-email', data: {'email': emailCtrl.text.trim(), 'password': passCtrl.text});
            if (context.mounted) { Navigator.pop(context); _loadProfile(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email updated!'), backgroundColor: AppColors.success)); }
          } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error)); }
        }, child: const Text('Update')),
      ],
    ));
  }

  Future<void> _deleteAccount() async {
    final passCtrl = TextEditingController();
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Account', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppColors.error)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('This will permanently delete your account and all your notes. This cannot be undone.', style: TextStyle(fontFamily: 'Inter', color: AppColors.textSub, fontSize: 13)),
        const SizedBox(height: 12),
        TextField(controller: passCtrl, obscureText: true, style: const TextStyle(color: AppColors.text, fontFamily: 'Inter'), decoration: const InputDecoration(labelText: 'Enter Password to Confirm')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSub))),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), onPressed: () => Navigator.pop(context, true), child: const Text('Delete Account')),
      ],
    ));
    if (confirm == true) {
      try {
        final dio = ref.read(dioProvider);
        await dio.delete('/api/v1/auth/delete-account', data: {'password': passCtrl.text});
        if (mounted) { await ref.read(authStateProvider.notifier).logout(); context.go('/login'); }
      } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error)); }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Sign Out', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppColors.text)),
      content: const Text('Are you sure you want to sign out?', style: TextStyle(fontFamily: 'Inter', color: AppColors.textSub)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSub))),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out')),
      ],
    ));
    if (confirm == true && mounted) {
      await ref.read(authStateProvider.notifier).logout();
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Profile'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.text, size: 20), onPressed: () => context.go('/notes'))),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : ListView(padding: const EdgeInsets.all(20), children: [
            Center(child: Column(children: [
              CircleAvatar(radius: 44, backgroundColor: AppColors.primary,
                backgroundImage: _profile?['profile_photo_url'] != null ? NetworkImage(_profile!['profile_photo_url']) : null,
                child: _profile?['profile_photo_url'] == null ? const Icon(Icons.person, color: Colors.white, size: 44) : null),
              const SizedBox(height: 12),
              Text(_profile?['full_name'] ?? 'User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text, fontFamily: 'Inter')),
              const SizedBox(height: 4),
              Text(_profile?['email_public'] ?? '', style: const TextStyle(fontSize: 14, color: AppColors.textSub, fontFamily: 'Inter')),
            ])),
            const SizedBox(height: 32),
            _buildSection('Account', [
              _buildTile(Icons.lock_outline, 'Change Password', AppColors.primary, _changePassword),
              _buildTile(Icons.email_outlined, 'Change Email', AppColors.primary, _changeEmail),
              _buildTile(Icons.lock_reset_rounded, 'Reset Password (via Email)', AppColors.warning, () => context.go('/forgot-password')),
            ]),
            const SizedBox(height: 16),
            _buildSection('Session', [
              _buildTile(Icons.logout_rounded, 'Sign Out', AppColors.error, _logout, isDestructive: true),
            ]),
            const SizedBox(height: 16),
            _buildSection('Danger Zone', [
              _buildTile(Icons.delete_forever_rounded, 'Delete My Account', AppColors.error, _deleteAccount, isDestructive: true),
            ]),
            const SizedBox(height: 40),
          ]),
    );
  }

  Widget _buildSection(String title, List<Widget> tiles) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, fontFamily: 'Inter', letterSpacing: 0.8))),
      Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Column(children: tiles.asMap().entries.map((e) => Column(children: [e.value, if (e.key < tiles.length - 1) const Divider(color: AppColors.border, height: 1, indent: 52)])).expand((w) => w.children).toList())),
    ]);
  }

  Widget _buildTile(IconData icon, String label, Color color, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
      title: Text(label, style: TextStyle(color: isDestructive ? AppColors.error : AppColors.text, fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
      onTap: onTap,
    );
  }
}
