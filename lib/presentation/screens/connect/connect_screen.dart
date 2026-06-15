import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/core/constants/app_constants.dart';
import 'package:lifeos/presentation/providers/connect_provider.dart';
import 'package:lifeos/services/api/api_client.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});
  @override
  ConsumerState<ConnectScreen> createState() => _ConnectState();
}

class _ConnectState extends ConsumerState<ConnectScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Map<String, dynamic>> _friends = [];
  Map<String, dynamic> _requests = {'incoming': [], 'outgoing': []};
  List<Map<String, dynamic>> _searchResults = [];
  final _search = TextEditingController();
  bool _loadingFriends = true;
  bool _loadingRequests = true;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadFriends();
    _loadRequests();
  }

  @override
  void dispose() { _tabs.dispose(); _search.dispose(); super.dispose(); }

  Future<void> _loadFriends() async {
    setState(() => _loadingFriends = true);
    try {
      final items = await ref.read(connectServiceProvider).listFriends();
      setState(() { _friends = items; _loadingFriends = false; });
    } catch (_) { setState(() => _loadingFriends = false); }
  }

  Future<void> _loadRequests() async {
    setState(() => _loadingRequests = true);
    try {
      final r = await ref.read(connectServiceProvider).listFriendRequests();
      setState(() { _requests = r; _loadingRequests = false; });
    } catch (_) { setState(() => _loadingRequests = false); }
  }

  Future<void> _doSearch(String q) async {
    if (q.trim().length < 2) { setState(() => _searchResults = []); return; }
    setState(() => _searching = true);
    try {
      final items = await ref.read(connectServiceProvider).search(q.trim());
      setState(() { _searchResults = items; _searching = false; });
    } catch (_) { setState(() => _searching = false); }
  }

  Future<void> _sendRequest(String username) async {
    try {
      await ref.read(connectServiceProvider).sendFriendRequest(username);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Friend request sent'), backgroundColor: C.success));
        _doSearch(_search.text);
      }
    } on DioException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractError(e)), backgroundColor: C.error));
    }
  }

  Future<void> _respond(int id, String action) async {
    try {
      await ref.read(connectServiceProvider).respondFriendRequest(id, action);
      _loadRequests();
      if (action == 'accept') _loadFriends();
    } on DioException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractError(e)), backgroundColor: C.error));
    }
  }

  Future<void> _removeFriend(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Remove Friend', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
      content: const Text('This will remove the friendship and you will lose access to chat.', style: TextStyle(fontFamily: 'Inter', color: C.textSub)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: C.error), onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
      ],
    ));
    if (ok == true) {
      try {
        await ref.read(connectServiceProvider).removeFriend(id);
        _loadFriends();
      } catch (_) {}
    }
  }

  String? _photoUrl(String? u) {
    if (u == null) return null;
    if (u.startsWith('http')) return u;
    return '${AppConstants.baseUrl}$u';
  }

  @override
  Widget build(BuildContext context) {
    final incoming = List<Map<String, dynamic>>.from(_requests['incoming'] ?? []);
    final outgoing = List<Map<String, dynamic>>.from(_requests['outgoing'] ?? []);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => context.pop()),
        bottom: TabBar(controller: _tabs,
          labelColor: C.primary, unselectedLabelColor: C.textMuted,
          indicatorColor: C.primary, indicatorWeight: 2,
          labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            const Tab(text: 'Friends'),
            Tab(text: 'Requests${incoming.isNotEmpty ? ' (${incoming.length})' : ''}'),
            const Tab(text: 'Find Friends'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        _buildFriends(),
        _buildRequests(incoming, outgoing),
        _buildFind(),
      ]),
    );
  }

  Widget _buildFriends() {
    if (_loadingFriends) return const Center(child: CircularProgressIndicator());
    if (_friends.isEmpty) {
      return RefreshIndicator(onRefresh: _loadFriends, child: ListView(children: [
        const SizedBox(height: 80),
        Center(child: Column(children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: C.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.people_outline_rounded, color: C.primary, size: 40)),
          const SizedBox(height: 16),
          const Text('No friends yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.text, fontFamily: 'Inter')),
          const SizedBox(height: 8),
          const Text('Find friends by username to start chatting', style: TextStyle(fontSize: 13, color: C.textSub, fontFamily: 'Inter')),
        ])),
      ]));
    }
    final notif = ref.watch(connectNotificationsProvider);
    final unreadByFriend = notif.maybeWhen(
      data: (d) => Map<String, dynamic>.from(d['unread_by_friend'] ?? {}),
      orElse: () => <String, dynamic>{},
    );
    return RefreshIndicator(onRefresh: _loadFriends, child: ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _friends.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: C.border, indent: 70),
      itemBuilder: (_, i) {
        final f = _friends[i];
        final photo = _photoUrl(f['profile_photo_url']?.toString());
        final unread = (unreadByFriend['${f['id']}'] ?? 0) as int;
        return ListTile(
          leading: Stack(children: [
            CircleAvatar(radius: 22, backgroundColor: C.primary.withOpacity(0.12),
              backgroundImage: photo != null ? NetworkImage(photo) : null,
              child: photo == null ? Text((f['username'] ?? '?')[0].toString().toUpperCase(), style: const TextStyle(color: C.primary, fontFamily: 'Inter', fontWeight: FontWeight.w700)) : null),
            if (f['online'] == true) Positioned(bottom: 0, right: 0, child: Container(width: 12, height: 12,
              decoration: BoxDecoration(color: C.success, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
          ]),
          title: Text('@${f['username']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.text, fontFamily: 'Inter')),
          subtitle: Text(f['full_name'] ?? (f['bio'] ?? ''), style: const TextStyle(fontSize: 12, color: C.textSub, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: unread > 0
            ? Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: C.error, borderRadius: BorderRadius.circular(10)),
                child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w700)))
            : IconButton(icon: const Icon(Icons.more_vert_rounded, color: C.textMuted, size: 18), onPressed: () => _removeFriend(f['id'])),
          onTap: () => context.push('/connect/chat/${f['id']}', extra: f),
        );
      },
    ));
  }

  Widget _buildRequests(List<Map<String, dynamic>> incoming, List<Map<String, dynamic>> outgoing) {
    if (_loadingRequests) return const Center(child: CircularProgressIndicator());
    if (incoming.isEmpty && outgoing.isEmpty) {
      return RefreshIndicator(onRefresh: _loadRequests, child: ListView(children: [
        const SizedBox(height: 80),
        const Center(child: Text('No pending friend requests', style: TextStyle(color: C.textSub, fontFamily: 'Inter'))),
      ]));
    }
    return RefreshIndicator(onRefresh: _loadRequests, child: ListView(padding: const EdgeInsets.all(16), children: [
      if (incoming.isNotEmpty) ...[
        const Text('INCOMING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: C.textMuted, fontFamily: 'Inter', letterSpacing: 1)),
        const SizedBox(height: 8),
        ...incoming.map((r) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
          child: Row(children: [
            CircleAvatar(radius: 18, backgroundColor: C.primary.withOpacity(0.12),
              child: Text((r['username'] ?? '?')[0].toString().toUpperCase(), style: const TextStyle(color: C.primary, fontFamily: 'Inter', fontWeight: FontWeight.w700))),
            const SizedBox(width: 12),
            Expanded(child: Text('@${r['username']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text, fontFamily: 'Inter'))),
            IconButton(icon: const Icon(Icons.check_circle, color: C.success), onPressed: () => _respond(r['id'], 'accept')),
            IconButton(icon: const Icon(Icons.cancel, color: C.error), onPressed: () => _respond(r['id'], 'reject')),
          ]))),
        const SizedBox(height: 16),
      ],
      if (outgoing.isNotEmpty) ...[
        const Text('OUTGOING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: C.textMuted, fontFamily: 'Inter', letterSpacing: 1)),
        const SizedBox(height: 8),
        ...outgoing.map((r) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
          child: Row(children: [
            CircleAvatar(radius: 18, backgroundColor: C.primary.withOpacity(0.12),
              child: Text((r['username'] ?? '?')[0].toString().toUpperCase(), style: const TextStyle(color: C.primary, fontFamily: 'Inter', fontWeight: FontWeight.w700))),
            const SizedBox(width: 12),
            Expanded(child: Text('@${r['username']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text, fontFamily: 'Inter'))),
            const Text('Pending', style: TextStyle(fontSize: 12, color: C.textMuted, fontFamily: 'Inter')),
          ]))),
      ],
    ]));
  }

  Widget _buildFind() {
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: TextField(
        controller: _search, autofocus: false,
        decoration: const InputDecoration(hintText: 'Search by username...', prefixIcon: Icon(Icons.search_rounded)),
        onChanged: _doSearch,
      )),
      if (_searching) const LinearProgressIndicator(),
      Expanded(child: _searchResults.isEmpty
        ? Center(child: Text(_search.text.trim().length < 2 ? 'Type at least 2 characters to search' : 'No users found', style: const TextStyle(color: C.textSub, fontFamily: 'Inter')))
        : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _searchResults.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: C.border),
            itemBuilder: (_, i) {
              final u = _searchResults[i];
              final status = u['status'] as String;
              return ListTile(
                leading: CircleAvatar(radius: 18, backgroundColor: C.primary.withOpacity(0.12),
                  child: Text((u['username'] ?? '?')[0].toString().toUpperCase(), style: const TextStyle(color: C.primary, fontFamily: 'Inter', fontWeight: FontWeight.w700))),
                title: Text('@${u['username']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text, fontFamily: 'Inter')),
                trailing: _statusWidget(status, u['username']),
              );
            },
          )),
    ]);
  }

  Widget _statusWidget(String status, String username) {
    switch (status) {
      case 'friends':
        return const Text('Friends', style: TextStyle(fontSize: 12, color: C.success, fontFamily: 'Inter', fontWeight: FontWeight.w600));
      case 'outgoing':
        return const Text('Requested', style: TextStyle(fontSize: 12, color: C.textMuted, fontFamily: 'Inter'));
      case 'incoming':
        return const Text('Respond in Requests', style: TextStyle(fontSize: 11, color: C.warning, fontFamily: 'Inter'));
      default:
        return TextButton(onPressed: () => _sendRequest(username), child: const Text('Add Friend'));
    }
  }
}
