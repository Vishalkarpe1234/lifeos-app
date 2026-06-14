import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';
import 'package:lifeos/presentation/widgets/common/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Settings', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Account', [
            _SettingItem(Icons.lock_outline, 'Change Password', 'Update your password', AppColors.primary, () {}),
            _SettingItem(Icons.pin_outlined, 'Set PIN', 'Set a quick access PIN', AppColors.accent, () {}),
            _SettingItem(Icons.fingerprint, 'Biometric Login', 'Enable fingerprint/face unlock', AppColors.success, () {}),
          ]),
          const SizedBox(height: 16),
          _buildSection('Appearance', [
            _SettingItem(Icons.dark_mode_outlined, 'Dark Mode', 'Always dark theme', AppColors.primary, () {}),
            _SettingItem(Icons.palette_outlined, 'Color Scheme', 'Change accent color', AppColors.warning, () {}),
          ]),
          const SizedBox(height: 16),
          _buildSection('Data & Sync', [
            _SettingItem(Icons.backup_outlined, 'Backup Data', 'Export all your data', AppColors.info, () {}),
            _SettingItem(Icons.restore_outlined, 'Restore Data', 'Import from backup', AppColors.success, () {}),
            _SettingItem(Icons.cloud_sync_outlined, 'Sync Settings', 'Configure sync', AppColors.accent, () {}),
          ]),
          const SizedBox(height: 16),
          _buildSection('AI Configuration', [
            _SettingItem(Icons.vpn_key_outlined, 'API Keys', 'Anthropic, OpenAI', const Color(0xFF8B5CF6), () {}),
            _SettingItem(Icons.auto_awesome_outlined, 'Default AI Model', 'claude-sonnet-4-6', AppColors.primary, () {}),
          ]),
          const SizedBox(height: 16),
          _buildSection('About', [
            _SettingItem(Icons.info_outline, 'App Version', '1.0.0', AppColors.textSecondary, () {}),
            _SettingItem(Icons.shield_outlined, 'Privacy Policy', '', AppColors.textSecondary, () {}),
            _SettingItem(Icons.logout, 'Sign Out', '', AppColors.error, () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            }),
          ]),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<_SettingItem> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted, fontFamily: 'Inter', letterSpacing: 0.5)),
      ),
      GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: items.asMap().entries.map((e) => Column(children: [
          _SettingTile(item: e.value),
          if (e.key < items.length - 1) Divider(color: AppColors.darkDivider, height: 1, indent: 52),
        ])).expand((w) => w is Column ? w.children : [w]).toList()),
      ),
    ]);
  }
}

class _SettingTile extends StatelessWidget {
  final _SettingItem item;
  const _SettingTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: item.color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(item.icon, color: item.color, size: 18)),
      title: Text(item.title, style: TextStyle(color: item.color == AppColors.error ? AppColors.error : Colors.white, fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
      subtitle: item.subtitle.isNotEmpty ? Text(item.subtitle, style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Inter')) : null,
      trailing: item.color != AppColors.error ? Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18) : null,
      onTap: item.onTap,
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _SettingItem(this.icon, this.title, this.subtitle, this.color, this.onTap);
}
