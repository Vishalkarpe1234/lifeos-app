import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';

class ModulesScreen extends ConsumerWidget {
  const ModulesScreen({super.key});

  static const _modules = [
    _Module(Icons.sticky_note_2_rounded, 'Notes', 'Smart notes', AppColors.primary, '/notes'),
    _Module(Icons.mic_rounded, 'Voice Notes', 'Record & transcribe', Color(0xFF8B5CF6), '/voice-notes'),
    _Module(Icons.book_rounded, 'Journal', 'Daily reflections', Color(0xFF06B6D4), '/journal'),
    _Module(Icons.task_alt_rounded, 'Tasks', 'Get things done', AppColors.primary, '/tasks'),
    _Module(Icons.calendar_today_rounded, 'Calendar', 'Schedule & events', AppColors.warning, '/calendar'),
    _Module(Icons.flag_rounded, 'Goals', 'Track ambitions', AppColors.success, '/goals'),
    _Module(Icons.loop_rounded, 'Habits', 'Build routines', Color(0xFF10B981), '/habits'),
    _Module(Icons.account_balance_wallet_rounded, 'Finance', 'Money tracker', Color(0xFFF59E0B), '/finance'),
    _Module(Icons.favorite_rounded, 'Health', 'Mind & body', Color(0xFFEF4444), '/health'),
    _Module(Icons.school_rounded, 'Learning', 'Grow every day', Color(0xFF3B82F6), '/learning'),
    _Module(Icons.contacts_rounded, 'Contacts', 'Your network', Color(0xFF06B6D4), '/contacts'),
    _Module(Icons.auto_awesome_rounded, 'AI Chat', 'Ask anything', Color(0xFF8B5CF6), '/ai'),
    _Module(Icons.timeline_rounded, 'Timeline', 'Life history', AppColors.primary, '/timeline'),
    _Module(Icons.search_rounded, 'Search', 'Find anything', Color(0xFF64748B), '/search'),
    _Module(Icons.science_rounded, 'Research', 'Publications', AppColors.success, '/research'),
    _Module(Icons.school_outlined, 'Teaching', 'Courses & subjects', AppColors.accent, '/teaching'),
    _Module(Icons.folder_rounded, 'Projects', 'Portfolio', AppColors.warning, '/projects'),
    _Module(Icons.workspace_premium_rounded, 'Certs', 'Achievements', Color(0xFF8B5CF6), '/certificates'),
    _Module(Icons.perm_media_rounded, 'Media', 'Files & images', Color(0xFF3B82F6), '/media'),
    _Module(Icons.bookmark_rounded, 'Bookmarks', 'Saved links', AppColors.warning, '/bookmarks'),
    _Module(Icons.settings_rounded, 'Settings', 'Preferences', Color(0xFF64748B), '/settings'),
    _Module(Icons.admin_panel_settings_rounded, 'Admin', 'Super Admin', AppColors.error, '/admin'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authStateProvider).isAdmin;
    final modules = isAdmin ? _modules : _modules.where((m) => m.path != '/admin').toList();

    return Scaffold(
      backgroundColor: AppStyle.bg(context),
      appBar: AppBar(
        backgroundColor: AppStyle.surface(context),
        elevation: 0,
        title: Text('All Modules', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, color: AppStyle.text(context), fontSize: 20)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(color: AppStyle.border(context), height: 1)),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85,
        ),
        itemCount: modules.length,
        itemBuilder: (context, i) {
          final m = modules[i];
          return GestureDetector(
            onTap: () => context.go(m.path),
            child: Container(
              decoration: BoxDecoration(
                color: AppStyle.card(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppStyle.border(context), width: 0.5),
                boxShadow: AppStyle.cardShadow(context),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: m.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(m.icon, color: m.color, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text(m.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppStyle.text(context), fontFamily: 'Inter'), textAlign: TextAlign.center),
                  const SizedBox(height: 3),
                  Text(m.subtitle, style: TextStyle(fontSize: 9, color: AppStyle.textMuted(context), fontFamily: 'Inter'), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Module {
  final IconData icon;
  final String title, subtitle, path;
  final Color color;
  const _Module(this.icon, this.title, this.subtitle, this.color, this.path);
}
