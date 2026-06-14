import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';
import 'package:intl/intl.dart';

final _timelineProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final dio = ref.watch(dioProvider);
    final res = await dio.get('/api/v1/timeline');
    return List<Map<String, dynamic>>.from(res.data as List);
  } catch (_) { return []; }
});

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(_timelineProvider);
    return Scaffold(
      backgroundColor: AppStyle.bg(context),
      appBar: AppBar(
        backgroundColor: AppStyle.surface(context),
        elevation: 0,
        title: Text('Timeline', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, color: AppStyle.text(context))),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: AppStyle.textSub(context)),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(color: AppStyle.border(context), height: 1)),
      ),
      body: timelineAsync.when(
        data: (items) => items.isEmpty ? _buildEmpty(context) : _buildTimeline(context, items),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildEmpty(context),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, List<Map<String, dynamic>> items) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final showDate = i == 0 || !_sameDay(items[i - 1], item);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDate) ...[
              if (i > 0) const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 52, bottom: 8),
                child: Text(_formatDate(item['entry_date'] ?? ''), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppStyle.textMuted(context), fontFamily: 'Inter', letterSpacing: 0.5)),
              ),
            ],
            _TimelineTile(item: item, isLast: i == items.length - 1),
          ],
        );
      },
    );
  }

  bool _sameDay(Map a, Map b) {
    try {
      final da = DateTime.parse(a['entry_date'] ?? '');
      final db = DateTime.parse(b['entry_date'] ?? '');
      return da.year == db.year && da.month == db.month && da.day == db.day;
    } catch (_) { return false; }
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      final now = DateTime.now();
      if (d.year == now.year && d.month == now.month && d.day == now.day) return 'TODAY';
      if (d.year == now.year && d.month == now.month && d.day == now.day - 1) return 'YESTERDAY';
      return DateFormat('MMMM d, y').format(d).toUpperCase();
    } catch (_) { return iso.toUpperCase(); }
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.timeline_rounded, color: AppColors.primary, size: 40)),
          const SizedBox(height: 16),
          Text('No Timeline Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppStyle.text(context), fontFamily: 'Inter')),
          const SizedBox(height: 8),
          Text('Your life activities will appear here', style: TextStyle(color: AppStyle.textSub(context), fontFamily: 'Inter')),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isLast;
  const _TimelineTile({required this.item, required this.isLast});

  static const _typeConfig = {
    'note': (Icons.sticky_note_2_rounded, Color(0xFF6366F1)),
    'task': (Icons.task_alt_rounded, Color(0xFF10B981)),
    'journal': (Icons.book_rounded, Color(0xFF06B6D4)),
    'habit': (Icons.loop_rounded, Color(0xFF8B5CF6)),
    'expense': (Icons.account_balance_wallet_rounded, Color(0xFFF59E0B)),
    'goal': (Icons.flag_rounded, Color(0xFF10B981)),
    'health': (Icons.favorite_rounded, Color(0xFFEF4444)),
  };

  @override
  Widget build(BuildContext context) {
    final type = item['entry_type'] as String? ?? 'note';
    final cfg = _typeConfig[type] ?? (Icons.circle_rounded, AppColors.primary);
    final icon = cfg.$1;
    final color = cfg.$2;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
                if (!isLast) Expanded(child: Center(child: Container(width: 1.5, color: AppStyle.border(context)))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppStyle.card(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppStyle.border(context), width: 0.5),
                  boxShadow: AppStyle.cardShadow(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(5)),
                          child: Text(type.toUpperCase(), style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                        ),
                        const Spacer(),
                        Text(_formatTime(item['entry_date'] ?? ''), style: TextStyle(fontSize: 10, color: AppStyle.textMuted(context), fontFamily: 'Inter')),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(item['title'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppStyle.text(context), fontFamily: 'Inter')),
                    if (item['description'] != null && (item['description'] as String).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(item['description'], style: TextStyle(fontSize: 12, color: AppStyle.textSub(context), fontFamily: 'Inter'), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    try { return DateFormat('h:mm a').format(DateTime.parse(iso)); } catch (_) { return ''; }
  }
}
