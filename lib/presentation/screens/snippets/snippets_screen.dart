import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/snippet_provider.dart';

class SnippetsScreen extends ConsumerStatefulWidget {
  const SnippetsScreen({super.key});
  @override
  ConsumerState<SnippetsScreen> createState() => _SnippetsScreenState();
}

class _SnippetsScreenState extends ConsumerState<SnippetsScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedLanguage;
  final _languages = ['Python', 'JavaScript', 'Dart', 'SQL', 'Bash', 'Other'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(snippetProvider.notifier).fetch();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _langColor(String lang) {
    switch (lang.toLowerCase()) {
      case 'python': return const Color(0xFF3776AB);
      case 'javascript': return const Color(0xFFF7DF1E);
      case 'dart': return const Color(0xFF0175C2);
      case 'sql': return const Color(0xFF336791);
      case 'bash': return const Color(0xFF4EAA25);
      default: return C.textSub;
    }
  }

  void _showAddSnippet() {
    final titleCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();
    String language = 'python';
    bool isFavorite = false;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Add Snippet', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, fontSize: 18, color: C.text)),
            const SizedBox(height: 16),
            TextField(controller: titleCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Title *'), style: const TextStyle(fontFamily: 'Inter')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: language,
              decoration: const InputDecoration(labelText: 'Language'),
              items: ['python', 'javascript', 'dart', 'sql', 'bash', 'other'].map((l) => DropdownMenuItem(value: l, child: Text(l[0].toUpperCase() + l.substring(1), style: const TextStyle(fontFamily: 'Inter')))).toList(),
              onChanged: (v) => setS(() => language = v ?? 'python'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Code *', alignLabelWithHint: true, hintText: 'Paste your code here...'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)'), style: const TextStyle(fontFamily: 'Inter')),
            const SizedBox(height: 12),
            TextField(controller: tagsCtrl, decoration: const InputDecoration(labelText: 'Tags (comma separated)', hintText: 'api, auth, utility'), style: const TextStyle(fontFamily: 'Inter')),
            const SizedBox(height: 12),
            Row(children: [
              Checkbox(value: isFavorite, onChanged: (v) => setS(() => isFavorite = v ?? false), activeColor: C.primary),
              const Text('Mark as favorite', style: TextStyle(fontFamily: 'Inter', color: C.text)),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: saving ? null : () async {
                  if (titleCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Title and code are required'), backgroundColor: C.error));
                    return;
                  }
                  setS(() => saving = true);
                  final tags = tagsCtrl.text.trim().isEmpty ? <String>[] : tagsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                  final ok = await ref.read(snippetProvider.notifier).create(
                    titleCtrl.text.trim(),
                    codeCtrl.text.trim(),
                    language: language,
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    tags: tags,
                    isFavorite: isFavorite,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Snippet saved!' : 'Failed'), backgroundColor: ok ? C.success : C.error));
                  }
                },
                child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save Snippet', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(snippetProvider);

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('Code Snippets'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search snippets...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  filled: true, fillColor: C.bg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.primary)),
                ),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                onChanged: (v) => ref.read(snippetProvider.notifier).fetch(search: v, language: _selectedLanguage?.toLowerCase()),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  GestureDetector(
                    onTap: () { setState(() => _selectedLanguage = null); ref.read(snippetProvider.notifier).fetch(search: _searchCtrl.text); },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _selectedLanguage == null ? C.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _selectedLanguage == null ? C.primary : C.border),
                      ),
                      child: Text('All', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: _selectedLanguage == null ? Colors.white : C.textSub)),
                    ),
                  ),
                  ..._languages.map((l) => GestureDetector(
                    onTap: () {
                      final lang = l.toLowerCase();
                      setState(() => _selectedLanguage = _selectedLanguage == lang ? null : lang);
                      ref.read(snippetProvider.notifier).fetch(search: _searchCtrl.text, language: _selectedLanguage);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _selectedLanguage == l.toLowerCase() ? _langColor(l) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _selectedLanguage == l.toLowerCase() ? _langColor(l) : C.border),
                      ),
                      child: Text(l, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: _selectedLanguage == l.toLowerCase() ? Colors.white : C.textSub)),
                    ),
                  )),
                ]),
              ),
            ]),
          ),
        ),
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: C.error, size: 40),
                  const SizedBox(height: 12),
                  Text(state.error!, style: const TextStyle(color: C.textSub, fontFamily: 'Inter')),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => ref.read(snippetProvider.notifier).fetch(), child: const Text('Retry')),
                ]))
              : state.snippets.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: () => ref.read(snippetProvider.notifier).fetch(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: state.snippets.length,
                        itemBuilder: (_, i) => _SnippetCard(
                          snippet: state.snippets[i],
                          langColor: _langColor(state.snippets[i].language),
                          onFavorite: () => ref.read(snippetProvider.notifier).toggleFavorite(state.snippets[i]),
                          onDelete: () => ref.read(snippetProvider.notifier).delete(state.snippets[i].id),
                        ),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSnippet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Snippet', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        backgroundColor: C.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80, decoration: BoxDecoration(color: C.primary.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.code_rounded, color: C.primary, size: 40)),
    const SizedBox(height: 16),
    const Text('No snippets yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.text, fontFamily: 'Inter')),
    const SizedBox(height: 8),
    const Text('Save your reusable code snippets', style: TextStyle(fontSize: 13, color: C.textSub, fontFamily: 'Inter')),
  ]));
}

class _SnippetCard extends StatelessWidget {
  final CodeSnippet snippet;
  final Color langColor;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  const _SnippetCard({required this.snippet, required this.langColor, required this.onFavorite, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: langColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(snippet.language, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: langColor)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(snippet.title, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: C.text), overflow: TextOverflow.ellipsis)),
            IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: Icon(snippet.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded, color: snippet.isFavorite ? C.warning : C.textMuted, size: 20), onPressed: onFavorite),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.copy_rounded, color: C.primary, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: snippet.code));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied!'), backgroundColor: C.success, duration: Duration(seconds: 1)));
              },
            ),
            const SizedBox(width: 4),
            IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.delete_outline_rounded, color: C.error, size: 18), onPressed: onDelete),
          ]),
        ),
        if (snippet.description?.isNotEmpty == true) Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Text(snippet.description!, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.textSub), maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        // Code block
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF1E1E2E), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14))),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              snippet.code.length > 200 ? '${snippet.code.substring(0, 200)}...' : snippet.code,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFFCDD6F4), height: 1.6),
            ),
          ),
        ),
        if (snippet.tags.isNotEmpty) Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(spacing: 6, children: snippet.tags.map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: C.border)),
            child: Text('#$t', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: C.textSub)),
          )).toList()),
        ),
      ]),
    );
  }
}
