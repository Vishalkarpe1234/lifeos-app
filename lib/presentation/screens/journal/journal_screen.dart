import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/journal_provider.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});
  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(journalProvider.notifier).fetch();
    });
  }

  String _moodEmoji(String? mood) {
    switch (mood) {
      case 'happy': return '😊';
      case 'neutral': return '😐';
      case 'sad': return '😔';
      case 'productive': return '🔥';
      case 'tired': return '😴';
      default: return '📓';
    }
  }

  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) { return d; }
  }

  void _openEditor({JournalEntry? entry}) {
    Navigator.push(context, MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _JournalEditorScreen(entry: entry),
    )).then((_) => ref.read(journalProvider.notifier).fetch());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(journalProvider);

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Journal')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: C.error, size: 40),
                  const SizedBox(height: 12),
                  Text(state.error!, style: const TextStyle(color: C.textSub, fontFamily: 'Inter')),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => ref.read(journalProvider.notifier).fetch(), child: const Text('Retry')),
                ]))
              : state.entries.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: () => ref.read(journalProvider.notifier).fetch(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: state.entries.length,
                        itemBuilder: (_, i) {
                          final e = state.entries[i];
                          return GestureDetector(
                            onTap: () => _openEditor(entry: e),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: C.border),
                              ),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Text(_moodEmoji(e.mood), style: const TextStyle(fontSize: 24)),
                                  const SizedBox(width: 10),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(
                                      e.title?.isNotEmpty == true ? e.title! : 'Journal Entry',
                                      style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: C.text),
                                    ),
                                    Text(_fmtDate(e.date), style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: C.textMuted)),
                                  ])),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.delete_outline_rounded, color: C.error, size: 18),
                                    onPressed: () async {
                                      final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                                        title: const Text('Delete Entry', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                                        content: const Text('Delete this journal entry?', style: TextStyle(fontFamily: 'Inter', color: C.textSub)),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: C.error), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                        ],
                                      ));
                                      if (ok == true) ref.read(journalProvider.notifier).delete(e.id);
                                    },
                                  ),
                                ]),
                                if (e.content.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(e.content, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: C.textSub, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                                ],
                                if (e.gratitude.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    const Text('🙏 ', style: TextStyle(fontSize: 12)),
                                    Expanded(child: Text('${e.gratitude.length} gratitude items', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: C.textMuted))),
                                  ]),
                                ],
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Write Today', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        backgroundColor: C.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80, decoration: BoxDecoration(color: C.primary.withOpacity(0.1), shape: BoxShape.circle),
      child: const Icon(Icons.menu_book_rounded, color: C.primary, size: 40)),
    const SizedBox(height: 16),
    const Text('No journal entries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.text, fontFamily: 'Inter')),
    const SizedBox(height: 8),
    const Text('Start writing your thoughts', style: TextStyle(fontSize: 13, color: C.textSub, fontFamily: 'Inter')),
    const SizedBox(height: 24),
    ElevatedButton.icon(
      onPressed: () => _openEditor(),
      icon: const Icon(Icons.edit_note_rounded),
      label: const Text('Write Today', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
    ),
  ]));
}

class _JournalEditorScreen extends ConsumerStatefulWidget {
  final JournalEntry? entry;
  const _JournalEditorScreen({this.entry});
  @override
  ConsumerState<_JournalEditorScreen> createState() => _JournalEditorState();
}

class _JournalEditorState extends ConsumerState<_JournalEditorScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  String? _mood;
  bool _saving = false;

  final List<TextEditingController> _gratitudeCtrl = [
    TextEditingController(), TextEditingController(), TextEditingController(),
  ];
  final List<TextEditingController> _highlightCtrl = [TextEditingController(), TextEditingController()];
  final List<TextEditingController> _tomorrowCtrl = [TextEditingController(), TextEditingController()];

  final _moods = [
    ('happy', '😊', 'Happy'),
    ('neutral', '😐', 'Neutral'),
    ('sad', '😔', 'Sad'),
    ('productive', '🔥', 'Productive'),
    ('tired', '😴', 'Tired'),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _contentCtrl = TextEditingController(text: e?.content ?? '');
    _mood = e?.mood;
    if (e != null) {
      for (int i = 0; i < e.gratitude.length && i < 3; i++) {
        _gratitudeCtrl[i].text = e.gratitude[i];
      }
      for (int i = 0; i < e.highlights.length && i < 2; i++) {
        _highlightCtrl[i].text = e.highlights[i];
      }
      for (int i = 0; i < e.goalsTomorrow.length && i < 2; i++) {
        _tomorrowCtrl[i].text = e.goalsTomorrow[i];
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    for (final c in [..._gratitudeCtrl, ..._highlightCtrl, ..._tomorrowCtrl]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (_contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Content is required'), backgroundColor: C.error));
      return;
    }
    setState(() => _saving = true);
    final gratitude = _gratitudeCtrl.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    final highlights = _highlightCtrl.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    final tomorrow = _tomorrowCtrl.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

    bool ok;
    if (widget.entry != null) {
      ok = await ref.read(journalProvider.notifier).update(
        widget.entry!.id,
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        mood: _mood,
        gratitude: gratitude,
        highlights: highlights,
        goalsTomorrow: tomorrow,
      );
    } else {
      ok = await ref.read(journalProvider.notifier).create(
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        mood: _mood,
        gratitude: gratitude,
        highlights: highlights,
        goalsTomorrow: tomorrow,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Saved!' : 'Failed to save'),
        backgroundColor: ok ? C.success : C.error,
      ));
      if (ok) Navigator.pop(context);
      else setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Text(widget.entry != null ? 'Edit Entry' : 'New Entry'),
        actions: [
          _saving
              ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
              : TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: C.primary, fontSize: 15))),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 60), children: [
        // Mood selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('How are you feeling?', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14, color: C.text)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: _moods.map((m) => GestureDetector(
              onTap: () => setState(() => _mood = m.$1),
              child: Column(children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: _mood == m.$1 ? C.primary.withOpacity(0.1) : C.bg,
                    shape: BoxShape.circle,
                    border: _mood == m.$1 ? Border.all(color: C.primary, width: 2) : null,
                  ),
                  child: Center(child: Text(m.$2, style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(height: 4),
                Text(m.$3, style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: _mood == m.$1 ? C.primary : C.textMuted)),
              ]),
            )).toList()),
          ]),
        ),
        const SizedBox(height: 12),

        // Title
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(labelText: 'Title (optional)', hintText: 'Give your entry a title...'),
          style: const TextStyle(fontFamily: 'Inter'),
        ),
        const SizedBox(height: 12),

        // Content
        TextField(
          controller: _contentCtrl,
          maxLines: 8,
          decoration: const InputDecoration(labelText: 'Your thoughts *', hintText: 'Write freely...', alignLabelWithHint: true),
          style: const TextStyle(fontFamily: 'Inter', height: 1.6),
        ),
        const SizedBox(height: 16),

        // Gratitude
        _section('🙏 Gratitude', 'What are you grateful for?', _gratitudeCtrl),
        const SizedBox(height: 12),
        _section('✨ Highlights', 'Best moments of the day', _highlightCtrl),
        const SizedBox(height: 12),
        _section('🎯 Plan for Tomorrow', "Tomorrow's intentions", _tomorrowCtrl),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Entry', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ]),
    );
  }

  Widget _section(String title, String hint, List<TextEditingController> ctrls) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14, color: C.text)),
        const SizedBox(height: 4),
        Text(hint, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.textSub)),
        const SizedBox(height: 10),
        ...ctrls.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: e.value,
            decoration: InputDecoration(
              hintText: '${e.key + 1}.',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
          ),
        )),
      ]),
    );
  }
}
