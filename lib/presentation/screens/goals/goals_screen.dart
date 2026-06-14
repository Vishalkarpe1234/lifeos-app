import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';

final _goalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final dio = ref.watch(dioProvider);
    final res = await dio.get('/api/v1/goals');
    return List<Map<String, dynamic>>.from(res.data as List);
  } catch (_) { return []; }
});

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  final _tabs2 = ['All', 'Active', 'Completed', 'Paused'];

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(_goalsProvider);
    return Scaffold(
      backgroundColor: AppStyle.bg(context),
      appBar: AppBar(
        backgroundColor: AppStyle.surface(context),
        elevation: 0,
        title: Text('Goals', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, color: AppStyle.text(context))),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppStyle.textMuted(context),
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _tabs2.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: goalsAsync.when(
        data: (goals) => _buildGoalsList(context, goals),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildEmpty(context),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoal(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Goal', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildGoalsList(BuildContext context, List<Map<String, dynamic>> goals) {
    if (goals.isEmpty) return _buildEmpty(context);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: goals.length,
      itemBuilder: (_, i) => _GoalCard(goal: goals[i])
          .animate(delay: (50 * i).ms).fadeIn().slideY(begin: 0.05, end: 0),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.flag_rounded, color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 16),
          Text('No Goals Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppStyle.text(context), fontFamily: 'Inter')),
          const SizedBox(height: 8),
          Text('Set your first goal and start achieving!', style: TextStyle(color: AppStyle.textSub(context), fontFamily: 'Inter')),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddGoal(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            icon: const Icon(Icons.add),
            label: const Text('Add Goal', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showAddGoal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'personal';
    DateTime? targetDate;

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
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppStyle.border(context), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('New Goal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppStyle.text(context), fontFamily: 'Inter')),
            const SizedBox(height: 20),
            TextField(
              controller: titleCtrl,
              style: TextStyle(color: AppStyle.text(ctx), fontFamily: 'Inter'),
              decoration: InputDecoration(labelText: 'Goal Title', filled: true, fillColor: AppStyle.surface(ctx), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppStyle.border(ctx))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppStyle.border(ctx)))),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              style: TextStyle(color: AppStyle.text(ctx), fontFamily: 'Inter'),
              decoration: InputDecoration(labelText: 'Description (optional)', filled: true, fillColor: AppStyle.surface(ctx), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppStyle.border(ctx))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppStyle.border(ctx)))),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) return;
                  try {
                    final dio = ref.read(dioProvider);
                    await dio.post('/api/v1/goals', data: {'title': titleCtrl.text.trim(), 'description': descCtrl.text.trim(), 'category': category});
                    ref.invalidate(_goalsProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (_) {}
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                child: const Text('Create Goal', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      )),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Map<String, dynamic> goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final progress = (goal['progress'] as num? ?? 0).toDouble() / 100;
    final status = goal['status'] ?? 'active';
    final statusColor = status == 'completed' ? AppColors.success : status == 'paused' ? AppColors.textMuted : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: AppStyle.cardDecor(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor, fontFamily: 'Inter', letterSpacing: 0.5)),
              ),
              const Spacer(),
              Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppStyle.text(context), fontFamily: 'Inter')),
            ],
          ),
          const SizedBox(height: 10),
          Text(goal['title'] ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppStyle.text(context), fontFamily: 'Inter')),
          if (goal['description'] != null && (goal['description'] as String).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(goal['description'], style: TextStyle(fontSize: 13, color: AppStyle.textSub(context), fontFamily: 'Inter'), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppStyle.border(context),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
          if (goal['target_date'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 12, color: AppStyle.textMuted(context)),
                const SizedBox(width: 4),
                Text('Target: ${goal['target_date']}', style: TextStyle(fontSize: 11, color: AppStyle.textMuted(context), fontFamily: 'Inter')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
