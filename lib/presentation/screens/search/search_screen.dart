import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String _query = '';

  static const _recents = ['Vishal research paper', 'Flutter notes', 'Monthly budget', 'Goals 2026'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() { _ctrl.dispose(); _focus.dispose(); super.dispose(); }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) { setState(() { _results = []; _query = ''; }); return; }
    setState(() { _loading = true; _query = q; });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/api/v1/search', queryParameters: {'q': q});
      setState(() => _results = List<Map<String, dynamic>>.from(res.data as List));
    } catch (_) {
      setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.bg(context),
      appBar: AppBar(
        backgroundColor: AppStyle.surface(context),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_rounded, color: AppStyle.text(context), size: 20), onPressed: () => context.pop()),
        title: TextField(
          controller: _ctrl,
          focusNode: _focus,
          onChanged: (v) { if (v.length > 2) _search(v); else if (v.isEmpty) setState(() { _results = []; _query = ''; }); },
          onSubmitted: _search,
          style: TextStyle(color: AppStyle.text(context), fontFamily: 'Inter', fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search everything...',
            hintStyle: TextStyle(color: AppStyle.textMuted(context), fontFamily: 'Inter'),
            border: InputBorder.none, filled: false,
          ),
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(icon: Icon(Icons.clear, color: AppStyle.textMuted(context)), onPressed: () { _ctrl.clear(); setState(() { _results = []; _query = ''; }); }),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(color: AppStyle.border(context), height: 1)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _query.isEmpty
              ? _buildSuggestions(context)
              : _results.isEmpty
                  ? _buildNoResults(context)
                  : _buildResults(context),
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Searches', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppStyle.textMuted(context), fontFamily: 'Inter', letterSpacing: 0.5)),
          const SizedBox(height: 12),
          ..._recents.map((r) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.history_rounded, color: AppStyle.textMuted(context), size: 20),
            title: Text(r, style: TextStyle(color: AppStyle.text(context), fontFamily: 'Inter', fontSize: 14)),
            trailing: Icon(Icons.north_west_rounded, color: AppStyle.textMuted(context), size: 16),
            onTap: () { _ctrl.text = r; _search(r); },
          )),
          const SizedBox(height: 24),
          Text('Search Across', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppStyle.textMuted(context), fontFamily: 'Inter', letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ['Notes', 'Tasks', 'Goals', 'Finance', 'Journal', 'Contacts', 'Learning'].map((t) => GestureDetector(
              onTap: () { _ctrl.text = t.toLowerCase(); _search(t.toLowerCase()); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: AppStyle.card(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppStyle.border(context))),
                child: Text(t, style: TextStyle(fontSize: 13, color: AppStyle.textSub(context), fontFamily: 'Inter')),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final r in _results) {
      final type = r['type'] as String? ?? 'other';
      grouped.putIfAbsent(type, () => []).add(r);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${_results.length} result${_results.length == 1 ? '' : 's'} for "$_query"',
          style: TextStyle(fontSize: 13, color: AppStyle.textSub(context), fontFamily: 'Inter')),
        const SizedBox(height: 16),
        ...grouped.entries.expand((e) => [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(e.key.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppStyle.textMuted(context), fontFamily: 'Inter', letterSpacing: 0.8)),
          ),
          ...e.value.map((r) => _ResultTile(result: r)),
        ]),
      ],
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, color: AppStyle.textMuted(context), size: 56),
          const SizedBox(height: 16),
          Text('No results for "$_query"', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppStyle.text(context), fontFamily: 'Inter')),
          const SizedBox(height: 8),
          Text('Try different keywords', style: TextStyle(color: AppStyle.textSub(context), fontFamily: 'Inter')),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultTile({required this.result});

  static const _typeIcons = {
    'note': Icons.sticky_note_2_rounded,
    'task': Icons.task_alt_rounded,
    'journal': Icons.book_rounded,
    'goal': Icons.flag_rounded,
    'contact': Icons.person_rounded,
    'finance': Icons.account_balance_wallet_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final type = result['type'] as String? ?? 'note';
    final icon = _typeIcons[type] ?? Icons.search_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: AppStyle.cardDecor(context, radius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppColors.primary, size: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result['title'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppStyle.text(context), fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (result['preview'] != null)
                  Text(result['preview'], style: TextStyle(fontSize: 12, color: AppStyle.textSub(context), fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppStyle.textMuted(context), size: 18),
        ],
      ),
    );
  }
}
