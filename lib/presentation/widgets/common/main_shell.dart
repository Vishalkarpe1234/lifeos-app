import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Home', path: '/dashboard'),
    _NavItem(icon: Icons.task_alt_outlined, activeIcon: Icons.task_alt, label: 'Tasks', path: '/tasks'),
    _NavItem(icon: Icons.sticky_note_2_outlined, activeIcon: Icons.sticky_note_2, label: 'Notes', path: '/notes'),
    _NavItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, label: 'AI', path: '/ai'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', path: '/profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _navItems.indexWhere((item) => location.startsWith(item.path));
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    if (isWide) {
      return _WideLayout(child: child, currentIndex: currentIndex);
    }

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: child,
      bottomNavigationBar: _buildBottomNav(context, currentIndex),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: AppColors.darkBorder, width: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems.asMap().entries.map((e) {
              final isActive = e.key == currentIndex;
              return _NavButton(
                item: e.value,
                isActive: isActive,
                onTap: () => context.go(e.value.path),
              );
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? AppColors.primary : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textMuted,
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
  final int currentIndex;

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard', path: '/dashboard'),
    _NavItem(icon: Icons.task_alt_outlined, activeIcon: Icons.task_alt, label: 'Tasks', path: '/tasks'),
    _NavItem(icon: Icons.sticky_note_2_outlined, activeIcon: Icons.sticky_note_2, label: 'Notes', path: '/notes'),
    _NavItem(icon: Icons.science_outlined, activeIcon: Icons.science, label: 'Research', path: '/research'),
    _NavItem(icon: Icons.school_outlined, activeIcon: Icons.school, label: 'Teaching', path: '/teaching'),
    _NavItem(icon: Icons.folder_outlined, activeIcon: Icons.folder, label: 'Projects', path: '/projects'),
    _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Finance', path: '/finance'),
    _NavItem(icon: Icons.loop_outlined, activeIcon: Icons.loop, label: 'Habits', path: '/habits'),
    _NavItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, label: 'AI', path: '/ai'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', path: '/profile'),
    _NavItem(icon: Icons.admin_panel_settings_outlined, activeIcon: Icons.admin_panel_settings, label: 'Admin', path: '/admin'),
  ];

  const _WideLayout({required this.child, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
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
        color: AppColors.darkSurface,
        border: Border(right: BorderSide(color: AppColors.darkBorder, width: 0.5)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildLogo(),
            const SizedBox(height: 32),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _navItems.asMap().entries.map((e) {
                  return _SideNavItem(item: e.value, isActive: e.key == currentIndex, onTap: () => context.go(e.value.path));
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: AppColors.primaryGradient,
            ),
            child: const Icon(Icons.all_inclusive_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('LifeOS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Inter')),
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
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive ? Border.all(color: AppColors.primary.withOpacity(0.2)) : null,
        ),
        child: Row(
          children: [
            Icon(isActive ? item.activeIcon : item.icon, color: isActive ? AppColors.primary : AppColors.textMuted, size: 20),
            const SizedBox(width: 12),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
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
