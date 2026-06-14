import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/widgets/animations/shimmer_loading.dart';
import 'package:lifeos/services/api/api_client.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(_todayHabitsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Habits', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddHabit(context, ref))],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(todayAsync),
          const Padding(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 12),
            child: Text("Today's Habits", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
          ),
          Expanded(child: todayAsync.when(
            data: (data) {
              final habits = data['habits'] as List? ?? [];
              if (habits.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.loop, color: AppColors.textMuted, size: 60),
                  const SizedBox(height: 16),
                  Text('No habits yet', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter')),
                ]));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: habits.length,
                itemBuilder: (_, i) {
                  final item = habits[i] as Map<String, dynamic>;
                  final habit = item['habit'] as Map<String, dynamic>;
                  final completed = item['completed'] as bool? ?? false;
                  return _HabitTile(habit: habit, completed: completed, onToggle: () async {
                    final dio = ref.read(dioProvider);
                    await dio.post('/api/v1/habits/logs', data: {'habit_id': habit['id'], 'date': DateTime.now().toIso8601String().split('T')[0]});
                    ref.invalidate(_todayHabitsProvider);
                  }).animate(delay: (40 * i).ms).fadeIn().slideX(begin: 0.05);
                },
              );
            },
            loading: () => const ShimmerLoading(count: 6, height: 70),
            error: (e, _) => Center(child: Text(e.toString(), style: TextStyle(color: AppColors.error))),
          )),
        ],
      ),
    );
  }

  Widget _buildHeader(AsyncValue todayAsync) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: todayAsync.when(
        data: (data) {
          final habits = data['habits'] as List? ?? [];
          final done = habits.where((h) => (h as Map)['completed'] == true).length;
          final total = habits.length;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16)]),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$done / $total', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Inter', letterSpacing: -1)),
                Text('Habits completed today', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontFamily: 'Inter')),
              ]),
              const Spacer(),
              SizedBox(width: 60, height: 60, child: CircularProgressIndicator(
                value: total > 0 ? done / total : 0,
                backgroundColor: Colors.white.withOpacity(0.2),
                color: Colors.white,
                strokeWidth: 6,
              )),
            ]),
          );
        },
        loading: () => const SizedBox(height: 90),
        error: (_, __) => const SizedBox(),
      ),
    );
  }

  void _showAddHabit(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('New Habit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, autofocus: true, style: const TextStyle(color: Colors.white, fontFamily: 'Inter'), decoration: const InputDecoration(labelText: 'Habit name')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final dio = ref.read(dioProvider);
              await dio.post('/api/v1/habits/', data: {'name': nameCtrl.text, 'frequency': 'daily'});
              ref.invalidate(_todayHabitsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add Habit', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  final Map<String, dynamic> habit;
  final bool completed;
  final VoidCallback onToggle;
  const _HabitTile({required this.habit, required this.completed, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: completed ? AppColors.primary.withOpacity(0.1) : AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: completed ? AppColors.primary.withOpacity(0.3) : AppColors.darkBorder, width: completed ? 1 : 0.5),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28, height: 28,
            decoration: BoxDecoration(shape: BoxShape.circle, color: completed ? AppColors.primary : Colors.transparent, border: Border.all(color: completed ? AppColors.primary : AppColors.darkBorder, width: 2)),
            child: completed ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(habit['name'] ?? '', style: TextStyle(color: completed ? AppColors.textSecondary : Colors.white, fontSize: 15, fontWeight: FontWeight.w500, fontFamily: 'Inter', decoration: completed ? TextDecoration.lineThrough : null)),
          if (habit['streak_current'] != null && (habit['streak_current'] as int) > 0)
            Row(children: [
              Icon(Icons.local_fire_department, color: AppColors.warning, size: 14),
              const SizedBox(width: 2),
              Text('${habit['streak_current']} day streak', style: TextStyle(color: AppColors.warning, fontSize: 11, fontFamily: 'Inter')),
            ]),
        ])),
        if (habit['target_count'] != null && habit['target_count'] > 1)
          Text('${habit['target_count']}x', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'Inter')),
      ]),
    );
  }
}

final _todayHabitsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/api/v1/habits/today');
  return Map<String, dynamic>.from(r.data as Map);
});
