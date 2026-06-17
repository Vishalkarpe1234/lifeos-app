import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';

final dashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/api/v1/dashboard/summary');
  return Map<String, dynamic>.from(r.data);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardProvider);
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: C.bg,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 8),
          const Text('VK OS'),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, color: C.error, size: 48),
              const SizedBox(height: 12),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: C.textSub, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(dashboardProvider.future),
                child: const Text('Retry'),
              ),
            ]),
          ),
          data: (d) => _buildBody(context, d),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> d) {
    final tasks = d['tasks'] as Map<String, dynamic>? ?? {};
    final habits = d['habits'] as Map<String, dynamic>? ?? {};
    final notes = d['notes'] as Map<String, dynamic>? ?? {};
    final projects = d['projects'] as Map<String, dynamic>? ?? {};

    final totalTasks = tasks['total'] ?? 0;
    final completedTasks = tasks['completed'] ?? 0;
    final todayHabits = habits['done_today'] ?? habits['today_completed'] ?? 0;
    final totalHabits = habits['active'] ?? habits['total_active'] ?? 0;
    final totalNotes = notes['total'] ?? 0;
    final activeProjects = projects['active'] ?? 0;
    final activeGoals = 0; // Not in dashboard summary

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // Greeting
        Container(
          margin: const EdgeInsets.only(bottom: 20, top: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [C.primary, C.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '${_greeting()}, VK',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _dateString(),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              _miniStat('$completedTasks/$totalTasks', 'Tasks'),
              const SizedBox(width: 20),
              _miniStat('$todayHabits/$totalHabits', 'Habits'),
              const SizedBox(width: 20),
              _miniStat('$activeGoals', 'Goals'),
            ]),
          ]),
        ),

        // Quick Actions
        const Text(
          'QUICK ACTIONS',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: C.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _quickAction(context, Icons.add_task_rounded, 'Add Task', '/tasks', C.primary)),
          const SizedBox(width: 10),
          Expanded(child: _quickAction(context, Icons.edit_note_rounded, 'New Note', '/notes/new', C.success)),
          const SizedBox(width: 10),
          Expanded(child: _quickAction(context, Icons.timer_rounded, 'Focus', '/focus', const Color(0xFF8B5CF6))),
        ]),
        const SizedBox(height: 24),

        // Stats Grid
        const Text(
          'OVERVIEW',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: C.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _statCard('Tasks Done', '$completedTasks / $totalTasks', Icons.check_circle_outline_rounded, C.success, '/tasks'),
            _statCard('Habits Today', '$todayHabits / $totalHabits', Icons.local_fire_department_rounded, const Color(0xFFFF6B35), '/habits'),
            _statCard('Notes', '$totalNotes', Icons.note_alt_rounded, C.primary, '/notes'),
            _statCard('Projects', '$activeProjects active', Icons.folder_open_rounded, const Color(0xFF8B5CF6), '/projects'),
          ],
        ),

        const SizedBox(height: 24),
        const Text(
          'NAVIGATE',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: C.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        _navRow(context, [
          _NavItem(Icons.flag_rounded, 'Goals', '/goals', C.primary),
          _NavItem(Icons.bar_chart_rounded, 'Analytics', '/analytics', const Color(0xFF06B6D4)),
          _NavItem(Icons.code_rounded, 'Snippets', '/snippets', const Color(0xFFF59E0B)),
          _NavItem(Icons.people_outline_rounded, 'Connect', '/connect', C.primaryDark),
        ]),
      ],
    );
  }

  Widget _miniStat(String value, String label) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        value,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    ]);
  }

  Widget _quickAction(
    BuildContext context,
    IconData icon,
    String label,
    String route,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
    String route,
  ) {
    return Builder(builder: (context) {
      return GestureDetector(
        onTap: () => context.go(route),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: C.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: C.textSub,
                  ),
                ),
              ]),
            ],
          ),
        ),
      );
    });
  }

  Widget _navRow(BuildContext context, List<_NavItem> items) {
    return Row(
      children: items
          .map((item) => Expanded(
                child: GestureDetector(
                  onTap: () => context.go(item.route),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: C.border),
                    ),
                    child: Column(children: [
                      Icon(item.icon, color: item.color, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: C.textSub,
                        ),
                      ),
                    ]),
                  ),
                ),
              ))
          .toList(),
    );
  }

  String _dateString() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const _NavItem(this.icon, this.label, this.route, this.color);
}
