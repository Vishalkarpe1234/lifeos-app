import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/notes_provider.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});
  @override
  ConsumerState<NoteEditorScreen> createState() => _EditorState();
}

class _EditorState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.note?.title ?? '');
    _content = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() { _title.dispose(); _content.dispose(); super.dispose(); }

  Future<void> _save() async {
    final t = _title.text.trim();
    if (t.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title'), backgroundColor: C.warning)); return; }
    setState(() => _saving = true);
    final ok = widget.note == null
      ? await ref.read(notesProvider.notifier).create(t, _content.text.trim())
      : await ref.read(notesProvider.notifier).update(widget.note!.id, t, _content.text.trim());
    if (mounted) {
      setState(() => _saving = false);
      if (ok) context.pop();
      else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save'), backgroundColor: C.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.pop()),
        actions: [_saving
          ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          : TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: C.primary, fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Inter')))],
      ),
      body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        TextField(
          controller: _title, autofocus: widget.note == null,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: C.text, fontFamily: 'Inter'),
          decoration: const InputDecoration(hintText: 'Title', border: InputBorder.none, fillColor: Colors.transparent, filled: false,
            hintStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: C.textMuted, fontFamily: 'Inter')),
        ),
        const Divider(color: C.border, height: 1),
        const SizedBox(height: 8),
        Expanded(child: TextField(
          controller: _content, maxLines: null, expands: true,
          style: const TextStyle(fontSize: 15, color: C.text, fontFamily: 'Inter', height: 1.7),
          decoration: const InputDecoration(hintText: 'Write your note here...', border: InputBorder.none, fillColor: Colors.transparent, filled: false,
            hintStyle: TextStyle(fontSize: 15, color: C.textMuted, fontFamily: 'Inter')),
        )),
      ])),
    );
  }
}
