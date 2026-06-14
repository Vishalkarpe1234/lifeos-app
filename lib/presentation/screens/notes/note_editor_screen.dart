import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/notes_provider.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final int? noteId;
  final Note? existingNote;
  const NoteEditorScreen({super.key, this.noteId, this.existingNote});
  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  bool _isPinned = false;
  bool _saving = false;
  Note? _note;

  @override
  void initState() {
    super.initState();
    _note = widget.existingNote;
    _titleCtrl = TextEditingController(text: _note?.title ?? '');
    _contentCtrl = TextEditingController(text: _note?.content ?? '');
    _isPinned = _note?.isPinned ?? false;
  }

  @override
  void dispose() { _titleCtrl.dispose(); _contentCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required'))); return; }
    setState(() => _saving = true);
    bool success;
    if (_note != null) {
      success = await ref.read(notesProvider.notifier).updateNote(id: _note!.id, title: title, content: _contentCtrl.text.trim(), isPinned: _isPinned);
    } else {
      success = await ref.read(notesProvider.notifier).createNote(title: title, content: _contentCtrl.text.trim(), isPinned: _isPinned);
    }
    if (mounted) {
      setState(() => _saving = false);
      if (success) context.pop();
      else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save note'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_note == null ? 'New Note' : 'Edit Note'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.text, size: 20), onPressed: () => context.pop()),
        actions: [
          IconButton(icon: Icon(_isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined, color: _isPinned ? AppColors.primary : AppColors.textMuted), onPressed: () => setState(() => _isPinned = !_isPinned)),
          _saving
            ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)))
            : TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: AppColors.primary, fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15))),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text, fontFamily: 'Inter'),
            decoration: const InputDecoration(hintText: 'Title', hintStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textMuted, fontFamily: 'Inter'), border: InputBorder.none, fillColor: Colors.transparent, filled: false),
          ),
          const Divider(color: AppColors.border),
          Expanded(
            child: TextField(
              controller: _contentCtrl,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontSize: 15, color: AppColors.text, fontFamily: 'Inter', height: 1.6),
              decoration: const InputDecoration(hintText: 'Start writing...', hintStyle: TextStyle(fontSize: 15, color: AppColors.textMuted, fontFamily: 'Inter'), border: InputBorder.none, fillColor: Colors.transparent, filled: false),
            ),
          ),
        ]),
      ),
    );
  }
}
