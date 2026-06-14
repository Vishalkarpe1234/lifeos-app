import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Home', path: '/dashboard'),
    _NavItem(icon: Icons.task_alt_outlined, activeIcon: Icons.task_alt_rounded, label: 'Tasks', path: '/tasks'),
    _NavItem(icon: Icons.sticky_note_2_outlined, activeIcon: Icons.sticky_note_2_rounded, label: 'Notes', path: '/notes'),
    _NavItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome_rounded, label: 'AI', path: '/ai'),
    _NavItem(icon: Icons.grid_view_rounded, activeIcon: Icons.grid_view_rounded, label: 'More', path: '/modules'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _navItems.indexWhere((i) => location.startsWith(i.path));
    final isWide = MediaQuery.of(context).size.width > 800;

    if (isWide) return _WideLayout(child: child, location: location, ref: ref);

    return Scaffold(
      backgroundColor: AppStyle.bg(context),
      body: child,
      bottomNavigationBar: _buildBottomNav(context, currentIndex),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: AppStyle.navBg(context),
        border: Border(top: BorderSide(color: AppStyle.border(context), width: 0.5)),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, -4))]
            : [const BoxShadow(color: Color(0x0C000000), blurRadius: 20, offset: Offset(0, -6))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems.asMap().entries.map((e) {
              return _NavButton(item: e.value, isActive: e.key == currentIndex, onTap: () => context.go(e.value.path));
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  const _NavButton({required this.item, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: isActive
            ? BoxDecoration(color: AppColors.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(12))
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                key: ValueKey(isActive),
                color: isActive ? AppColors.primary : AppStyle.textMuted(context),
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppStyle.textMuted(context),
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  final Widget child;
  final String location;
  final WidgetRef ref;

  static const _sideItems = [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard', path: '/dashboard'),
    _NavItem(icon: Icons.sticky_note_2_outlined, activeIcon: Icons.sticky_note_2_rounded, label: 'Notes', path: '/notes'),
    _NavItem(icon: Icons.mic_none_rounded, activeIcon: Icons.mic_rounded, label: 'Voice Notes', path: '/voice-notes'),
    _NavItem(icon: Icons.book_outlined, activeIcon: Icons.book_rounded, label: 'Journal', path: '/journal'),
    _NavItem(icon: Icons.task_alt_outlined, activeIcon: Icons.task_alt_rounded, label: 'Tasks', path: '/tasks'),
    _NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Calendar', path: '/calendar'),
    _NavItem(icon: Icons.flag_outlined, activeIcon: Icons.flag_rounded, label: 'Goals', path: '/goals'),
    _NavItem(icon: Icons.loop_outlined, activeIcon: Icons.loop_rounded, label: 'Habits', path: '/habits'),
    _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: 'Finance', path: '/finance'),
    _NavItem(icon: Icons.favorite_border_rounded, activeIcon: Icons.favorite_rounded, label: 'Health', path: '/health'),
    _NavItem(icon: Icons.school_outlined, activeIcon: Icons.school_rounded, label: 'Learning', path: '/learning'),
    _NavItem(icon: Icons.contacts_outlined, activeIcon: Icons.contacts_rounded, label: 'Contacts', path: '/contacts'),
    _NavItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome_rounded, label: 'AI Chat', path: '/ai'),
    _NavItem(icon: Icons.timeline_outlined, activeIcon: Icons.timeline_rounded, label: 'Timeline', path: '/timeline'),
    _NavItem(icon: Icons.search_rounded, activeIcon: Icons.search_rounded, label: 'Search', path: '/search'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profile', path: '/profile'),
    _NavItem(icon: Icons.admin_panel_settings_outlined, activeIcon: Icons.admin_panel_settings_rounded, label: 'Admin', path: '/admin'),
  ];

  const _WideLayout({required this.child, required this.location, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.bg(context),
      body: Row(
        children: [
          _buildSideRail(context),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildSideRail(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppStyle.navBg(context),
        border: Border(right: BorderSide(color: AppStyle.border(context), width: 0.5)),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(4, 0))],
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildLogo(context),
            const SizedBox(height: 8),
            Divider(color: AppStyle.border(context), height: 32),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _sideItems.where((item) {
                  if (item.path == '/admin') return ref.read(authStateProvider).isAdmin;
                  return true;
                }).map((item) {
                  final isActive = location.startsWith(item.path);
                  return _SideNavItem(item: item, isActive: isActive, onTap: () => context.go(item.path));
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('VK OS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppStyle.text(context), fontFamily: 'Inter')),
              Text('Your Life OS', style: TextStyle(fontSize: 10, color: AppStyle.textMuted(context), fontFamily: 'Inter')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  const _SideNavItem({required this.item, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: AppColors.primary.withOpacity(0.15)) : null,
        ),
        child: Row(
          children: [
            Icon(isActive ? item.activeIcon : item.icon, color: isActive ? AppColors.primary : AppStyle.textMuted(context), size: 20),
            const SizedBox(width: 12),
            Text(item.label, style: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400, color: isActive ? AppColors.primary : AppStyle.textSub(context), fontFamily: 'Inter')),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.path});
}
