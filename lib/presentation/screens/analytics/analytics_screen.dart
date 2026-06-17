import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';

final analyticsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/api/v1/dashboard/summary');
  return Map<String, dynamic>.from(r.data);
});

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Analytics')),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, color: C.error, size: 40),
            const SizedBox(height: 12),
            Text(e.toString(), style: const TextStyle(color: C.textSub, fontFamily: 'Inter')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => ref.refresh(analyticsProvider.future), child: const Text('Retry')),
          ]),
        ),
        data: (d) => RefreshIndicator(
          onRefresh: () => ref.refresh(analyticsProvider.future),
          child: _buildBody(d),
        ),
      ),
    );
  }

  Widget _buildBody(Map<String, dynamic> d) {
    final tasks = d['tasks'] as Map<String, dynamic>? ?? {};
    final habits = d['habits'] as Map<String, dynamic>? ?? {};
    final notes = d['notes'] as Map<String, dynamic>? ?? {};
    final projects = d['projects'] as Map<String, dynamic>? ?? {};

    final totalTasks = (tasks['total'] ?? 0) as int;
    final completedTasks = (tasks['completed'] ?? 0) as int;
    final totalHabits = (habits['active'] ?? habits['total_active'] ?? 0) as int;
    final todayHabits = (habits['done_today'] ?? habits['today_completed'] ?? 0) as int;
    final totalNotes = (notes['total'] ?? 0) as int;
    final activeProjects = (projects['active'] ?? 0) as int;
    final totalProjects = activeProjects;
    // Goals and journal not in dashboard summary — show 0 as defaults
    const activeGoals = 0;
    const totalGoals = 0;
    const journalEntries = 0;

    // Productivity score
    final score = completedTasks * 2 + todayHabits * 3 + totalNotes * 1;
    final maxScore = (totalTasks * 2 + totalHabits * 3 + 50).clamp(10, 999);
    final scorePercent = (score / maxScore).clamp(0.0, 1.0);

    final scoreLabel = scorePercent > 0.8
        ? 'Excellent!'
        : scorePercent > 0.6
            ? 'Great progress!'
            : scorePercent > 0.4
                ? 'Doing well'
                : scorePercent > 0.2
                    ? 'Keep going'
                    : 'Just getting started';

    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
      // Productivity Score Card
      Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [C.primary, C.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Productivity Score', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$score', style: const TextStyle(fontFamily: 'Inter', fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(width: 8),
            Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('pts', style: TextStyle(fontFamily: 'Inter', fontSize: 18, color: Colors.white.withOpacity(0.7)))),
            const Spacer(),
            Text(scoreLabel, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: scorePercent, backgroundColor: Colors.white.withOpacity(0.3), valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), minHeight: 8),
          ),
          const SizedBox(height: 8),
          Text('Tasks ×2 + Habits ×3 + Notes ×1', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white.withOpacity(0.6))),
        ]),
      ),

      // Stats Grid
      const Text('OVERVIEW', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: C.textMuted, letterSpacing: 1)),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.6,
        children: [
          _statCard('Tasks Completed', '$completedTasks / $totalTasks', Icons.check_circle_outline_rounded, C.success),
          _statCard('Habits Done Today', '$todayHabits / $totalHabits', Icons.local_fire_department_rounded, const Color(0xFFFF6B35)),
          _statCard('Notes', '$totalNotes', Icons.note_alt_rounded, C.primary),
          _statCard('Active Projects', '$activeProjects / $totalProjects', Icons.folder_open_rounded, const Color(0xFF8B5CF6)),
          _statCard('Goals Active', '$activeGoals / $totalGoals', Icons.flag_rounded, C.warning),
          _statCard('Journal Entries', '$journalEntries', Icons.menu_book_rounded, const Color(0xFF06B6D4)),
        ],
      ),
      const SizedBox(height: 24),

      // Progress Bars
      const Text('PROGRESS OVERVIEW', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: C.textMuted, letterSpacing: 1)),
      const SizedBox(height: 10),
      _progressBar('Task Completion', totalTasks > 0 ? completedTasks / totalTasks : 0, '$completedTasks / $totalTasks', C.success),
      const SizedBox(height: 10),
      _progressBar("Today's Habits", totalHabits > 0 ? todayHabits / totalHabits : 0, '$todayHabits / $totalHabits', const Color(0xFFFF6B35)),
      const SizedBox(height: 10),
      _progressBar('Goals Progress', totalGoals > 0 ? activeGoals / totalGoals : 0, '$activeGoals active of $totalGoals', C.primary),
      const SizedBox(height: 24),

      // Tips
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: C.success.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: C.success.withOpacity(0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('💡', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('Tips to boost productivity', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14, color: C.text)),
          ]),
          const SizedBox(height: 10),
          ...[
            'Complete your 3 most important tasks first',
            'Track habits daily to build strong streaks',
            'Use Focus Timer for deep work sessions',
            'Journal daily to reflect and improve',
          ].map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('• ', style: TextStyle(fontFamily: 'Inter', color: C.success, fontWeight: FontWeight.w700)),
              Expanded(child: Text(tip, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: C.textSub, height: 1.4))),
            ]),
          )),
        ]),
      ),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16)),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: C.textSub)),
        ]),
      ]),
    );
  }

  Widget _progressBar(String label, double value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: C.text))),
          Text('${(value * 100).toInt()}%', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: value.clamp(0.0, 1.0), backgroundColor: C.border, valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 8),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: C.textMuted)),
      ]),
    );
  }
}
