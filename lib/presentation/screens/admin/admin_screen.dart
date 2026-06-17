import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/core/constants/app_constants.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';
import 'package:lifeos/services/api/api_client.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});
  @override
  ConsumerState<AdminScreen> createState() => _AdminState();
}

class _AdminState extends ConsumerState<AdminScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Map<String, dynamic>> _users = [];
  bool _loadingUsers = true;
  final Set<int> _selected = {};
  bool _selectMode = false;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _connectOverview;
  bool _loadingConnect = true;

  // New admin data
  Map<String, dynamic>? _analytics;
  List<Map<String, dynamic>> _adminTasks = [];
  List<Map<String, dynamic>> _adminHabits = [];
  List<Map<String, dynamic>> _adminJournals = [];
  bool _loadingAnalytics = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 8, vsync: this);
    _loadUsers();
    _loadProfile();
    _loadConnectOverview();
    _loadAnalytics();
    _loadAdminTasks();
    _loadAdminHabits();
    _loadAdminJournals();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loadingAnalytics = true);
    try {
      final r = await ref.read(dioProvider).get('/api/v1/admin/analytics');
      setState(() { _analytics = r.data; _loadingAnalytics = false; });
    } catch (_) { setState(() => _loadingAnalytics = false); }
  }

  Future<void> _loadAdminTasks() async {
    try {
      final r = await ref.read(dioProvider).get('/api/v1/admin/tasks');
      setState(() { _adminTasks = List<Map<String, dynamic>>.from(r.data['items']); });
    } catch (_) {}
  }

  Future<void> _loadAdminHabits() async {
    try {
      final r = await ref.read(dioProvider).get('/api/v1/admin/habits');
      setState(() { _adminHabits = List<Map<String, dynamic>>.from(r.data['items']); });
    } catch (_) {}
  }

  Future<void> _loadAdminJournals() async {
    try {
      final r = await ref.read(dioProvider).get('/api/v1/admin/journals');
      setState(() { _adminJournals = List<Map<String, dynamic>>.from(r.data['items']); });
    } catch (_) {}
  }

  Future<void> _loadConnectOverview() async {
    setState(() => _loadingConnect = true);
    try {
      final r = await ref.read(dioProvider).get('/api/v1/admin/connect-overview');
      setState(() { _connectOverview = r.data; _loadingConnect = false; });
    } catch (_) { setState(() => _loadingConnect = false); }
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final r = await ref.read(dioProvider).get('/api/v1/admin/users');
      setState(() { _users = List<Map<String, dynamic>>.from(r.data['items']); _loadingUsers = false; });
    } catch (_) { setState(() => _loadingUsers = false); }
  }

  Future<void> _loadProfile() async {
    try {
      final r = await ref.read(dioProvider).get('/api/v1/profile/');
      setState(() => _profile = r.data);
    } catch (_) {}
  }

  String _adminPhotoUrl() {
    final u = _profile!['profile_photo_url'].toString();
    return u.startsWith('http') ? u : '${AppConstants.baseUrl}$u';
  }

  Future<void> _deleteUser(int id) async {
    try { await ref.read(dioProvider).delete('/api/v1/admin/users/$id'); _loadUsers(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: C.error)); }
  }

  Future<void> _bulkDelete() async {
    if (_selected.isEmpty) return;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Users', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: C.error)),
      content: Text('Delete ${_selected.length} selected user(s)? Their notes will also be deleted.', style: const TextStyle(fontFamily: 'Inter', color: C.textSub, fontSize: 13)),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: C.error), onPressed: () => Navigator.pop(context, true), child: const Text('Delete All'))],
    ));
    if (ok == true) {
      try {
        await ref.read(dioProvider).post('/api/v1/admin/users/bulk-delete', data: {'user_ids': _selected.toList()});
        setState(() { _selected.clear(); _selectMode = false; });
        _loadUsers();
      } catch (_) {}
    }
  }

  Future<void> _pickAdminPhoto() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img == null || !mounted) return;
    try {
      final form = FormData.fromMap({'file': await MultipartFile.fromFile(img.path, filename: 'photo.jpg')});
      await ref.read(dioProvider).post('/api/v1/profile/photo', data: form, options: Options(contentType: 'multipart/form-data'));
      _loadProfile();
    } catch (_) {}
  }

  Future<void> _changeAdminPassword() async {
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
            await ref.read(dioProvider).patch('/api/v1/admin/profile/password', data: {'current_password': curr.text, 'new_password': nw.text});
            if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed!'), backgroundColor: C.success)); }
          } on DioException catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractError(e)), backgroundColor: C.error)); }
        }, child: const Text('Change')),
      ],
    ));
  }

  Future<void> _changeAdminEmail() async {
    final email = TextEditingController(text: ref.read(authProvider).email ?? '');
    final pass = TextEditingController();
    await showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Change Email', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'New Email')),
        const SizedBox(height: 12),
        TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          try {
            await ref.read(dioProvider).patch('/api/v1/admin/profile/email', data: {'new_email': email.text.trim(), 'current_password': pass.text});
            if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email changed! Please re-login.'), backgroundColor: C.success)); await ref.read(authProvider.notifier).logout(); context.go('/login'); }
          } on DioException catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractError(e)), backgroundColor: C.error)); }
        }, child: const Text('Change')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final nonAdminUsers = _users.where((u) => u['is_admin'] != true).toList();
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(width: 26, height: 26, decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), color: C.bg),
            child: ClipRRect(borderRadius: BorderRadius.circular(7), child: Image.asset('assets/images/logo.png', fit: BoxFit.contain))),
          const SizedBox(width: 8),
          const Text('Admin Panel'),
        ]),
        actions: [
          if (_tabs.index == 1 && _selectMode && _selected.isNotEmpty)  // Users tab
            TextButton.icon(onPressed: _bulkDelete, icon: const Icon(Icons.delete_sweep_rounded, color: C.error, size: 18), label: Text('Delete (${_selected.length})', style: const TextStyle(color: C.error, fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13))),
          IconButton(icon: const Icon(Icons.logout_rounded, color: C.error), onPressed: () async {
            await ref.read(authProvider.notifier).logout();
            if (mounted) context.go('/login');
          }),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: C.primary,
          unselectedLabelColor: C.textMuted,
          indicatorColor: C.primary,
          indicatorWeight: 2,
          isScrollable: true,
          labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Users'),
            Tab(text: 'Analytics'),
            Tab(text: 'Tasks'),
            Tab(text: 'Habits'),
            Tab(text: 'Journals'),
            Tab(text: 'Connect'),
            Tab(text: 'Profile'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        _buildDashboard(nonAdminUsers),
        _buildUsers(nonAdminUsers),
        _buildAnalyticsTab(),
        _buildTasksTab(),
        _buildHabitsTab(),
        _buildJournalsTab(),
        _buildConnect(),
        _buildProfile(),
      ]),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_loadingAnalytics) return const Center(child: CircularProgressIndicator());
    final a = _analytics;
    if (a == null) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('Failed to load analytics', style: TextStyle(color: C.textSub, fontFamily: 'Inter')),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: _loadAnalytics, child: const Text('Retry')),
    ]));
    return RefreshIndicator(onRefresh: _loadAnalytics, child: ListView(padding: const EdgeInsets.all(20), children: [
      _statCard('Total Users', '${a['total_users'] ?? 0}', Icons.people_rounded, C.primary),
      const SizedBox(height: 12),
      _statCard('Total Tasks', '${a['total_tasks'] ?? 0}', Icons.task_alt_rounded, C.success),
      const SizedBox(height: 12),
      _statCard('Completed Tasks', '${a['completed_tasks'] ?? 0}', Icons.check_circle_rounded, const Color(0xFF10B981)),
      const SizedBox(height: 12),
      _statCard('Total Habits', '${a['total_habits'] ?? 0}', Icons.local_fire_department_rounded, const Color(0xFFFF6B35)),
      const SizedBox(height: 12),
      _statCard('Journal Entries', '${a['total_journals'] ?? 0}', Icons.menu_book_rounded, const Color(0xFF06B6D4)),
      const SizedBox(height: 12),
      _statCard('Total Goals', '${a['total_goals'] ?? 0}', Icons.flag_rounded, const Color(0xFFF59E0B)),
      const SizedBox(height: 12),
      _statCard('Total Projects', '${a['total_projects'] ?? 0}', Icons.folder_rounded, const Color(0xFF8B5CF6)),
    ]));
  }

  Color _taskPriorityColor(String p) {
    switch (p) {
      case 'high': return C.error;
      case 'medium': return C.warning;
      default: return C.success;
    }
  }

  Widget _buildTasksTab() {
    if (_adminTasks.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('No tasks found', style: TextStyle(color: C.textSub, fontFamily: 'Inter')),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: _loadAdminTasks, child: const Text('Refresh')),
    ]));
    return RefreshIndicator(onRefresh: () async { await _loadAdminTasks(); }, child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _adminTasks.length,
      itemBuilder: (_, i) {
        final t = _adminTasks[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: C.border)),
          child: Row(children: [
            Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: _taskPriorityColor(t['priority'] ?? 'low'), shape: BoxShape.circle)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t['title'] ?? '', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: C.text, decoration: t['is_completed'] == true ? TextDecoration.lineThrough : null)),
              if (t['due_date'] != null) Text('Due: ${t['due_date']}', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: C.textMuted)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: t['is_completed'] == true ? C.success.withOpacity(0.1) : C.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(t['is_completed'] == true ? 'Done' : t['status'] ?? 'todo', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: t['is_completed'] == true ? C.success : C.warning)),
            ),
          ]),
        );
      },
    ));
  }

  Widget _buildHabitsTab() {
    if (_adminHabits.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('No habits found', style: TextStyle(color: C.textSub, fontFamily: 'Inter')),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: _loadAdminHabits, child: const Text('Refresh')),
    ]));
    return RefreshIndicator(onRefresh: () async { await _loadAdminHabits(); }, child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _adminHabits.length,
      itemBuilder: (_, i) {
        final h = _adminHabits[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: C.border)),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: C.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.local_fire_department_rounded, color: C.primary, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(h['name'] ?? '', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: C.text)),
              Text('Streak: ${h['streak_current'] ?? 0} • Best: ${h['streak_longest'] ?? 0}', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: C.textMuted)),
            ])),
            Text(h['frequency'] ?? 'daily', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: C.textSub)),
          ]),
        );
      },
    ));
  }

  String _adminMoodEmoji(String? m) {
    switch (m) {
      case 'happy': return '😊';
      case 'neutral': return '😐';
      case 'sad': return '😔';
      case 'productive': return '🔥';
      case 'tired': return '😴';
      default: return '📓';
    }
  }

  Widget _buildJournalsTab() {
    if (_adminJournals.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('No journal entries', style: TextStyle(color: C.textSub, fontFamily: 'Inter')),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: _loadAdminJournals, child: const Text('Refresh')),
    ]));
    return RefreshIndicator(onRefresh: () async { await _loadAdminJournals(); }, child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _adminJournals.length,
      itemBuilder: (_, i) {
        final e = _adminJournals[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: C.border)),
          child: Row(children: [
            Text(_adminMoodEmoji(e['mood']), style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e['title'] ?? 'Journal Entry', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: C.text)),
              Text(e['date']?.toString() ?? '', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: C.textMuted)),
            ])),
          ]),
        );
      },
    ));
  }

  Widget _buildDashboard(List<Map<String, dynamic>> users) {
    final totalNotes = users.fold(0, (sum, u) => sum + (u['note_count'] as int? ?? 0));
    final activeUsers = users.where((u) => u['is_active'] == true).length;
    return RefreshIndicator(onRefresh: _loadUsers, child: ListView(padding: const EdgeInsets.all(20), children: [
      _statCard('Total Users', '${users.length}', Icons.people_rounded, C.primary),
      const SizedBox(height: 12),
      _statCard('Active Users', '$activeUsers', Icons.check_circle_outline_rounded, C.success),
      const SizedBox(height: 12),
      _statCard('Total Notes', '$totalNotes', Icons.note_rounded, C.warning),
      const SizedBox(height: 24),
      const Text('Recent Users', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: C.text, fontFamily: 'Inter')),
      const SizedBox(height: 12),
      ...users.take(5).map((u) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
        child: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: C.primary.withOpacity(0.12),
            child: Text((u['email'] as String)[0].toUpperCase(), style: const TextStyle(color: C.primary, fontFamily: 'Inter', fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u['email'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text, fontFamily: 'Inter'), overflow: TextOverflow.ellipsis),
            Text('${u['note_count'] ?? 0} notes', style: const TextStyle(fontSize: 11, color: C.textMuted, fontFamily: 'Inter')),
          ])),
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: u['is_active'] == true ? C.success : C.error)),
        ]))),
    ]));
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24)),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color, fontFamily: 'Inter')),
          Text(label, style: const TextStyle(fontSize: 13, color: C.textSub, fontFamily: 'Inter')),
        ]),
      ]));
  }

  Widget _buildUsers(List<Map<String, dynamic>> users) {
    return Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white,
        child: Row(children: [
          Checkbox(value: _selectMode && _selected.length == users.length && users.isNotEmpty,
            onChanged: (v) {
              setState(() {
                _selectMode = true;
                if (v == true) _selected.addAll(users.map((u) => u['id'] as int));
                else { _selected.clear(); _selectMode = false; }
              });
            }),
          const Text('Select All', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: C.textSub)),
          const Spacer(),
          Text('${users.length} users', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.textMuted)),
        ])),
      const Divider(height: 1, color: C.border),
      Expanded(child: RefreshIndicator(onRefresh: _loadUsers,
        child: _loadingUsers ? const Center(child: CircularProgressIndicator()) :
        users.isEmpty ? const Center(child: Text('No users yet', style: TextStyle(color: C.textSub, fontFamily: 'Inter'))) :
        ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: users.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: C.border, indent: 60),
          itemBuilder: (_, i) {
            final u = users[i];
            final id = u['id'] as int;
            final isSelected = _selected.contains(id);
            return ListTile(
              leading: Row(mainAxisSize: MainAxisSize.min, children: [
                if (_selectMode) Checkbox(value: isSelected, onChanged: (v) { setState(() { v == true ? _selected.add(id) : _selected.remove(id); }); })
                else const SizedBox(width: 4),
                CircleAvatar(radius: 18, backgroundColor: C.primary.withOpacity(0.12),
                  child: Text((u['email'] as String)[0].toUpperCase(), style: const TextStyle(color: C.primary, fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14))),
              ]),
              title: Text(u['email'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text, fontFamily: 'Inter'), overflow: TextOverflow.ellipsis),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${u['note_count'] ?? 0} notes • ${u['is_active'] == true ? 'Active' : 'Inactive'}',
                  style: const TextStyle(fontSize: 11, color: C.textMuted, fontFamily: 'Inter')),
                Row(children: [
                  Icon(u['location_permission'] == true ? Icons.location_on_rounded : Icons.location_off_rounded,
                    size: 11, color: u['location_permission'] == true ? C.success : C.textMuted),
                  const SizedBox(width: 3),
                  Text(u['location_permission'] == true ? 'Location: Allowed' : 'Location: Not allowed',
                    style: TextStyle(fontSize: 11, color: u['location_permission'] == true ? C.success : C.textMuted, fontFamily: 'Inter')),
                ]),
              ]),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (u['location_permission'] == true) IconButton(
                  icon: const Icon(Icons.my_location_rounded, size: 18, color: C.success),
                  onPressed: () => context.push('/admin/users/$id/location', extra: u),
                  tooltip: 'View Location',
                ),
                IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: C.primary), onPressed: () => context.push('/admin/users/$id', extra: u)),
                IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: C.error), onPressed: () async {
                  final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                    title: const Text('Delete User', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: C.error)),
                    content: Text('Delete ${u['email']}?', style: const TextStyle(fontFamily: 'Inter', color: C.textSub)),
                    actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: C.error), onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))],
                  ));
                  if (ok == true) _deleteUser(id);
                }),
              ]),
              onTap: () {
                if (_selectMode) { setState(() { isSelected ? _selected.remove(id) : _selected.add(id); }); }
                else { context.push('/admin/users/$id', extra: u); }
              },
              onLongPress: () { setState(() { _selectMode = true; _selected.add(id); }); },
            );
          },
        ),
      )),
    ]);
  }

  Widget _buildConnect() {
    if (_loadingConnect) return const Center(child: CircularProgressIndicator());
    final overview = _connectOverview;
    if (overview == null) return const Center(child: Text('Failed to load', style: TextStyle(color: C.textSub, fontFamily: 'Inter')));
    final users = List<Map<String, dynamic>>.from(overview['users'] ?? []);
    final friendships = List<Map<String, dynamic>>.from(overview['friendships'] ?? []);
    final usersWithUsername = users.where((u) => u['username'] != null).toList();
    return RefreshIndicator(onRefresh: _loadConnectOverview, child: ListView(padding: const EdgeInsets.all(20), children: [
      _statCard('Connect Users', '${usersWithUsername.length}', Icons.badge_outlined, C.primary),
      const SizedBox(height: 12),
      _statCard('Friendships', '${friendships.length}', Icons.people_alt_rounded, C.success),
      const SizedBox(height: 12),
      _statCard('Pending Requests', '${overview['pending_friend_requests'] ?? 0}', Icons.hourglass_top_rounded, C.warning),
      const SizedBox(height: 24),
      const Text('Users', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: C.text, fontFamily: 'Inter')),
      const SizedBox(height: 12),
      ...users.map((u) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
        child: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: C.primary.withOpacity(0.12),
            child: Text((u['email'] as String)[0].toUpperCase(), style: const TextStyle(color: C.primary, fontFamily: 'Inter', fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u['email'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text, fontFamily: 'Inter'), overflow: TextOverflow.ellipsis),
            Text(u['username'] != null ? '@${u['username']}' : 'No username set', style: const TextStyle(fontSize: 11, color: C.textMuted, fontFamily: 'Inter')),
            if ((u['bio'] ?? '').toString().isNotEmpty) Text(u['bio'], style: const TextStyle(fontSize: 11, color: C.textSub, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Text('${u['message_count'] ?? 0} msgs', style: const TextStyle(fontSize: 11, color: C.textMuted, fontFamily: 'Inter')),
        ]))),
      const SizedBox(height: 24),
      const Text('Friendships', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: C.text, fontFamily: 'Inter')),
      const SizedBox(height: 12),
      if (friendships.isEmpty) const Text('No friendships yet', style: TextStyle(color: C.textSub, fontFamily: 'Inter')),
      ...friendships.map((f) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
        child: Row(children: [
          Expanded(child: Text('@${f['user1_username'] ?? f['user1_id']}  ↔  @${f['user2_username'] ?? f['user2_id']}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text, fontFamily: 'Inter'))),
        ]))),
    ]));
  }

  Widget _buildProfile() {
    return ListView(padding: const EdgeInsets.all(20), children: [
      Center(child: Stack(children: [
        CircleAvatar(radius: 52, backgroundColor: C.primary.withOpacity(0.1),
          backgroundImage: _profile?['profile_photo_url'] != null ? NetworkImage(_adminPhotoUrl()) : null,
          child: _profile?['profile_photo_url'] == null ? const Icon(Icons.admin_panel_settings_rounded, color: C.primary, size: 48) : null),
        Positioned(bottom: 0, right: 0, child: GestureDetector(onTap: _pickAdminPhoto,
          child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: C.primary, shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16)))),
      ])),
      const SizedBox(height: 12),
      const Center(child: Text('Administrator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.text, fontFamily: 'Inter'))),
      Center(child: Text(ref.read(authProvider).email ?? '', style: const TextStyle(fontSize: 13, color: C.textSub, fontFamily: 'Inter'))),
      const SizedBox(height: 32),
      _adminTile(Icons.lock_outline, 'Change Password', _changeAdminPassword),
      const Divider(height: 1, color: C.border),
      _adminTile(Icons.email_outlined, 'Change Email', _changeAdminEmail),
      const Divider(height: 1, color: C.border),
      ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: C.error.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.logout_rounded, color: C.error, size: 18)),
        title: const Text('Sign Out', style: TextStyle(color: C.error, fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, color: C.textMuted, size: 18),
        onTap: () async { await ref.read(authProvider.notifier).logout(); if (mounted) context.go('/login'); },
      ),
    ]);
  }

  Widget _adminTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: C.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: C.primary, size: 18)),
      title: Text(label, style: const TextStyle(color: C.text, fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: C.textMuted, size: 18),
      onTap: onTap,
    );
  }

  String _lastLogin(String? s) {
    if (s == null || s == 'None' || s.isEmpty) return 'Never';
    try {
      final dt = DateTime.parse(s).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return 'Unknown'; }
  }
}
