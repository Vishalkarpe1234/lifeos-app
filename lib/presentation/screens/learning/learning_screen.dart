import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';

final _learningProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final dio = ref.watch(dioProvider);
    final res = await dio.get('/api/v1/learning');
    return List<Map<String, dynamic>>.from(res.data as List);
  } catch (_) { return []; }
});

class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({super.key});

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  final _types = ['All', 'Books', 'Courses', 'Articles'];

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final learningAsync = ref.watch(_learningProvider);
    return Scaffold(
      backgroundColor: AppStyle.bg(context),
      appBar: AppBar(
        backgroundColor: AppStyle.surface(context),
        elevation: 0,
        title: Text('Learning Hub', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, color: AppStyle.text(context))),
        bottom: TabBar(
          controller: _tabs,
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: AppStyle.textMuted(context),
          indicatorColor: const Color(0xFF3B82F6),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _types.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: learningAsync.when(
        data: (items) => _buildList(context, items),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildEmpty(context),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdd(context),
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Resource', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Map<String, dynamic>> items) {
    if (items.isEmpty) return _buildEmpty(context);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => _LearningCard(item: items[i])
          .animate(delay: (40 * i).ms).fadeIn().slideX(begin: 0.03, end: 0),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.10), borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.school_rounded, color: Color(0xFF3B82F6), size: 40),
          ),
          const SizedBox(height: 16),
          Text('Nothing here yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppStyle.text(context), fontFamily: 'Inter')),
          const SizedBox(height: 8),
          Text('Track your books, courses & articles', style: TextStyle(color: AppStyle.textSub(context), fontFamily: 'Inter')),
        ],
      ),
    );
  }

  void _showAdd(BuildContext context) {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String type = 'book';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppStyle.card(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Resource', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppStyle.text(context), fontFamily: 'Inter')),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              style: TextStyle(color: AppStyle.text(ctx), fontFamily: 'Inter'),
              decoration: InputDecoration(labelText: 'Title', filled: true, fillColor: AppStyle.surface(ctx), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppStyle.border(ctx))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppStyle.border(ctx)))),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              style: TextStyle(color: AppStyle.text(ctx), fontFamily: 'Inter'),
              decoration: InputDecoration(labelText: 'URL (optional)', filled: true, fillColor: AppStyle.surface(ctx), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppStyle.border(ctx))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppStyle.border(ctx)))),
            ),
            const SizedBox(height: 12),
            Row(
              children: ['book', 'course', 'article', 'video'].map((t) => GestureDetector(
                onTap: () => ss(() => type = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: type == t ? const Color(0xFF3B82F6) : AppStyle.surface(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: type == t ? const Color(0xFF3B82F6) : AppStyle.border(context)),
                  ),
                  child: Text(t, style: TextStyle(color: type == t ? Colors.white : AppStyle.textSub(context), fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.isEmpty) return;
                  try {
                    final dio = ref.read(dioProvider);
                    await dio.post('/api/v1/learning', data: {'title': titleCtrl.text, 'resource_type': type, if (urlCtrl.text.isNotEmpty) 'url': urlCtrl.text});
                    ref.invalidate(_learningProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (_) {}
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                child: const Text('Add Resource', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      )),
    );
  }
}

class _LearningCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _LearningCard({required this.item});

  static const _typeColors = {
    'book': Color(0xFF8B5CF6),
    'course': Color(0xFF3B82F6),
    'article': Color(0xFF10B981),
    'video': Color(0xFFEF4444),
  };
  static const _typeIcons = {
    'book': Icons.menu_book_rounded,
    'course': Icons.play_lesson_rounded,
    'article': Icons.article_rounded,
    'video': Icons.play_circle_filled_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final type = item['resource_type'] as String? ?? 'book';
    final color = _typeColors[type] ?? AppColors.primary;
    final icon = _typeIcons[type] ?? Icons.book_rounded;
    final status = item['status'] as String? ?? 'wishlist';
    final progress = (item['progress'] as num? ?? 0).toDouble() / 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppStyle.cardDecor(context),
      child: Row(
        children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(item['title'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppStyle.text(context), fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
                      child: Text(status.replaceAll('_', ' '), style: TextStyle(fontSize: 9, color: _statusColor(status), fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(type, style: TextStyle(fontSize: 11, color: color, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                if (status == 'in_progress') ...[
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: progress, backgroundColor: color.withOpacity(0.12), valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 4)),
                  const SizedBox(height: 2),
                  Text('${(progress * 100).toInt()}% complete', style: TextStyle(fontSize: 10, color: AppStyle.textMuted(context), fontFamily: 'Inter')),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) => s == 'completed' ? AppColors.success : s == 'in_progress' ? AppColors.primary : AppColors.textMuted;
}
