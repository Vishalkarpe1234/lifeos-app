import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/habit_provider.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});
  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(habitProvider.notifier).fetch();
    });
  }

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return C.primary;
    }
  }

  void _showAddHabit() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String icon = '';
    String color = '#6366F1';
    String frequency = 'daily';
    bool saving = false;

    final colors = [
      '#6366F1', '#10B981', '#F59E0B', '#EF4444',
      '#8B5CF6', '#06B6D4', '#EC4899', '#3F51B5',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Add Habit', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, fontSize: 18, color: C.text)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Habit name *'),
              style: const TextStyle(fontFamily: 'Inter'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              style: const TextStyle(fontFamily: 'Inter'),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Emoji Icon', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.textSub)),
                const SizedBox(height: 4),
                TextField(
                  decoration: const InputDecoration(hintText: 'e.g. 💪', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  style: const TextStyle(fontSize: 22),
                  onChanged: (v) => icon = v,
                ),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Frequency', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.textSub)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily', style: TextStyle(fontFamily: 'Inter'))),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly', style: TextStyle(fontFamily: 'Inter'))),
                  ],
                  onChanged: (v) => setS(() => frequency = v ?? 'daily'),
                ),
              ])),
            ]),
            const SizedBox(height: 12),
            const Text('Color', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: C.textSub)),
            const SizedBox(height: 8),
            Row(children: colors.map((c) => GestureDetector(
              onTap: () => setS(() => color = c),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: _parseColor(c),
                  shape: BoxShape.circle,
                  border: color == c ? Border.all(color: C.text, width: 2) : null,
                ),
                child: color == c ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
              ),
            )).toList()),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saving ? null : () async {
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Name is required'), backgroundColor: C.error));
                    return;
                  }
                  setS(() => saving = true);
                  final ok = await ref.read(habitProvider.notifier).create(
                    nameCtrl.text.trim(),
                    icon: icon.isEmpty ? null : icon,
                    color: color,
                    frequency: frequency,
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok ? 'Habit created!' : 'Failed to create habit'),
                      backgroundColor: ok ? C.success : C.error,
                    ));
                  }
                },
                child: saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Add Habit', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
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
    final state = ref.watch(habitProvider);
    final todayHabits = state.todayHabits;
    final done = todayHabits.where((h) => h.completed).length;
    final total = todayHabits.length;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Habits')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: C.error, size: 40),
                  const SizedBox(height: 12),
                  Text(state.error!, textAlign: TextAlign.center, style: const TextStyle(color: C.textSub, fontFamily: 'Inter')),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => ref.read(habitProvider.notifier).fetch(), child: const Text('Retry')),
                ]))
              : todayHabits.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: () => ref.read(habitProvider.notifier).fetch(),
                      child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
                        // Progress header
                        Container(
                          padding: const EdgeInsets.all(18),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [C.primary, C.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Today\'s Progress', style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
                                const SizedBox(height: 4),
                                Text('$done / $total habits done', style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                              ])),
                              Container(
                                width: 56, height: 56,
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                child: Center(child: Text(
                                  total > 0 ? '${(done * 100 ~/ total)}%' : '0%',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                                )),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: total > 0 ? done / total : 0,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                minHeight: 8,
                              ),
                            ),
                          ]),
                        ),

                        // Habit list
                        const Text('TODAY\'S HABITS', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: C.textMuted, letterSpacing: 1)),
                        const SizedBox(height: 10),
                        ...todayHabits.map((th) => _HabitCard(
                          todayHabit: th,
                          onLog: () async {
                            if (!th.completed) {
                              await ref.read(habitProvider.notifier).logHabit(th.habit.id);
                            }
                          },
                          onDelete: () => ref.read(habitProvider.notifier).delete(th.habit.id),
                          parseColor: _parseColor,
                        )),
                      ]),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddHabit,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Habit', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        backgroundColor: C.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80, decoration: BoxDecoration(color: C.primary.withOpacity(0.1), shape: BoxShape.circle),
      child: const Icon(Icons.local_fire_department_rounded, color: C.primary, size: 40)),
    const SizedBox(height: 16),
    const Text('No habits yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.text, fontFamily: 'Inter')),
    const SizedBox(height: 8),
    const Text('Build streaks by adding your first habit', style: TextStyle(fontSize: 13, color: C.textSub, fontFamily: 'Inter')),
    const SizedBox(height: 24),
    ElevatedButton.icon(
      onPressed: _showAddHabit,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Habit', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
    ),
  ]));
}

class _HabitCard extends StatelessWidget {
  final TodayHabit todayHabit;
  final VoidCallback onLog;
  final VoidCallback onDelete;
  final Color Function(String) parseColor;

  const _HabitCard({
    required this.todayHabit,
    required this.onLog,
    required this.onDelete,
    required this.parseColor,
  });

  @override
  Widget build(BuildContext context) {
    final h = todayHabit.habit;
    final color = parseColor(h.color);
    final done = todayHabit.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: done ? color.withOpacity(0.3) : C.border),
      ),
      child: Row(children: [
        // Icon/color circle
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Center(child: h.icon != null && h.icon!.isNotEmpty
              ? Text(h.icon!, style: const TextStyle(fontSize: 22))
              : Icon(Icons.star_rounded, color: color, size: 22)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(h.name, style: TextStyle(
            fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700,
            color: done ? C.textMuted : C.text,
            decoration: done ? TextDecoration.lineThrough : null,
          )),
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.local_fire_department_rounded, size: 12, color: Color(0xFFFF6B35)),
            const SizedBox(width: 3),
            Text('${h.streakCurrent} day streak', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: C.textSub)),
            if (h.streakLongest > 0) ...[
              const Text(' • ', style: TextStyle(color: C.textMuted, fontSize: 11)),
              Text('Best: ${h.streakLongest}', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: C.textMuted)),
            ],
          ]),
        ])),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: done ? null : onLog,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: done ? color : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: done ? color : C.border, width: 2),
            ),
            child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
          ),
        ),
      ]),
    );
  }
}
