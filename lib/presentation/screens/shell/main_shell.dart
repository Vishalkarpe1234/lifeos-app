import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/connect_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  final String location;
  const MainShell({super.key, required this.child, required this.location});

  static const _routes = ['/dashboard', '/tasks', '/habits', '/journal'];

  int _indexForLocation() {
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  void _onTap(BuildContext context, WidgetRef ref, int idx) {
    if (idx == 4) {
      _showMore(context);
      return;
    }
    context.go(_routes[idx]);
  }

  void _showMore(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _MoreSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = _indexForLocation();
    final notif = ref.watch(connectNotificationsProvider);
    final chatCount = notif.maybeWhen(
      data: (d) =>
          ((d['pending_requests'] ?? 0) as int) +
          ((d['unread_messages'] ?? 0) as int),
      orElse: () => 0,
    );
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx > 3 ? 4 : idx,
        onTap: (i) => _onTap(context, ref, i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: C.primary,
        unselectedItemColor: C.textMuted,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 11),
        backgroundColor: Colors.white,
        elevation: 8,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline_rounded),
            label: 'Tasks',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department_rounded),
            label: 'Habits',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Journal',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.more_horiz_rounded),
                if (chatCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: C.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class _MoreSheet extends StatelessWidget {
  const _MoreSheet();

  @override
  Widget build(BuildContext context) {
    final items = [
      _MoreItem(Icons.flag_rounded, 'Goals', '/goals', C.primary),
      _MoreItem(
        Icons.folder_open_rounded,
        'Projects',
        '/projects',
        const Color(0xFF8B5CF6),
      ),
      _MoreItem(Icons.timer_rounded, 'Focus Timer', '/focus', C.success),
      _MoreItem(
        Icons.code_rounded,
        'Snippets',
        '/snippets',
        const Color(0xFFF59E0B),
      ),
      _MoreItem(
        Icons.bar_chart_rounded,
        'Analytics',
        '/analytics',
        const Color(0xFF06B6D4),
      ),
      _MoreItem(Icons.note_alt_rounded, 'Notes', '/notes', C.primary),
      _MoreItem(
        Icons.people_outline_rounded,
        'Connect',
        '/connect',
        C.primaryDark,
      ),
      _MoreItem(
        Icons.person_outline_rounded,
        'Profile',
        '/profile',
        C.textSub,
      ),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'More Features',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: C.text,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: items
                  .map(
                    (item) => GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        context.go(item.route);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(item.icon, color: item.color, size: 24),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.label,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: C.text,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const _MoreItem(this.icon, this.label, this.route, this.color);
}
