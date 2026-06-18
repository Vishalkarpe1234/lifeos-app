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

  // Users tab
  List<Map<String, dynamic>> _users = [];
  bool _loadingUsers = true;
  final Set<int> _selected = {};
  bool _selectMode = false;
  String _search = '';

  // Overview/Analytics
  Map<String, dynamic>? _analytics;
  bool _loadingAnalytics = true;

  // Connect overview
  Map<String, dynamic>? _connectOverview;
  bool _loadingConnect = true;

  // Profile
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _loadUsers();
    _loadAnalytics();
    _loadConnectOverview();
    _loadProfile();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final r = await ref.read(dioProvider).get('/api/v1/admin/users');
      setState(() {
        _users = List<Map<String, dynamic>>.from(r.data);
        _loadingUsers = false;
      });
    } catch (_) {
      setState(() => _loadingUsers = false);
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loadingAnalytics = true);
    try {
      final r = await ref.read(dioProvider).get('/api/v1/admin/analytics');
      setState(() { _analytics = r.data; _loadingAnalytics = false; });
    } catch (_) {
      setState(() => _loadingAnalytics = false);
    }
  }

  Future<void> _loadConnectOverview() async {
    setState(() => _loadingConnect = true);
    try {
      final r = await ref.read(dioProvider).get('/api/v1/connect/admin/overview');
      setState(() { _connectOverview = r.data; _loadingConnect = false; });
    } catch (_) {
      setState(() => _loadingConnect = false);
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
        content: Text('Delete ${_selected.length} user(s)?'),
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
    for (final id in _selected) {
      try { await ref.read(dioProvider).delete('/api/v1/admin/users/$id'); } catch (_) {}
    }
    setState(() { _selected.clear(); _selectMode = false; });
    await _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          if (_selectMode) ...[
            Text('${_selected.length} selected', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: C.textSub)),
            const SizedBox(width: 8),
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
          isScrollable: true,
          labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13),
          indicatorColor: C.primary,
          labelColor: C.primary,
          unselectedLabelColor: C.textSub,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Connect'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildOverviewTab(),
          _buildUsersTab(),
          _buildConnectTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_loadingAnalytics) return const Center(child: CircularProgressIndicator());
    if (_analytics == null) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: C.error, size: 40),
      const SizedBox(height: 12),
      const Text('Failed to load analytics', style: TextStyle(fontFamily: 'Inter', color: C.textSub)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _loadAnalytics, child: const Text('Retry')),
    ]));

    final a = _analytics!;
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('PLATFORM ANALYTICS', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: C.textMuted, letterSpacing: 1)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
          children: [
            _statCard('Users', '${a['total_users'] ?? 0}', Icons.people_outline_rounded, C.primary),
            _statCard('Tasks', '${a['total_tasks'] ?? 0}', Icons.task_alt_rounded, C.success),
            _statCard('Completed Tasks', '${a['completed_tasks'] ?? 0}', Icons.check_circle_outline_rounded, C.warning),
            _statCard('Habits', '${a['total_habits'] ?? 0}', Icons.local_fire_department_rounded, const Color(0xFFFF6B35)),
            _statCard('Journal Entries', '${a['total_journals'] ?? 0}', Icons.menu_book_rounded, const Color(0xFF8B5CF6)),
            _statCard('Goals', '${a['total_goals'] ?? 0}', Icons.flag_rounded, const Color(0xFF06B6D4)),
          ],
        ),
      ]),
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
                                else
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.location_on_rounded, color: C.primary, size: 20),
                                    onPressed: () => context.push('/admin/users/$uid/location', extra: u),
                                  ),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
      ),
    ]);
  }

  Widget _buildConnectTab() {
    if (_loadingConnect) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadConnectOverview,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('CONNECT OVERVIEW', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: C.textMuted, letterSpacing: 1)),
        const SizedBox(height: 12),
        if (_connectOverview != null) ...[
          _overviewTile(Icons.people_outline_rounded, 'Total Connections', '${_connectOverview!['total_connections'] ?? 0}'),
          _overviewTile(Icons.message_outlined, 'Total Messages', '${_connectOverview!['total_messages'] ?? 0}'),
          _overviewTile(Icons.pending_outlined, 'Pending Requests', '${_connectOverview!['pending_requests'] ?? 0}'),
        ] else
          const Text('No connect data available', style: TextStyle(fontFamily: 'Inter', color: C.textSub)),
      ]),
    );
  }

  Widget _overviewTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: C.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: C.primary, size: 18)),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: C.textSub))),
        Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800, color: C.text)),
      ]),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(padding: const EdgeInsets.all(20), children: [
      // Profile card
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
      _settingsTile(Icons.people_outline_rounded, 'Connect / Chat', () => context.push('/connect')),
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
