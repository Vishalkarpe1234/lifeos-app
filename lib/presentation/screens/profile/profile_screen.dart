import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';
import 'package:lifeos/services/api/api_client.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await ref.read(dioProvider).get('/api/v1/profile/');
      setState(() { _profile = r.data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _pickPhoto() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img == null || !mounted) return;
    try {
      final form = FormData.fromMap({'file': await MultipartFile.fromFile(img.path, filename: 'photo.jpg')});
      await ref.read(dioProvider).post('/api/v1/profile/photo', data: form,
        options: Options(contentType: 'multipart/form-data'));
      _load();
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo upload failed'), backgroundColor: C.error)); }
  }

  Future<void> _changePassword() async {
    final curr = TextEditingController();
    final nw = TextEditingController();
    await showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Change Password', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: curr, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
        const SizedBox(height: 12),
        TextField(controller: nw, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          try {
            await ref.read(dioProvider).post('/api/v1/auth/change-password', data: {'current_password': curr.text, 'new_password': nw.text});
            if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed!'), backgroundColor: C.success)); }
          } on DioException catch (e) {
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractError(e)), backgroundColor: C.error));
          }
        }, child: const Text('Change')),
      ],
    ));
  }

  Future<void> _deleteAccount() async {
    final pass = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Account', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: C.error)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('This permanently deletes your account and all notes. Cannot be undone.', style: TextStyle(fontFamily: 'Inter', color: C.textSub, fontSize: 13)),
        const SizedBox(height: 12),
        TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Enter password to confirm')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: C.error), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ));
    if (ok == true && mounted) {
      try {
        await ref.read(dioProvider).delete('/api/v1/auth/delete-account', data: {'password': pass.text});
        await ref.read(authProvider.notifier).logout();
        if (mounted) context.go('/login');
      } on DioException catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractError(e)), backgroundColor: C.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => context.pop())),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(20), children: [
        Center(child: Stack(children: [
          CircleAvatar(radius: 48, backgroundColor: C.primary.withOpacity(0.1),
            backgroundImage: (_profile?['profile_photo_url'] != null) ? NetworkImage(_profile!['profile_photo_url']) : null,
            child: _profile?['profile_photo_url'] == null ? const Icon(Icons.person, color: C.primary, size: 48) : null),
          Positioned(bottom: 0, right: 0, child: GestureDetector(onTap: _pickPhoto,
            child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: C.primary, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16)))),
        ])),
        const SizedBox(height: 12),
        Center(child: Text(_profile?['full_name'] ?? 'User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.text, fontFamily: 'Inter'))),
        Center(child: Text(ref.read(authProvider).email ?? '', style: const TextStyle(fontSize: 13, color: C.textSub, fontFamily: 'Inter'))),
        const SizedBox(height: 32),
        _tile(Icons.lock_outline, 'Change Password', C.primary, _changePassword),
        const Divider(height: 1, color: C.border),
        _tile(Icons.logout_rounded, 'Sign Out', C.textSub, () async {
          final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
            title: const Text('Sign Out', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
            content: const Text('Are you sure?', style: TextStyle(fontFamily: 'Inter', color: C.textSub)),
            actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out'))],
          ));
          if (ok == true && mounted) { await ref.read(authProvider.notifier).logout(); context.go('/login'); }
        }),
        const Divider(height: 1, color: C.border),
        _tile(Icons.delete_forever_rounded, 'Delete My Account', C.error, _deleteAccount),
      ]),
    );
  }

  Widget _tile(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18)),
      title: Text(label, style: TextStyle(color: color == C.error ? C.error : C.text, fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: C.textMuted, size: 18),
      onTap: onTap,
    );
  }
}
