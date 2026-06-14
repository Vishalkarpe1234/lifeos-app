import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';
import 'package:lifeos/presentation/providers/dashboard_provider.dart';
import 'package:lifeos/presentation/providers/profile_provider.dart';
import 'package:lifeos/presentation/widgets/cards/stat_card.dart';
import 'package:lifeos/presentation/widgets/cards/quick_action_card.dart';
import 'package:lifeos/presentation/widgets/common/glass_card.dart';
import 'package:lifeos/presentation/widgets/animations/shimmer_loading.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardSummaryProvider);
    final profileAsync = ref.watch(profileProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppStyle.bg(context),
      body: Stack(
        children: [
          _buildBackground(),
          CustomScrollView(
            slivers: [
              _buildAppBar(context, profileAsync, now),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    dashAsync.when(
                      data: (data) => _buildContent(context, data),
                      loading: () => const ShimmerLoading(count: 6),
                      error: (e, _) => _buildError(context, e.toString()),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.primary.withOpacity(0.15), Colors.transparent]),
            ),
          ),
        ),
        Positioned(
          bottom: 200,
          left: -100,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.accent.withOpacity(0.1), Colors.transparent]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, AsyncValue profileAsync, DateTime now) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 20, right: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36, height: 36,
                margin: const EdgeInsets.only(right: 12, top: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 8)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(now.hour),
                      style: TextStyle(fontSize: 13, color: AppStyle.textMuted(context), fontFamily: 'Inter'),
                    ),
                    const SizedBox(height: 4),
                    profileAsync.when(
                      data: (p) => Text(
                        p?.fullName ?? 'Welcome',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppStyle.text(context), fontFamily: 'Inter', letterSpacing: -0.5),
                      ),
                      loading: () => Text('Loading...', style: TextStyle(fontSize: 24, color: AppStyle.text(context), fontFamily: 'Inter')),
                      error: (_, __) => Text('VK OS', style: TextStyle(fontSize: 24, color: AppStyle.text(context), fontFamily: 'Inter')),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d').format(now),
                      style: TextStyle(fontSize: 13, color: AppStyle.textSub(context), fontFamily: 'Inter'),
                    ),
                  ],
                ),
              ),
              _buildProfileAvatar(context, profileAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, AsyncValue profileAsync) {
    void showMenu() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _ProfileSheet(parentContext: context),
      );
    }

    return profileAsync.when(
      data: (p) => GestureDetector(
        onTap: showMenu,
        child: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12)],
          ),
          child: p?.profilePhotoUrl != null
              ? ClipOval(child: Image.network(p!.profilePhotoUrl!, fit: BoxFit.cover))
              : const Icon(Icons.person, color: Colors.white, size: 24),
        ),
      ),
      loading: () => CircleAvatar(radius: 24, backgroundColor: AppStyle.card(context)),
      error: (_, __) => GestureDetector(
        onTap: showMenu,
        child: CircleAvatar(radius: 24, backgroundColor: AppStyle.card(context), child: const Icon(Icons.person, color: Colors.white)),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductivityScore(context, data['productivity_score'] ?? 0),
        const SizedBox(height: 20),
        _buildQuickActions(context),
        const SizedBox(height: 20),
        _buildStatsGrid(context, data),
        const SizedBox(height: 20),
        _buildRecentTasks(context, data['recent_tasks'] as List? ?? []),
        const SizedBox(height: 20),
        _buildRecentNotes(context, data['recent_notes'] as List? ?? []),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildProductivityScore(BuildContext context, int score) {
    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Productivity Score', style: TextStyle(fontSize: 13, color: AppStyle.textSub(context), fontFamily: 'Inter')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('$score%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppStyle.text(context), fontFamily: 'Inter')),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Today', style: TextStyle(fontSize: 11, color: AppColors.success, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: AppStyle.border(context),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      score >= 70 ? AppColors.success : score >= 40 ? AppColors.warning : AppColors.error,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15)],
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QA(icon: Icons.add_task, label: 'Add Task', color: AppColors.primary, path: '/tasks'),
      _QA(icon: Icons.note_add_outlined, label: 'New Note', color: AppColors.accent, path: '/notes/new'),
      _QA(icon: Icons.auto_awesome_outlined, label: 'Ask AI', color: const Color(0xFF8B5CF6), path: '/ai'),
      _QA(icon: Icons.flag_outlined, label: 'Goals', color: AppColors.success, path: '/goals'),
      _QA(icon: Icons.calendar_today_outlined, label: 'Calendar', color: AppColors.warning, path: '/calendar'),
      _QA(icon: Icons.search_rounded, label: 'Search', color: AppColors.textMuted, path: '/search'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppStyle.text(context), fontFamily: 'Inter')),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.3,
          ),
          itemCount: actions.length,
          itemBuilder: (_, i) => QuickActionCard(
            icon: actions[i].icon,
            label: actions[i].label,
            color: actions[i].color,
            onTap: () => context.go(actions[i].path),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> data) {
    final tasks = data['tasks'] as Map<String, dynamic>? ?? {};
    final habits = data['habits'] as Map<String, dynamic>? ?? {};
    final finance = data['finance'] as Map<String, dynamic>? ?? {};
    final research = data['research'] as Map<String, dynamic>? ?? {};

    final stats = [
      _Stat(label: 'Tasks Today', value: '${tasks['today'] ?? 0}', sub: '${tasks['completed_today'] ?? 0} done', color: AppColors.primary, icon: Icons.task_alt),
      _Stat(label: 'Habits', value: '${habits['done_today'] ?? 0}/${habits['active'] ?? 0}', sub: 'completed today', color: AppColors.success, icon: Icons.loop),
      _Stat(label: 'Monthly Spend', value: '₹${(finance['monthly_expense'] ?? 0).toStringAsFixed(0)}', sub: 'this month', color: AppColors.warning, icon: Icons.account_balance_wallet),
      _Stat(label: 'Publications', value: '${research['publications'] ?? 0}', sub: 'total', color: AppColors.accent, icon: Icons.article_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppStyle.text(context), fontFamily: 'Inter')),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.4,
          ),
          itemCount: stats.length,
          itemBuilder: (_, i) => StatCard(
            label: stats[i].label,
            value: stats[i].value,
            subtitle: stats[i].sub,
            accentColor: stats[i].color,
            icon: stats[i].icon,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTasks(BuildContext context, List tasks) {
    if (tasks.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pending Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppStyle.text(context), fontFamily: 'Inter')),
            TextButton(
              onPressed: () => context.go('/tasks'),
              child: const Text('View all', style: TextStyle(color: AppColors.primary, fontSize: 13, fontFamily: 'Inter')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...tasks.take(4).map((t) => _buildTaskItem(context, t as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, Map<String, dynamic> task) {
    final priority = task['priority'] ?? 'medium';
    final priorityColor = priority == 'high' ? AppColors.priorityHigh : priority == 'low' ? AppColors.priorityLow : AppColors.priorityMedium;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppStyle.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppStyle.border(context), width: 0.5),
        boxShadow: AppStyle.cardShadow(context),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 24, decoration: BoxDecoration(color: priorityColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Text(task['title'] ?? '', style: TextStyle(color: AppStyle.text(context), fontSize: 14, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (task['due_date'] != null)
            Text(task['due_date'].toString(), style: TextStyle(color: AppStyle.textMuted(context), fontSize: 11, fontFamily: 'Inter')),
        ],
      ),
    );
  }

  Widget _buildRecentNotes(BuildContext context, List notes) {
    if (notes.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppStyle.text(context), fontFamily: 'Inter')),
            TextButton(
              onPressed: () => context.go('/notes'),
              child: const Text('View all', style: TextStyle(color: AppColors.primary, fontSize: 13, fontFamily: 'Inter')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: notes.take(6).length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final note = notes[i] as Map<String, dynamic>;
              return GestureDetector(
                onTap: () => context.go('/notes/${note['id']}'),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppStyle.card(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppStyle.border(context), width: 0.5),
                    boxShadow: AppStyle.cardShadow(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.sticky_note_2_outlined, color: AppColors.primary, size: 18),
                      const SizedBox(height: 6),
                      Text(note['title'] ?? 'Untitled', style: TextStyle(color: AppStyle.text(context), fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Inter'), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.wifi_off, color: AppStyle.textMuted(context), size: 48),
            const SizedBox(height: 16),
            Text('Could not load dashboard', style: TextStyle(color: AppStyle.textSub(context), fontFamily: 'Inter')),
            const SizedBox(height: 8),
            Text(msg, style: TextStyle(color: AppStyle.textMuted(context), fontSize: 12, fontFamily: 'Inter'), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }
}

class _QA {
  final IconData icon;
  final String label;
  final Color color;
  final String path;
  const _QA({required this.icon, required this.label, required this.color, required this.path});
}

class _Stat {
  final String label, value, sub;
  final Color color;
  final IconData icon;
  const _Stat({required this.label, required this.value, required this.sub, required this.color, required this.icon});
}

class _ProfileSheet extends ConsumerWidget {
  final BuildContext parentContext;
  const _ProfileSheet({required this.parentContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyle.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppStyle.border(context), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          _SheetItem(
            icon: Icons.person_outline,
            label: 'View Profile',
            color: AppColors.primary,
            onTap: () {
              Navigator.pop(context);
              parentContext.go('/profile');
            },
          ),
          const SizedBox(height: 8),
          _SheetItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            color: AppColors.accent,
            onTap: () {
              Navigator.pop(context);
              parentContext.go('/settings');
            },
          ),
          const SizedBox(height: 8),
          _SheetItem(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            color: AppColors.error,
            onTap: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: parentContext,
                builder: (_) => AlertDialog(
                  backgroundColor: AppStyle.card(parentContext),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text('Sign Out?', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, color: AppStyle.text(parentContext))),
                  content: Text('You will be returned to the login screen.', style: TextStyle(fontFamily: 'Inter', color: AppStyle.textSub(parentContext))),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(parentContext, false), child: Text('Cancel', style: TextStyle(color: AppStyle.textMuted(parentContext), fontFamily: 'Inter'))),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(parentContext, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                    ),
                  ],
                ),
              );
              if (confirm == true && parentContext.mounted) {
                await ref.read(authStateProvider.notifier).logout();
                if (parentContext.mounted) parentContext.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SheetItem({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: TextStyle(color: color == AppColors.error ? AppColors.error : AppStyle.text(context), fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 15)),
      trailing: Icon(Icons.chevron_right, color: AppStyle.textMuted(context), size: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: AppStyle.surface(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    );
  }
}
