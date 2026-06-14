import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/widgets/common/glass_card.dart';
import 'package:lifeos/services/api/api_client.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Admin Panel', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.analytics_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(ref),
            const SizedBox(height: 24),
            const Text('Content Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
            const SizedBox(height: 12),
            _buildAdminGrid(context),
            const SizedBox(height: 24),
            const Text('System', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
            const SizedBox(height: 12),
            _buildSystemGrid(context),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(WidgetRef ref) {
    final overviewAsync = ref.watch(_adminOverviewProvider);
    return overviewAsync.when(
      data: (data) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.2,
        children: [
          _MiniStat('Tasks', '${data['tasks']}', AppColors.primary, Icons.task_alt),
          _MiniStat('Notes', '${data['notes']}', AppColors.accent, Icons.sticky_note_2),
          _MiniStat('Papers', '${data['publications']}', AppColors.success, Icons.article),
          _MiniStat('Projects', '${data['projects']}', AppColors.warning, Icons.folder),
          _MiniStat('Certs', '${data['certificates']}', const Color(0xFF8B5CF6), Icons.workspace_premium),
          _MiniStat('Files', '${data['media_files']}', AppColors.info, Icons.perm_media),
        ],
      ),
      loading: () => const SizedBox(height: 140, child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildAdminGrid(BuildContext context) {
    final sections = [
      _AdminSection(Icons.person_outline, 'Profile', 'Edit personal info', AppColors.primary, '/profile'),
      _AdminSection(Icons.science_outlined, 'Research', 'Publications & conferences', AppColors.success, '/research'),
      _AdminSection(Icons.school_outlined, 'Teaching', 'Subjects & lectures', AppColors.accent, '/teaching'),
      _AdminSection(Icons.folder_outlined, 'Projects', 'Portfolio projects', AppColors.warning, '/projects'),
      _AdminSection(Icons.workspace_premium_outlined, 'Certificates', 'Certifications', const Color(0xFF8B5CF6), '/certificates'),
      _AdminSection(Icons.perm_media_outlined, 'Media', 'Files & images', AppColors.info, '/media'),
      _AdminSection(Icons.account_balance_wallet_outlined, 'Finance', 'Expenses & budget', AppColors.error, '/finance'),
      _AdminSection(Icons.loop_outlined, 'Habits', 'Daily habits', AppColors.success, '/habits'),
      _AdminSection(Icons.book_outlined, 'Journal', 'Daily journal', AppColors.primary, '/journal'),
      _AdminSection(Icons.bookmark_outlined, 'Bookmarks', 'Saved links', AppColors.warning, '/bookmarks'),
      _AdminSection(Icons.auto_awesome_outlined, 'AI Settings', 'Prompts & models', const Color(0xFF8B5CF6), '/settings'),
      _AdminSection(Icons.sticky_note_2_outlined, 'Notes', 'All notes', AppColors.accent, '/notes'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.4),
      itemCount: sections.length,
      itemBuilder: (_, i) => _AdminTile(section: sections[i]).animate(delay: (30 * i).ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),
    );
  }

  Widget _buildSystemGrid(BuildContext context) {
    final items = [
      _AdminSection(Icons.settings_outlined, 'App Settings', 'Configure app', AppColors.textSecondary, '/settings'),
      _AdminSection(Icons.backup_outlined, 'Backup', 'Backup & restore', AppColors.info, '/settings'),
      _AdminSection(Icons.people_outline, 'Users', 'User management', AppColors.primary, '/admin'),
      _AdminSection(Icons.analytics_outlined, 'Analytics', 'Activity logs', AppColors.success, '/admin'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.4),
      itemCount: items.length,
      itemBuilder: (_, i) => _AdminTile(section: items[i]),
    );
  }
}

final _adminOverviewProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/api/v1/admin/analytics/overview');
  return Map<String, dynamic>.from(r.data as Map);
});

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _MiniStat(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.darkBorder, width: 0.5)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Inter')),
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'Inter')),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final _AdminSection section;
  const _AdminTile({required this.section});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(section.path),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder, width: 0.5),
          gradient: LinearGradient(colors: [AppColors.darkCard, section.color.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: section.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(section.icon, color: section.color, size: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(section.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(section.subtitle, style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }
}

class _AdminSection {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String path;
  const _AdminSection(this.icon, this.title, this.subtitle, this.color, this.path);
}
