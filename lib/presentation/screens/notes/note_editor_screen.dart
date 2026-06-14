import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/notes_provider.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final int? noteId;
  const NoteEditorScreen({super.key, this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _isPreview = false;
  bool _isSaving = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.noteId != null) _loadNote();
  }

  Future<void> _loadNote() async {
    final note = await ref.read(noteDetailProvider(widget.noteId!).future);
    if (note != null && mounted) {
      _titleCtrl.text = note['title'] ?? '';
      _contentCtrl.text = note['content'] ?? '';
      setState(() => _isLoaded = true);
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty) return;
    setState(() => _isSaving = true);
    final notifier = ref.read(notesProvider.notifier);
    if (widget.noteId != null) {
      await notifier.updateNote(widget.noteId!, title: _titleCtrl.text, content: _contentCtrl.text);
    } else {
      await notifier.createNote(title: _titleCtrl.text, content: _contentCtrl.text);
    }
    setState(() => _isSaving = false);
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text(widget.noteId == null ? 'New Note' : 'Edit Note', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(_isPreview ? Icons.edit_outlined : Icons.preview_outlined),
            onPressed: () => setState(() => _isPreview = !_isPreview),
            tooltip: _isPreview ? 'Edit' : 'Preview',
          ),
          if (_isSaving)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
          else
            IconButton(icon: const Icon(Icons.check, color: AppColors.primary), onPressed: _save, tooltip: 'Save'),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter'),
              decoration: const InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
              ),
            ),
            const Divider(color: AppColors.darkBorder, height: 1),
            const SizedBox(height: 16),
            Expanded(
              child: _isPreview
                  ? Markdown(
                      data: _contentCtrl.text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Inter', fontSize: 15, height: 1.6),
                        h1: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
                        h2: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                        h3: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                        code: const TextStyle(color: AppColors.accent, backgroundColor: AppColors.darkCard, fontFamily: 'monospace', fontSize: 13),
                        blockquoteDecoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: BorderRadius.circular(4),
                          border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
                        ),
                      ),
                    )
                  : TextField(
                      controller: _contentCtrl,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontFamily: 'Inter', height: 1.6),
                      decoration: const InputDecoration(
                        hintText: 'Start writing in Markdown...\n\n# Heading\n**bold** *italic*\n- list item',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontFamily: 'Inter', fontSize: 14),
                        border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
