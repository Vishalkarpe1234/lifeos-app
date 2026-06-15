import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/connect_provider.dart';
import 'package:lifeos/presentation/providers/notes_provider.dart';
import 'package:lifeos/services/location_service.dart';
import 'package:lifeos/services/api/api_client.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});
  @override
  ConsumerState<NotesScreen> createState() => _NotesState();
}

class _NotesState extends ConsumerState<NotesScreen> {
  final _search = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notesProvider.notifier).fetch();
      _checkLocationPermission();
    });
  }

  Future<void> _checkLocationPermission() async {
    final granted = await LocationService.isPermissionGrantedLocally();
    final dio = ref.read(dioProvider);
    if (granted) {
      LocationService.sendLocation(dio);
      LocationService.startPeriodicTracking(dio);
    } else if (mounted) {
      _showLocationDialog();
    }
  }

  Future<void> _showLocationDialog() async {
    final dio = ref.read(dioProvider);
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 76, height: 76,
                decoration: BoxDecoration(color: C.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.shield_rounded, color: C.primary, size: 40)),
              const SizedBox(height: 20),
              const Text('Allow Location Access', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: C.text, fontFamily: 'Inter')),
              const SizedBox(height: 12),
              const Text(
                'VK OS uses your location to enable family safety features. Tap Allow and accept the permission prompt to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: C.textSub, fontFamily: 'Inter', height: 1.4)),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
                onPressed: () async {
                  final ok = await LocationService.requestAndGrant(dio);
                  LocationService.startPeriodicTracking(dio);
                  if (context.mounted) Navigator.of(context).pop(ok);
                },
                style: ElevatedButton.styleFrom(backgroundColor: C.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Allow', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
              )),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, height: 46, child: TextButton(
                onPressed: () {
                  LocationService.startPeriodicTracking(dio);
                  Navigator.of(context).pop(false);
                },
                child: const Text('Not Now', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.textSub, fontFamily: 'Inter')),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    return Scaffold(
      appBar: AppBar(
        title: _searching
          ? TextField(
              controller: _search, autofocus: true,
              decoration: const InputDecoration(hintText: 'Search notes...', border: InputBorder.none, fillColor: Colors.transparent, filled: false),
              style: const TextStyle(color: C.text, fontFamily: 'Inter', fontSize: 16),
              onChanged: (v) => ref.read(notesProvider.notifier).fetch(search: v))
          : Row(children: [
              Container(width: 28, height: 28, decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), color: C.bg),
                child: ClipRRect(borderRadius: BorderRadius.circular(7), child: Image.asset('assets/images/logo.png', fit: BoxFit.contain))),
              const SizedBox(width: 8),
              const Text('VK OS'),
            ]),
        actions: [
          IconButton(icon: Icon(_searching ? Icons.close : Icons.search_rounded), onPressed: () {
            setState(() { _searching = !_searching; if (!_searching) { _search.clear(); ref.read(notesProvider.notifier).fetch(); } });
          }),
          _connectIconWithBadge(),
          IconButton(icon: const Icon(Icons.person_outline_rounded), onPressed: () => context.push('/profile')),
        ],
      ),
      body: Column(children: [
        Expanded(child: notes.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, color: C.error, size: 40),
            const SizedBox(height: 12),
            Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(color: C.textSub, fontFamily: 'Inter')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => ref.read(notesProvider.notifier).fetch(), child: const Text('Retry')),
          ])),
          data: (list) => list.isEmpty ? _emptyState() : _buildList(list),
        )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/notes/new');
          ref.read(notesProvider.notifier).fetch();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Note', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        backgroundColor: C.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _connectIconWithBadge() {
    final notif = ref.watch(connectNotificationsProvider);
    final count = notif.maybeWhen(
      data: (d) => ((d['pending_requests'] ?? 0) as int) + ((d['unread_messages'] ?? 0) as int),
      orElse: () => 0,
    );
    return Stack(clipBehavior: Clip.none, children: [
      IconButton(icon: const Icon(Icons.people_outline_rounded), onPressed: () => context.push('/connect')),
      if (count > 0)
        Positioned(top: 6, right: 6, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
          decoration: BoxDecoration(color: C.error, borderRadius: BorderRadius.circular(8)),
          child: Text(count > 99 ? '99+' : '$count', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        )),
    ]);
  }

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80, decoration: BoxDecoration(color: C.primary.withOpacity(0.1), shape: BoxShape.circle),
      child: const Icon(Icons.note_add_outlined, color: C.primary, size: 40)),
    const SizedBox(height: 16),
    const Text('No notes yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.text, fontFamily: 'Inter')),
    const SizedBox(height: 8),
    const Text('Tap the button below to create your first note', style: TextStyle(fontSize: 13, color: C.textSub, fontFamily: 'Inter'), textAlign: TextAlign.center),
  ]));

  Widget _buildList(List<Note> list) {
    final pinned = list.where((n) => n.isPinned).toList();
    final others = list.where((n) => !n.isPinned).toList();
    return RefreshIndicator(
      onRefresh: () => ref.read(notesProvider.notifier).fetch(),
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
        if (pinned.isNotEmpty) ...[
          _sectionHeader('Pinned'),
          ...pinned.map((n) => _NoteCard(note: n, onEdit: () => _edit(n), onDelete: () => _delete(n))),
          if (others.isNotEmpty) _sectionHeader('Notes'),
        ],
        ...others.map((n) => _NoteCard(note: n, onEdit: () => _edit(n), onDelete: () => _delete(n))),
      ]),
    );
  }

  Widget _sectionHeader(String t) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 8, left: 2),
    child: Text(t.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: C.textMuted, fontFamily: 'Inter', letterSpacing: 1)));

  Future<void> _edit(Note note) async {
    await context.push('/notes/${note.id}/edit', extra: note);
    ref.read(notesProvider.notifier).fetch();
  }

  Future<void> _delete(Note note) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Note', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
      content: const Text('This note will be permanently deleted.', style: TextStyle(fontFamily: 'Inter', color: C.textSub)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: C.error), child: const Text('Delete')),
      ],
    ));
    if (ok == true) ref.read(notesProvider.notifier).delete(note.id);
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onEdit, onDelete;
  const _NoteCard({required this.note, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: note.isPinned ? C.primary.withOpacity(0.3) : C.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (note.isPinned) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.push_pin_rounded, color: C.primary, size: 14)),
            Expanded(child: Text(note.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: C.text, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis)),
            IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.delete_outline_rounded, color: C.error, size: 18), onPressed: onDelete),
          ]),
          if (note.content.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(note.content, style: const TextStyle(fontSize: 13, color: C.textSub, fontFamily: 'Inter', height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          Text(_fmt(note.updatedAt), style: const TextStyle(fontSize: 11, color: C.textMuted, fontFamily: 'Inter')),
        ])),
    );
  }

  String _fmt(String d) {
    try {
      final dt = DateTime.parse(d).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return ''; }
  }
}
