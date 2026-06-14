import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';
import 'package:intl/intl.dart';

final _eventsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final dio = ref.watch(dioProvider);
    final res = await dio.get('/api/v1/calendar');
    return List<Map<String, dynamic>>.from(res.data as List);
  } catch (_) { return []; }
});

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(_eventsProvider);

    return Scaffold(
      backgroundColor: AppStyle.bg(context),
      appBar: AppBar(
        backgroundColor: AppStyle.surface(context),
        elevation: 0,
        title: Text('Calendar', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, color: AppStyle.text(context))),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(color: AppStyle.border(context), height: 1)),
      ),
      body: Column(
        children: [
          _buildCalendarHeader(context),
          _buildCalendarGrid(context),
          const Divider(height: 1),
          Expanded(
            child: eventsAsync.when(
              data: (events) => _buildEventsList(context, events),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildEmpty(context),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEvent(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCalendarHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, color: AppStyle.text(context)),
            onPressed: () => setState(() => _focused = DateTime(_focused.year, _focused.month - 1)),
          ),
          Text(DateFormat('MMMM yyyy').format(_focused), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppStyle.text(context), fontFamily: 'Inter')),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded, color: AppStyle.text(context)),
            onPressed: () => setState(() => _focused = DateTime(_focused.year, _focused.month + 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final firstDay = DateTime(_focused.year, _focused.month, 1);
    final lastDay = DateTime(_focused.year, _focused.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;

    final days = <Widget>[];
    for (final d in ['S', 'M', 'T', 'W', 'T', 'F', 'S']) {
      days.add(Center(child: Text(d, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppStyle.textMuted(context), fontFamily: 'Inter'))));
    }
    for (var i = 0; i < startWeekday; i++) days.add(const SizedBox());
    for (var d = 1; d <= lastDay.day; d++) {
      final date = DateTime(_focused.year, _focused.month, d);
      final isToday = _isSameDay(date, DateTime.now());
      final isSelected = _isSameDay(date, _selected);
      days.add(GestureDetector(
        onTap: () => setState(() => _selected = date),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : isToday ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text('$d', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Inter',
            color: isSelected ? Colors.white : isToday ? AppColors.primary : AppStyle.text(context),
          )),
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1,
        children: days,
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildEventsList(BuildContext context, List<Map<String, dynamic>> events) {
    final dayEvents = events.where((e) {
      try {
        final d = DateTime.parse(e['start_time'] ?? '');
        return _isSameDay(d, _selected);
      } catch (_) { return false; }
    }).toList();

    if (dayEvents.isEmpty) return _buildEmpty(context);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dayEvents.length,
      itemBuilder: (_, i) => _EventTile(event: dayEvents[i]),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_rounded, color: AppStyle.textMuted(context), size: 48),
          const SizedBox(height: 12),
          Text('No events for ${DateFormat('MMMM d').format(_selected)}', style: TextStyle(color: AppStyle.textSub(context), fontFamily: 'Inter')),
        ],
      ),
    );
  }

  void _showAddEvent(BuildContext context) {
    final titleCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppStyle.card(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Event', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppStyle.text(context), fontFamily: 'Inter')),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              style: TextStyle(color: AppStyle.text(ctx), fontFamily: 'Inter'),
              decoration: InputDecoration(labelText: 'Event Title', filled: true, fillColor: AppStyle.surface(ctx), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppStyle.border(ctx))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppStyle.border(ctx)))),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.isEmpty) return;
                  try {
                    final dio = ref.read(dioProvider);
                    await dio.post('/api/v1/calendar', data: {
                      'title': titleCtrl.text,
                      'start_time': _selected.toIso8601String(),
                    });
                    ref.invalidate(_eventsProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (_) {}
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                child: const Text('Add Event', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final Map<String, dynamic> event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(event['color'] as String? ?? '#6366F1');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppStyle.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: AppStyle.cardShadow(context),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event['title'] ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppStyle.text(context), fontFamily: 'Inter')),
                if (event['description'] != null && (event['description'] as String).isNotEmpty)
                  Text(event['description'], style: TextStyle(fontSize: 12, color: AppStyle.textSub(context), fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (event['start_time'] != null)
            Text(_formatTime(event['start_time']), style: TextStyle(fontSize: 12, color: AppStyle.textMuted(context), fontFamily: 'Inter')),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) { return AppColors.primary; }
  }

  String _formatTime(String iso) {
    try { return DateFormat('h:mm a').format(DateTime.parse(iso)); } catch (_) { return ''; }
  }
}
