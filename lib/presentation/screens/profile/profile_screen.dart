import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/data/models/profile_model.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';
import 'package:lifeos/presentation/providers/profile_provider.dart';
import 'package:lifeos/presentation/widgets/common/glass_card.dart';
import 'package:lifeos/presentation/widgets/animations/shimmer_loading.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profile not found', style: TextStyle(color: AppColors.textSecondary)));
          return _buildProfile(context, ref, profile);
        },
        loading: () => const ShimmerLoading(count: 5, height: 100),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, WidgetRef ref, ProfileModel profile) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, profile),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildAbout(profile),
              const SizedBox(height: 16),
              if (profile.skills?.isNotEmpty ?? false) _buildSkills(profile),
              const SizedBox(height: 16),
              _buildSocialLinks(profile),
              const SizedBox(height: 16),
              if (profile.education?.isNotEmpty ?? false) _buildEducation(profile),
              const SizedBox(height: 16),
              if (profile.experience?.isNotEmpty ?? false) _buildExperience(profile),
              const SizedBox(height: 16),
              _buildActions(context, ref),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ProfileModel p) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.darkBg,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (p.coverImageUrl != null)
              Image.network(p.coverImageUrl!, fit: BoxFit.cover)
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withOpacity(0.4), AppColors.darkBg],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            Positioned(
              bottom: 20, left: 20,
              child: Row(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      border: Border.all(color: AppColors.darkBg, width: 3),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16)],
                    ),
                    child: p.profilePhotoUrl != null
                        ? ClipOval(child: Image.network(p.profilePhotoUrl!, fit: BoxFit.cover))
                        : const Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.fullName ?? 'Vishal Karpe', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Inter', shadows: [Shadow(blurRadius: 10)])),
                      Text(p.title ?? 'Professor & Developer', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontFamily: 'Inter', shadows: const [Shadow(blurRadius: 6)])),
                      if (p.location != null) Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.white.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(p.location!, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7), fontFamily: 'Inter')),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbout(ProfileModel p) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
          const SizedBox(height: 10),
          Text(p.bio ?? p.introduction ?? 'No bio added yet.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontFamily: 'Inter', height: 1.6)),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildSkills(ProfileModel p) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Skills', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: (p.skills ?? []).map((skill) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.25)),
              ),
              child: Text(skill, style: const TextStyle(color: AppColors.primaryLight, fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
            )).toList(),
          ),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn();
  }

  Widget _buildSocialLinks(ProfileModel p) {
    final links = <_SocialLink>[];
    if (p.linkedinUrl != null) links.add(_SocialLink('LinkedIn', Icons.business, AppColors.info, p.linkedinUrl!));
    if (p.githubUsername != null) links.add(_SocialLink('GitHub', Icons.code, AppColors.textSecondary, 'https://github.com/${p.githubUsername}'));
    if (p.blogUrl != null) links.add(_SocialLink('Blog', Icons.article_outlined, AppColors.warning, p.blogUrl!.startsWith('http') ? p.blogUrl! : 'https://${p.blogUrl}'));
    if (p.twitterUrl != null) links.add(_SocialLink('Twitter', Icons.flutter_dash, const Color(0xFF1DA1F2), p.twitterUrl!));
    if (links.isEmpty) return const SizedBox();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Connect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: links.map((l) => GestureDetector(
              onTap: () async {
                final uri = Uri.parse(l.url);
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: l.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: l.color.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(l.icon, color: l.color, size: 16),
                    const SizedBox(width: 6),
                    Text(l.label, style: TextStyle(color: l.color, fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn();
  }

  Widget _buildEducation(ProfileModel p) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Education', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
          const SizedBox(height: 12),
          ...(p.education ?? []).map((e) {
            final edu = e as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.school_outlined, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(edu['degree'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                        Text(edu['institution'] ?? '', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Inter')),
                        if (edu['year_start'] != null || edu['percentage'] != null)
                          Text(
                            [if (edu['year_start'] != null) '${edu['year_start']} – ${edu['year_end'] ?? 'Present'}', if (edu['percentage'] != null) '${edu['percentage']}'].join(' • '),
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'Inter'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn();
  }

  Widget _buildExperience(ProfileModel p) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Experience', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter')),
          const SizedBox(height: 12),
          ...(p.experience ?? []).map((e) {
            final exp = e as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.work_outline, color: AppColors.accent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exp['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                        Text(exp['company'] ?? '', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Inter')),
                        if (exp['start_date'] != null)
                          Text('${exp['start_date']} – ${exp['is_current'] == true ? 'Present' : exp['end_date'] ?? ''}', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'Inter')),
                        if (exp['description'] != null) ...[
                          const SizedBox(height: 4),
                          Text(exp['description'].toString(), style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'Inter', height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn();
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return GlassCard(
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 20)),
            title: const Text('Admin Panel', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
            subtitle: Text('Manage all content', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'Inter')),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () => context.go('/admin'),
          ),
          Divider(color: AppColors.darkBorder, height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.settings_outlined, color: AppColors.warning, size: 20)),
            title: const Text('Settings', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
            subtitle: Text('App preferences', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'Inter')),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () => context.go('/settings'),
          ),
          Divider(color: AppColors.darkBorder, height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.logout, color: AppColors.error, size: 20)),
            title: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
            onTap: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    ).animate(delay: 500.ms).fadeIn();
  }
}

class _SocialLink {
  final String label;
  final IconData icon;
  final Color color;
  final String url;
  const _SocialLink(this.label, this.icon, this.color, this.url);
}
