import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/notes_provider.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});
  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(notesProvider.notifier).fetchNotes());
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(notesProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: _searching
          ? TextField(controller: _searchCtrl, autofocus: true, style: const TextStyle(color: AppColors.text, fontFamily: 'Inter'),
              decoration: const InputDecoration(hintText: 'Search notes...', hintStyle: TextStyle(color: AppColors.textMuted), border: InputBorder.none, fillColor: Colors.transparent),
              onChanged: (v) => ref.read(notesProvider.notifier).fetchNotes(search: v))
          : Row(children: [
              Container(width: 30, height: 30, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white, boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 6)]),
                child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset('assets/images/logo.png', fit: BoxFit.contain))),
              const SizedBox(width: 10),
              const Text('VK OS', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, color: AppColors.text, fontSize: 20)),
            ]),
        actions: [
          IconButton(icon: Icon(_searching ? Icons.close : Icons.search_rounded, color: AppColors.text), onPressed: () { setState(() { _searching = !_searching; if (!_searching) { _searchCtrl.clear(); ref.read(notesProvider.notifier).fetchNotes(); } }); }),
          IconButton(icon: const Icon(Icons.person_outline_rounded, color: AppColors.text), onPressed: () => context.go('/profile')),
        ],
      ),
      body: notesState.isLoading && notesState.notes.isEmpty
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : notesState.notes.isEmpty
          ? _buildEmpty()
          : _buildNotesList(notesState.notes),
      floatingActionButton: FloatingActionButton(
        onPressed: () async { await context.push('/notes/new'); ref.read(notesProvider.notifier).fetchNotes(); },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.note_add_outlined, color: AppColors.primary, size: 40)),
          const SizedBox(height: 16),
          const Text('No notes yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text, fontFamily: 'Inter')),
          const SizedBox(height: 8),
          const Text('Tap + to create your first note', style: TextStyle(fontSize: 14, color: AppColors.textSub, fontFamily: 'Inter')),
        ],
      ),
    );
  }

  Widget _buildNotesList(List<Note> notes) {
    final pinned = notes.where((n) => n.isPinned).toList();
    final others = notes.where((n) => !n.isPinned).toList();
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(notesProvider.notifier).fetchNotes(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          if (pinned.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.only(bottom: 8, top: 4), child: Text('Pinned', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted, fontFamily: 'Inter', letterSpacing: 0.8))),
            ...pinned.map((n) => _NoteCard(note: n, onTap: () async { await context.push('/notes/${n.id}/edit', extra: n); ref.read(notesProvider.notifier).fetchNotes(); }, onDelete: () => _deleteNote(n), onPin: () => ref.read(notesProvider.notifier).togglePin(n))),
          ],
          if (others.isNotEmpty) ...[
            if (pinned.isNotEmpty) const Padding(padding: EdgeInsets.only(bottom: 8, top: 12), child: Text('All Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted, fontFamily: 'Inter', letterSpacing: 0.8))),
            ...others.map((n) => _NoteCard(note: n, onTap: () async { await context.push('/notes/${n.id}/edit', extra: n); ref.read(notesProvider.notifier).fetchNotes(); }, onDelete: () => _deleteNote(n), onPin: () => ref.read(notesProvider.notifier).togglePin(n))),
          ],
        ],
      ),
    );
  }

  void _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Note', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppColors.text)),
      content: const Text('This note will be permanently deleted.', style: TextStyle(fontFamily: 'Inter', color: AppColors.textSub)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSub))),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Delete')),
      ],
    ));
    if (confirm == true) ref.read(notesProvider.notifier).deleteNote(note.id);
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap, onDelete, onPin;
  const _NoteCard({required this.note, required this.onTap, required this.onDelete, required this.onPin});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: note.isPinned ? AppColors.primary.withOpacity(0.3) : AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              if (note.isPinned) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.push_pin_rounded, color: AppColors.primary, size: 14)),
              Expanded(child: Text(note.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis)),
              GestureDetector(onTap: onPin, child: Icon(note.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined, color: note.isPinned ? AppColors.primary : AppColors.textMuted, size: 18)),
              const SizedBox(width: 8),
              GestureDetector(onTap: onDelete, child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18)),
            ]),
            if (note.content.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(note.content, style: const TextStyle(fontSize: 13, color: AppColors.textSub, fontFamily: 'Inter'), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Text(_formatDate(note.updatedAt), style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Inter')),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }
}
