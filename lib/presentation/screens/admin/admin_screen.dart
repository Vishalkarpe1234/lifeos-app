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

class _AdminState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  List<Map<String, dynamic>> _users = [];
  bool _loadingUsers = true;
  final Set<int> _selected = {};
  bool _selectMode = false;
  String _search = '';

  Map<String, dynamic>? _overview;
  bool _loadingOverview = true;

  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadUsers();
    _loadOverview();
    _loadProfile();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final r = await ref.read(dioProvider).get('/api/v1/admin/users');
      setState(() {
        _users = List<Map<String, dynamic>>.from(r.data as List);
        _loadingUsers = false;
      });
    } catch (_) {
      setState(() => _loadingUsers = false);
    }
  }

  Future<void> _loadOverview() async {
    setState(() => _loadingOverview = true);
    try {
      final r = await ref.read(dioProvider).get('/api/v1/admin/analytics');
      setState(() { _overview = r.data; _loadingOverview = false; });
    } catch (_) {
      setState(() => _loadingOverview = false);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final r = await ref.read(dioProvider).get('/api/v1/profile/');
      setState(() => _profile = r.data);
    } catch (_) {}
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Users', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        content: Text('Delete ${_selected.length} user(s)? This cannot be undone.', style: const TextStyle(fontFamily: 'Inter', color: C.textSub)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: C.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(dioProvider).post('/api/v1/admin/users/bulk-delete', data: {'user_ids': _selected.toList()});
    } catch (_) {
      for (final id in _selected) {
        try { await ref.read(dioProvider).delete('/api/v1/admin/users/$id'); } catch (_) {}
      }
    }
    setState(() { _selected.clear(); _selectMode = false; });
    await _loadUsers();
  }

  Future<void> _editUser(Map<String, dynamic> u) async {
    final uid = (u['id'] as num).toInt();
    final emailCtrl = TextEditingController(text: u['email']?.toString() ?? '');
    final usernameCtrl = TextEditingController(text: u['username']?.toString() ?? '');
    final passCtrl = TextEditingController();
    bool isActive = u['is_active'] == true;
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
              decoration: const InputDecoration(labelText: 'New Password (leave blank to keep)', prefixIcon: Icon(Icons.lock_outline, size: 18), isDense: true),
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
                  await ref.read(dioProvider).patch('/api/v1/admin/users/$uid', data: data);
                  setState(() {
                    final idx = _users.indexWhere((x) => (x['id'] as num).toInt() == uid);
                    if (idx != -1) {
                      _users[idx] = {..._users[idx], ...data};
                    }
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated'), backgroundColor: C.success));
                } catch (e) {
                  setLocal(() => errorMsg = 'Failed to update user');
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser(Map<String, dynamic> u) async {
    final uid = (u['id'] as num).toInt();
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete User', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
      content: Text('Delete ${u['email']}? This cannot be undone.', style: const TextStyle(fontFamily: 'Inter', color: C.textSub)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: C.error), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ));
    if (ok != true) return;
    try {
      await ref.read(dioProvider).delete('/api/v1/admin/users/$uid');
      setState(() => _users.removeWhere((x) => (x['id'] as num).toInt() == uid));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted'), backgroundColor: C.success));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          if (_selectMode) ...[
            Center(child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text('${_selected.length} selected', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: C.textSub)),
            )),
            IconButton(icon: const Icon(Icons.delete_outline_rounded, color: C.error), onPressed: _deleteSelected),
            IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() { _selected.clear(); _selectMode = false; })),
          ] else
            IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/login');
            }),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13),
          indicatorColor: C.primary,
          labelColor: C.primary,
          unselectedLabelColor: C.textSub,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildOverviewTab(),
          _buildUsersTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_loadingOverview) return const Center(child: CircularProgressIndicator());
    final a = _overview ?? {};
    final totalUsers = _users.length;
    final locEnabled = _users.where((u) => u['location_permission'] == true).length;
    return RefreshIndicator(
      onRefresh: () async { await _loadOverview(); await _loadUsers(); },
      child: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('PLATFORM OVERVIEW', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: C.textMuted, letterSpacing: 1)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
          children: [
            _statCard('Total Users', '$totalUsers', Icons.people_outline_rounded, C.primary),
            _statCard('Location Enabled', '$locEnabled', Icons.location_on_rounded, C.success),
            _statCard('Total Notes', '${a['total_tasks'] ?? 0}', Icons.note_outlined, const Color(0xFF8B5CF6)),
            _statCard('Registered Users', '$totalUsers', Icons.person_add_outlined, C.warning),
          ],
        ),
        const SizedBox(height: 20),
        const Text('USERS WITH LOCATION', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: C.textMuted, letterSpacing: 1)),
        const SizedBox(height: 10),
        ..._users.where((u) => u['location_permission'] == true).map((u) => _locationUserTile(u)),
        if (_users.where((u) => u['location_permission'] == true).isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
            child: const Text('No users have enabled location yet', style: TextStyle(fontFamily: 'Inter', color: C.textMuted, fontSize: 13)),
          ),
      ]),
    );
  }

  Widget _locationUserTile(Map<String, dynamic> u) {
    final uid = (u['id'] as num).toInt();
    return GestureDetector(
      onTap: () => context.push('/admin/users/$uid/location', extra: u),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: C.success.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.location_on_rounded, color: C.success, size: 16)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u['username'] ?? u['email'] ?? '-', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13, color: C.text)),
            Text(u['email'] ?? '', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: C.textSub)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: C.textMuted, size: 18),
        ]),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18)),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: C.textSub)),
        ]),
      ]),
    );
  }

  Widget _buildUsersTab() {
    final filtered = _users.where((u) {
      if (_search.isEmpty) return true;
      return (u['email'] ?? '').toString().toLowerCase().contains(_search.toLowerCase()) ||
             (u['username'] ?? '').toString().toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(hintText: 'Search users...', prefixIcon: Icon(Icons.search_rounded), isDense: true),
              style: const TextStyle(fontFamily: 'Inter'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(_selectMode ? Icons.close_rounded : Icons.checklist_rounded, color: C.primary),
            onPressed: () => setState(() { _selectMode = !_selectMode; _selected.clear(); }),
            tooltip: _selectMode ? 'Cancel' : 'Select multiple',
          ),
        ]),
      ),
      Expanded(
        child: _loadingUsers
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadUsers,
                child: filtered.isEmpty
                    ? const Center(child: Text('No users found', style: TextStyle(fontFamily: 'Inter', color: C.textSub)))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final u = filtered[i];
                          final uid = (u['id'] as num).toInt();
                          final isAdmin = u['is_admin'] == true;
                          final isSelected = _selected.contains(uid);
                          final hasLocation = u['location_permission'] == true;
                          return GestureDetector(
                            onTap: () {
                              if (_selectMode) {
                                setState(() {
                                  if (isSelected) _selected.remove(uid);
                                  else _selected.add(uid);
                                });
                              } else {
                                context.push('/admin/users/$uid', extra: u);
                              }
                            },
                            onLongPress: () => setState(() {
                              _selectMode = true;
                              _selected.add(uid);
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected ? C.primary.withOpacity(0.08) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? C.primary : C.border),
                              ),
                              child: Row(children: [
                                if (_selectMode)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                      color: isSelected ? C.primary : C.textMuted, size: 22),
                                  ),
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isAdmin ? C.warning.withOpacity(0.15) : C.primary.withOpacity(0.12),
                                  child: Text(
                                    (u['username'] ?? u['email'] ?? '?').toString().substring(0, 1).toUpperCase(),
                                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: isAdmin ? C.warning : C.primary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(u['username'] ?? u['email'] ?? 'Unknown',
                                    style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: C.text)),
                                  Text(u['email'] ?? '', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.textSub)),
                                ])),
                                if (isAdmin)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: C.warning.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                    child: const Text('ADMIN', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: C.warning)),
                                  )
                                else if (!_selectMode) Row(mainAxisSize: MainAxisSize.min, children: [
                                  if (hasLocation) IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.location_on_rounded, color: C.success, size: 20),
                                    onPressed: () => context.push('/admin/users/$uid/location', extra: u),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.edit_outlined, color: C.primary, size: 18),
                                    onPressed: () => _editUser(u),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.delete_outline_rounded, color: C.error, size: 18),
                                    onPressed: () => _deleteUser(u),
                                  ),
                                ]),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
      ),
    ]);
  }

  Widget _buildSettingsTab() {
    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.border)),
        child: Column(children: [
          GestureDetector(
            onTap: () async {
              final picker = ImagePicker();
              final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
              if (img == null) return;
              try {
                final dio = ref.read(dioProvider);
                final fd = FormData.fromMap({'photo': await MultipartFile.fromFile(img.path, filename: 'photo.jpg')});
                await dio.patch('/api/v1/profile/photo', data: fd);
                await _loadProfile();
              } catch (_) {}
            },
            child: CircleAvatar(
              radius: 40,
              backgroundColor: C.primary.withOpacity(0.15),
              backgroundImage: _profile?['photo_url'] != null
                  ? NetworkImage('${AppConstants.baseUrl}${_profile!['photo_url']}')
                  : null,
              child: _profile?['photo_url'] == null
                  ? const Icon(Icons.person_rounded, color: C.primary, size: 36)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(_profile?['username'] ?? 'Admin', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 18, color: C.text)),
          Text(_profile?['email'] ?? '', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: C.textSub)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: C.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Text('ADMIN', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: C.warning)),
          ),
        ]),
      ),
      const SizedBox(height: 24),
      const Text('ACTIONS', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: C.textMuted, letterSpacing: 1)),
      const SizedBox(height: 12),
      _settingsTile(Icons.person_outline_rounded, 'Edit Profile', () => context.push('/profile')),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: C.error),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Logout', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          onPressed: () async {
            await ref.read(authProvider.notifier).logout();
            if (mounted) context.go('/login');
          },
        ),
      ),
    ]);
  }

  Widget _settingsTile(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
        child: Row(children: [
          Icon(icon, color: C.primary, size: 20),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: C.text)),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded, color: C.textMuted, size: 20),
        ]),
      ),
    );
  }
}
