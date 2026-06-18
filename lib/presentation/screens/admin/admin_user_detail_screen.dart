import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final int userId;
  final Map<String, dynamic>? userData;
  const AdminUserDetailScreen({super.key, required this.userId, this.userData});
  @override
  ConsumerState<AdminUserDetailScreen> createState() => _DetailState();
}

class _DetailState extends ConsumerState<AdminUserDetailScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late Map<String, dynamic> _user;
  List<Map<String, dynamic>> _notes = [];
  bool _loadingNotes = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _user = widget.userData ?? {'email': '', 'is_active': true};
    _loadNotes();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadNotes() async {
    setState(() => _loadingNotes = true);
    try {
      final r = await ref.read(dioProvider).get('/api/v1/admin/users/${widget.userId}/notes');
      setState(() { _notes = List<Map<String, dynamic>>.from(r.data['items']); _loadingNotes = false; });
    } catch (_) { setState(() => _loadingNotes = false); }
  }

  Future<void> _editUser() async {
    final emailCtrl = TextEditingController(text: _user['email']?.toString() ?? '');
    final usernameCtrl = TextEditingController(text: _user['username']?.toString() ?? '');
    final passCtrl = TextEditingController();
    bool isActive = _user['is_active'] == true;
    String? errorMsg;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit User', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: usernameCtrl,
              decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline, size: 18), isDense: true),
              style: const TextStyle(fontFamily: 'Inter'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 18), isDense: true),
              style: const TextStyle(fontFamily: 'Inter'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password (leave blank to keep)',
                prefixIcon: Icon(Icons.lock_outline, size: 18),
                isDense: true,
              ),
              style: const TextStyle(fontFamily: 'Inter'),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.toggle_on_outlined, color: C.textMuted, size: 18),
              const SizedBox(width: 8),
              const Text('Active', style: TextStyle(fontFamily: 'Inter', color: C.text)),
              const Spacer(),
              Switch(value: isActive, onChanged: (v) => setLocal(() => isActive = v), activeColor: C.primary),
            ]),
            if (errorMsg != null) ...[
              const SizedBox(height: 8),
              Text(errorMsg!, style: const TextStyle(color: C.error, fontSize: 12, fontFamily: 'Inter')),
            ],
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final data = <String, dynamic>{'is_active': isActive};
                if (emailCtrl.text.trim().isNotEmpty) data['email'] = emailCtrl.text.trim();
                if (usernameCtrl.text.trim().isNotEmpty) data['username'] = usernameCtrl.text.trim();
                if (passCtrl.text.isNotEmpty) {
                  if (passCtrl.text.length < 8) {
                    setLocal(() => errorMsg = 'Password must be at least 8 characters');
                    return;
                  }
                  data['password'] = passCtrl.text;
                }
                try {
                  await ref.read(dioProvider).patch('/api/v1/admin/users/${widget.userId}', data: data);
                  setState(() {
                    if (data['email'] != null) _user['email'] = data['email'];
                    if (data['username'] != null) _user['username'] = data['username'];
                    _user['is_active'] = isActive;
                  });
                  if (ctx.mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated'), backgroundColor: C.success)); }
                } on DioException catch (e) {
                  setLocal(() => errorMsg = extractError(e));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete User', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
      content: Text('Delete ${_user['email']}? This cannot be undone.', style: const TextStyle(fontFamily: 'Inter', color: C.textSub)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: C.error), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ));
    if (ok != true) return;
    try {
      await ref.read(dioProvider).delete('/api/v1/admin/users/${widget.userId}');
      if (mounted) { context.pop(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted'), backgroundColor: C.success)); }
    } catch (_) {}
  }

  Future<void> _deleteNote(int noteId) async {
    try {
      await ref.read(dioProvider).delete('/api/v1/notes/$noteId');
      setState(() => _notes.removeWhere((n) => n['id'] == noteId));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_user['username']?.toString() ?? _user['email']?.toString() ?? 'User', overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16)),
          if (_user['username'] != null && _user['email'] != null)
            Text(_user['email']?.toString() ?? '', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: C.textSub, fontWeight: FontWeight.normal)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _editUser, tooltip: 'Edit user'),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: C.error), onPressed: _deleteUser, tooltip: 'Delete user'),
          if (_user['location_permission'] == true)
            IconButton(
              icon: const Icon(Icons.location_on_rounded, color: C.success),
              onPressed: () => context.push('/admin/users/${widget.userId}/location', extra: _user),
              tooltip: 'View location',
            ),
        ],
        bottom: TabBar(controller: _tabs, labelColor: C.primary, unselectedLabelColor: C.textMuted, indicatorColor: C.primary,
          labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [Tab(text: 'Info'), Tab(text: 'Notes')]),
      ),
      body: TabBarView(controller: _tabs, children: [
        ListView(padding: const EdgeInsets.all(20), children: [
          _infoRow(Icons.person_outline_rounded, 'Username', _user['username']?.toString() ?? '-'),
          _infoRow(Icons.email_outlined, 'Email', _user['email']?.toString() ?? '-'),
          _infoRow(Icons.calendar_today_outlined, 'Registered', _fmtDate(_user['created_at']?.toString())),
          _infoRow(Icons.login_rounded, 'Last Login', _lastLogin(_user['last_login']?.toString())),
          _infoRow(Icons.note_rounded, 'Total Notes', '${_user['note_count'] ?? 0}'),
          _infoRow(Icons.location_on_rounded, 'Location Tracking',
            _user['location_permission'] == true ? 'Enabled' : 'Not enabled',
            valueColor: _user['location_permission'] == true ? C.success : C.textMuted),
          _infoRow(_user['is_active'] == true ? Icons.check_circle_outline : Icons.cancel_outlined,
            'Status', _user['is_active'] == true ? 'Active' : 'Inactive',
            valueColor: _user['is_active'] == true ? C.success : C.error),
        ]),
        _loadingNotes ? const Center(child: CircularProgressIndicator()) :
        _notes.isEmpty ? const Center(child: Text('No notes', style: TextStyle(color: C.textSub, fontFamily: 'Inter'))) :
        ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _notes.length,
          itemBuilder: (_, i) {
            final n = _notes[i];
            return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.text, fontFamily: 'Inter')),
                  if ((n['content'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(n['content'] ?? '', style: const TextStyle(fontSize: 12, color: C.textSub, fontFamily: 'Inter'), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 4),
                  Text(_fmtDate(n['created_at']?.toString()), style: const TextStyle(fontSize: 10, color: C.textMuted, fontFamily: 'Inter')),
                ])),
                IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.delete_outline_rounded, color: C.error, size: 18), onPressed: () => _deleteNote(n['id'])),
              ]),
            );
          },
        ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: C.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: C.primary, size: 18)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: C.textMuted, fontFamily: 'Inter', letterSpacing: 0.5)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? C.text, fontFamily: 'Inter')),
      ])),
    ]));
  }

  String _fmtDate(String? s) {
    if (s == null || s == 'None') return '-';
    try { final dt = DateTime.parse(s).toLocal(); final m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']; return '${m[dt.month-1]} ${dt.day}, ${dt.year}'; } catch (_) { return '-'; }
  }

  String _lastLogin(String? s) {
    if (s == null || s == 'None' || s.isEmpty) return 'Never';
    return _fmtDate(s);
  }
}
