import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';
import 'package:lifeos/services/api/api_client.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});
  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _notes = [];
  bool _loadingUsers = true;
  bool _loadingNotes = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadUsers();
    _loadNotes();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/api/v1/admin/users');
      if (mounted) setState(() { _users = List<Map<String, dynamic>>.from(res.data['items']); _loadingUsers = false; });
    } catch (_) { if (mounted) setState(() => _loadingUsers = false); }
  }

  Future<void> _loadNotes() async {
    setState(() => _loadingNotes = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/api/v1/admin/all-notes');
      if (mounted) setState(() { _notes = List<Map<String, dynamic>>.from(res.data['items']); _loadingNotes = false; });
    } catch (_) { if (mounted) setState(() => _loadingNotes = false); }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete User', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppColors.error)),
      content: Text('Delete user ${user['email']}? All their notes will also be deleted.', style: const TextStyle(fontFamily: 'Inter', color: AppColors.textSub, fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSub))),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ));
    if (confirm == true) {
      try { final dio = ref.read(dioProvider); await dio.delete('/api/v1/admin/users/${user['id']}'); _loadUsers(); _loadNotes(); }
      catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error)); }
    }
  }

  Future<void> _addUser() async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    await showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Add User', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppColors.text)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: AppColors.text, fontFamily: 'Inter'), decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 12),
        TextField(controller: passCtrl, obscureText: true, style: const TextStyle(color: AppColors.text, fontFamily: 'Inter'), decoration: const InputDecoration(labelText: 'Password')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textSub))),
        ElevatedButton(onPressed: () async {
          try {
            final dio = ref.read(dioProvider);
            await dio.post('/api/v1/admin/users', data: {'email': emailCtrl.text.trim(), 'password': passCtrl.text, 'is_admin': false});
            if (context.mounted) { Navigator.pop(context); _loadUsers(); }
          } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error)); }
        }, child: const Text('Add')),
      ],
    ));
  }

  Future<void> _deleteNote(Map<String, dynamic> note) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/api/v1/notes/${note['id']}');
      setState(() => _notes.removeWhere((n) => n['id'] == note['id']));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error)); }
  }

  Future<void> _logout() async {
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Row(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), color: Colors.white, boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 6)]),
            child: ClipRRect(borderRadius: BorderRadius.circular(7), child: Image.asset('assets/images/logo.png', fit: BoxFit.contain))),
          const SizedBox(width: 8),
          const Text('Admin Panel', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, color: AppColors.text, fontSize: 18)),
        ]),
        actions: [IconButton(icon: const Icon(Icons.logout_rounded, color: AppColors.error), onPressed: _logout, tooltip: 'Sign Out')],
        bottom: TabBar(controller: _tabs, labelColor: AppColors.primary, unselectedLabelColor: AppColors.textMuted, indicatorColor: AppColors.primary, labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700), tabs: const [Tab(text: 'Users'), Tab(text: 'All Notes')]),
      ),
      body: TabBarView(controller: _tabs, children: [_buildUsersTab(), _buildNotesTab()]),
      floatingActionButton: ListenableBuilder(
        listenable: _tabs,
        builder: (_, __) => _tabs.index == 0 ? FloatingActionButton(onPressed: _addUser, backgroundColor: AppColors.primary, child: const Icon(Icons.person_add_rounded, color: Colors.white)) : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_loadingUsers) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    return RefreshIndicator(color: AppColors.primary, onRefresh: _loadUsers, child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (_, i) {
        final u = _users[i];
        final lastLogin = u['last_login'];
        return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
          child: Row(children: [
            CircleAvatar(radius: 20, backgroundColor: u['is_admin'] == true ? AppColors.primary : AppColors.primary.withOpacity(0.15),
              child: Text((u['email'] as String? ?? 'U')[0].toUpperCase(), style: TextStyle(color: u['is_admin'] == true ? Colors.white : AppColors.primary, fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(u['email'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text, fontFamily: 'Inter'), overflow: TextOverflow.ellipsis)),
                if (u['is_admin'] == true) Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Text('Admin', style: TextStyle(fontSize: 10, color: AppColors.primary, fontFamily: 'Inter', fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: u['is_active'] == true ? AppColors.success : AppColors.error)),
                const SizedBox(width: 4),
                Text(u['is_active'] == true ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, color: u['is_active'] == true ? AppColors.success : AppColors.error, fontFamily: 'Inter')),
                if (lastLogin != null) ...[
                  const SizedBox(width: 8),
                  Text('Last: ${_formatDate(lastLogin.toString())}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'Inter')),
                ],
              ]),
            ])),
            if (u['is_admin'] != true) IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20), onPressed: () => _deleteUser(u)),
          ]),
        );
      },
    ));
  }

  Widget _buildNotesTab() {
    if (_loadingNotes) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    return RefreshIndicator(color: AppColors.primary, onRefresh: _loadNotes, child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notes.length,
      itemBuilder: (_, i) {
        final n = _notes[i];
        return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(n['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis)),
              IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18), onPressed: () => _deleteNote(n)),
            ]),
            const SizedBox(height: 2),
            Text('By: ${n['user_email'] ?? 'unknown'}', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
            if ((n['content'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(n['content'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSub, fontFamily: 'Inter'), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 4),
            Text(_formatDate(n['created_at'] ?? ''), style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'Inter')),
          ]),
        );
      },
    ));
  }

  String _formatDate(String dateStr) {
    try { final dt = DateTime.parse(dateStr).toLocal(); return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'; }
    catch (_) { return dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr; }
  }
}
